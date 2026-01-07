# Mixed Compute Example

This example demonstrates a hybrid EKS cluster using both managed EC2 node groups and Fargate profiles. This architecture allows you to optimize compute for different workload types.

## Features

- **EC2 Node Groups** for stateful workloads and system components
- **Fargate Profiles** for stateless applications and batch jobs
- Optimized node placement with taints and tolerations
- EBS CSI Driver for persistent storage on EC2
- Cost-optimized compute selection

## Architecture

### EC2 Node Groups (2 groups)

1. **System Nodes** (t3.medium):
   - Purpose: DaemonSets, system pods, monitoring agents
   - Tainted: `node-role=system:NO_SCHEDULE`
   - Always-on: 2-4 nodes
   - CoreDNS runs here

2. **Stateful Nodes** (r6i.large):
   - Purpose: Databases, caches, stateful applications
   - Persistent storage via EBS CSI Driver
   - Memory-optimized instances
   - 200GB gp3 volumes

### Fargate Profiles (4 profiles)

1. **Web**: Stateless web applications
2. **API**: Microservices and APIs
3. **Batch**: Background jobs and processing
4. **Development**: Dev/test environments

## When to Use This Pattern

This mixed approach is ideal when:

1. **You have DaemonSets**: Fargate doesn't support DaemonSets (monitoring agents, log collectors)
2. **Mixed workload types**: Stateful on EC2, stateless on Fargate
3. **Cost optimization**: Right-size compute for each workload
4. **Gradual migration**: Transition from EC2 to Fargate incrementally
5. **GPU or special hardware**: Not available on Fargate

## Workload Placement Strategy

### Run on EC2 (Nodes):
- DaemonSets (Prometheus Node Exporter, Fluent Bit)
- Stateful applications (databases, caches)
- GPU workloads
- Privileged containers
- High-performance networking
- Applications with local storage

### Run on Fargate:
- Stateless web applications
- APIs and microservices
- Batch jobs and CI/CD
- Development/test environments
- Variable-load applications
- Multi-tenant workloads

## Prerequisites

- AWS account with appropriate permissions
- VPC with private subnets in at least 2 AZs
- NAT Gateway for Fargate internet access
- Terraform >= 1.0
- kubectl and AWS CLI

## Usage

1. Copy and configure:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Deploy:
```bash
terraform init
terraform apply
```

3. Configure kubectl:
```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1
```

4. Verify both compute types:
```bash
# Check EC2 nodes
kubectl get nodes -l compute=ec2

# Check Fargate nodes
kubectl get nodes -l eks.amazonaws.com/compute-type=fargate
```

## Deploying Workloads

### Deploy to EC2 (Stateful Database)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: default
spec:
  serviceName: postgres
  replicas: 2
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      nodeSelector:
        workload: stateful  # Target stateful nodes
      containers:
      - name: postgres
        image: postgres:15
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3
      resources:
        requests:
          storage: 50Gi
```

### Deploy to Fargate (Stateless API)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
  namespace: api  # Matches Fargate profile
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: nginx:latest
        resources:
          requests:
            cpu: "0.5"
            memory: "1Gi"
```

### Deploy System Component (DaemonSet on EC2)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      tolerations:
      - key: node-role
        operator: Equal
        value: system
        effect: NoSchedule
      nodeSelector:
        workload: system  # Only on system nodes
      containers:
      - name: node-exporter
        image: prom/node-exporter:latest
```

## Cost Optimization

### Estimated Monthly Costs (us-east-1)

| Component | Specs | Quantity | Monthly Cost |
|-----------|-------|----------|--------------|
| EKS Cluster | - | 1 | $73 |
| t3.medium (system) | ON_DEMAND | 2 | $60 |
| r6i.large (stateful) | ON_DEMAND | 2 | $244 |
| Fargate (web) | 0.5 vCPU, 1GB | 3 pods | $32 |
| Fargate (api) | 0.25 vCPU, 0.5GB | 5 pods | $45 |
| Fargate (batch) | Variable | Avg usage | $20 |
| EBS gp3 (500GB) | - | - | $40 |
| **Total** | | | **~$514/month** |

### Cost Optimization Tips

1. **Right-size EC2 instances**: Use smaller types for system nodes
2. **Scale Fargate to zero**: For dev/test environments
3. **Use Spot for batch**: Add spot node group for batch workloads
4. **Schedule scaling**: Scale down during off-hours
5. **Monitor usage**: Track which pods use which compute

## Monitoring and Observability

### View Compute Distribution

```bash
# Count pods by compute type
kubectl get pods -A -o custom-columns=\
NAME:.metadata.name,\
NAMESPACE:.metadata.namespace,\
NODE:.spec.nodeName,\
COMPUTE:.spec.nodeSelector

# Cost visibility by namespace
kubectl get pods -A -o json | jq -r '
  .items[] |
  select(.spec.nodeName != null) |
  [.metadata.namespace, .spec.nodeName, .spec.containers[0].resources.requests] |
  @tsv
'
```

### CloudWatch Metrics

Both EC2 and Fargate publish metrics:
- EC2: Instance metrics, node metrics
- Fargate: Pod CPU/memory utilization

## Scaling

### EC2 Autoscaling

Install Cluster Autoscaler:
```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=$(terraform output -raw cluster_name)
```

### Fargate Autoscaling

Fargate scales automatically based on pod requests. No additional configuration needed.

For advanced scaling, use:
- Horizontal Pod Autoscaler (HPA)
- Vertical Pod Autoscaler (VPA)
- KEDA for event-driven scaling

## Migration Strategy

### From EC2-only to Mixed

1. Deploy Fargate profiles alongside existing nodes
2. Identify stateless workloads
3. Update namespace labels to match Fargate selectors
4. Redeploy pods to Fargate
5. Scale down EC2 nodes

### From Fargate-only to Mixed

1. Deploy EC2 node groups
2. Identify workloads needing EC2 (DaemonSets, GPUs)
3. Add node selectors or taints
4. Redeploy affected pods
5. Remove unnecessary Fargate profiles

## Troubleshooting

### Pod on wrong compute type

Check scheduler decisions:
```bash
kubectl describe pod <pod-name> -n <namespace>
```

Common causes:
- Missing namespace for Fargate
- Missing node selector for EC2
- Taint without toleration

### Fargate pods not starting

1. Verify Fargate profile selectors
2. Ensure subnets are private with NAT
3. Check pod resource requests are specified

### DaemonSet not on all nodes

DaemonSets don't run on Fargate nodes. Ensure:
- Toleration for system node taint
- Node selector for EC2 nodes

## Security Best Practices

1. **Network isolation**: Separate security groups for EC2 and Fargate
2. **IAM least privilege**: Different roles for workload types
3. **Pod Security Standards**: Enforce in both compute types
4. **IRSA for applications**: Use IAM roles, not credentials

## Cleanup

```bash
# Delete all workloads
kubectl delete namespace web api batch dev test monitoring --ignore-not-found

# Delete PVCs
kubectl delete pvc --all

# Destroy infrastructure
terraform destroy
```

## Next Steps

- Configure Cluster Autoscaler for EC2 scaling
- Add Karpenter for advanced node provisioning
- Implement Pod Security Policies
- Set up cost allocation tags
- Deploy service mesh (Istio/App Mesh)

## Related Examples

- [fargate-only](../fargate-only) - Pure serverless approach
- [basic-managed-nodes](../basic-managed-nodes) - EC2 only
- [karpenter-ready](../karpenter-ready) - Modern autoscaling
- [complete](../complete) - All features enabled
