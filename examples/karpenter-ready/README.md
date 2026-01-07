# Karpenter-Ready EKS Cluster Example

This example demonstrates an EKS cluster optimized for [Karpenter](https://karpenter.sh), a high-performance Kubernetes cluster autoscaler that provisions nodes in seconds based on pending pod requirements.

## Features

- EKS cluster with Karpenter support enabled
- Dedicated system node group for Karpenter controller
- IAM roles configured for Karpenter IRSA
- SQS queue for Spot interruption handling
- EventBridge rules for instance lifecycle events
- Node IAM role pre-configured for Karpenter-provisioned nodes
- VPC-CNI with prefix delegation for more IPs

## Why Karpenter?

### vs Cluster Autoscaler

| Feature | Cluster Autoscaler | Karpenter |
|---------|-------------------|-----------|
| Provisioning speed | Minutes | Seconds |
| Instance flexibility | Node groups only | Any instance type |
| Consolidation | Limited | Automatic |
| Spot support | Basic | Advanced |
| Configuration | Complex | Simple |

### Benefits

1. **Fast scaling**: Provisions nodes in ~40 seconds (vs 3-5 minutes)
2. **Right-sizing**: Selects optimal instance type per workload
3. **Cost optimization**: Automatic consolidation and Spot usage
4. **Simplified ops**: No node group management
5. **Flexible**: Mix Spot and On-Demand dynamically

## Prerequisites

- AWS account with appropriate permissions
- VPC with subnets in multiple AZs
- Terraform >= 1.0
- kubectl and Helm installed
- AWS CLI configured

## Usage

### 1. Deploy Infrastructure

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1
```

### 3. Install Karpenter

```bash
# Add Karpenter Helm repository
helm repo add karpenter https://charts.karpenter.sh
helm repo update

# Install Karpenter
helm upgrade --install karpenter karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --set settings.clusterName=$(terraform output -raw cluster_name) \
  --set settings.clusterEndpoint=$(terraform output -raw cluster_endpoint) \
  --set settings.interruptionQueue=$(terraform output -raw karpenter_interruption_queue_name) \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw karpenter_controller_role_arn) \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --set tolerations[0].key=CriticalAddonsOnly \
  --set tolerations[0].operator=Exists \
  --set tolerations[0].effect=NoSchedule \
  --set nodeSelector.role=karpenter \
  --version v0.37.0
```

### 4. Create NodePool (Karpenter Configuration)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["2"]
      nodeClassRef:
        name: default
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h # 30 days
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  role: $(terraform output -raw node_iam_role_name)
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: $(terraform output -raw cluster_name)
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: $(terraform output -raw cluster_name)
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        encrypted: true
        deleteOnTermination: true
EOF
```

**Note**: Tag your subnets and security groups with `karpenter.sh/discovery: <cluster-name>` for Karpenter to discover them.

### 5. Test Karpenter

Deploy a test workload:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      containers:
      - name: inflate
        image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
        resources:
          requests:
            cpu: 1
            memory: 1.5Gi
EOF

# Scale up to trigger Karpenter
kubectl scale deployment inflate --replicas=10

# Watch Karpenter provision nodes
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter -c controller

# View nodes created by Karpenter
kubectl get nodes -L karpenter.sh/nodepool

# Scale down
kubectl scale deployment inflate --replicas=0

# Watch Karpenter consolidate (deprovisioning happens after ~30s of idle)
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter -c controller
```

## Karpenter Configuration Explained

### NodePool

Defines node requirements and limits:

```yaml
spec:
  template:
    spec:
      requirements:
        # Instance types: c, m, r families (compute, memory, general)
        # Generation > 2 (modern instances)
        # Spot and On-Demand mix
        # AMD64 architecture
  limits:
    cpu: 1000        # Max 1000 CPUs across all Karpenter nodes
    memory: 1000Gi   # Max 1000GB RAM
  disruption:
    consolidationPolicy: WhenUnderutilized  # Automatically consolidate
    expireAfter: 720h  # Replace nodes after 30 days
```

### EC2NodeClass

Defines AWS-specific configuration:

```yaml
spec:
  amiFamily: AL2                    # Amazon Linux 2
  role: <node-iam-role>             # IAM role for nodes
  subnetSelectorTerms:              # Discover subnets by tag
    - tags:
        karpenter.sh/discovery: cluster-name
  securityGroupSelectorTerms:       # Discover SGs by tag
    - tags:
        karpenter.sh/discovery: cluster-name
```

## Advanced Karpenter Examples

### Multiple NodePools for Different Workloads

```yaml
---
# General purpose NodePool
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: general
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-size
          operator: In
          values: ["small", "medium", "large"]
      taints:
        - key: workload
          value: general
          effect: NoSchedule
  weight: 100  # Higher priority
---
# Batch processing NodePool (Spot only)
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: batch
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m"]
      taints:
        - key: workload
          value: batch
          effect: NoSchedule
  weight: 50  # Lower priority
```

### Workload Targeting Specific NodePool

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 5
  template:
    spec:
      tolerations:
      - key: workload
        operator: Equal
        value: general
        effect: NoSchedule
      nodeSelector:
        karpenter.sh/nodepool: general
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: "1"
            memory: "2Gi"
```

### Spot Interruption Handling

Karpenter automatically handles Spot interruptions via the SQS queue:

1. AWS sends interruption warning (2 minutes notice)
2. EventBridge forwards to SQS queue
3. Karpenter receives notification
4. Karpenter cordons and drains node
5. Pods rescheduled to other nodes
6. Node terminated gracefully

## Monitoring Karpenter

### View Karpenter Metrics

```bash
# Install Prometheus if not already installed
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

# Karpenter exposes metrics on :8000/metrics
kubectl port-forward -n karpenter svc/karpenter 8000:8000

# View in browser: http://localhost:8000/metrics
```

### Key Metrics

- `karpenter_nodes_created`: Total nodes created
- `karpenter_nodes_terminated`: Total nodes terminated
- `karpenter_pods_startup_time_seconds`: Pod startup duration
- `karpenter_nodeclaims_disrupted`: Nodes disrupted (consolidation, drift)

### CloudWatch Logs

```bash
# View Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter --tail=100 -f

# Watch for provisioning events
kubectl get events -n karpenter --field-selector involvedObject.kind=NodeClaim --watch
```

## Cost Optimization with Karpenter

### Automatic Consolidation

Karpenter automatically:
- Moves pods to fewer nodes
- Terminates underutilized nodes
- Repacks pods for better bin-packing

### Spot Instance Strategy

```yaml
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]  # 70% cost savings
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]  # Diversify for availability
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["5"]  # Newer generations cheaper
```

### Budget Limits

```yaml
spec:
  limits:
    cpu: "100"      # Max 100 CPUs
    memory: "200Gi" # Max 200GB
  weight: 10        # Priority for this pool
```

## Troubleshooting

### Karpenter not provisioning nodes

1. Check Karpenter logs:
```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

2. Verify NodePool exists:
```bash
kubectl get nodepools
kubectl describe nodepool default
```

3. Check pending pods:
```bash
kubectl get pods --field-selector=status.phase=Pending -A
kubectl describe pod <pending-pod>
```

4. Verify IAM role permissions:
```bash
aws iam get-role --role-name $(terraform output -raw karpenter_controller_role_name)
```

### Nodes created but pods not scheduling

1. Check node taints vs pod tolerations
2. Verify resource requests are reasonable
3. Check pod affinity/anti-affinity rules

### Spot interruptions causing issues

1. Verify SQS queue is receiving events:
```bash
aws sqs get-queue-attributes \
  --queue-url $(terraform output -raw karpenter_interruption_queue_arn) \
  --attribute-names ApproximateNumberOfMessages
```

2. Increase pod replica counts for high availability
3. Use Pod Disruption Budgets (PDBs)

## Best Practices

1. **Start with limits**: Set reasonable CPU/memory limits per NodePool
2. **Use Pod Disruption Budgets**: Prevent too many pods terminating
3. **Diversify Spot**: Use multiple instance families and sizes
4. **Monitor costs**: Track Spot vs On-Demand usage
5. **Test failover**: Simulate Spot interruptions
6. **Update regularly**: Keep Karpenter version current
7. **Use NodePools**: Separate workload types
8. **Set resource requests**: Critical for right-sizing

## Cost Estimation

With Karpenter optimizations:

| Scenario | Without Karpenter | With Karpenter | Savings |
|----------|------------------|----------------|---------|
| Static sizing | $500/month | $300/month | 40% |
| Variable load | $800/month | $400/month | 50% |
| Batch jobs | $1000/month | $300/month | 70% |

Factors:
- Spot instance usage (60-90% savings)
- Consolidation (20-40% fewer nodes)
- Right-sizing (10-30% efficiency gain)

## Migration from Cluster Autoscaler

1. Deploy Karpenter alongside Cluster Autoscaler
2. Create Karpenter NodePools with different taints
3. Gradually migrate workloads to Karpenter nodes
4. Monitor performance and costs
5. Remove Cluster Autoscaler when ready

## Cleanup

```bash
# Delete Karpenter resources
kubectl delete nodepools --all
kubectl delete ec2nodeclasses --all

# Delete test workloads
kubectl delete deployment inflate

# Uninstall Karpenter
helm uninstall karpenter -n karpenter

# Destroy infrastructure
terraform destroy
```

## Related Examples

- [basic-managed-nodes](../basic-managed-nodes) - Traditional autoscaling
- [complete](../complete) - Full-featured cluster
- [mixed-compute](../mixed-compute) - Managed nodes + Fargate

## References

- [Karpenter Documentation](https://karpenter.sh)
- [Karpenter Best Practices](https://aws.github.io/aws-eks-best-practices/karpenter/)
- [Karpenter GitHub](https://github.com/aws/karpenter)
