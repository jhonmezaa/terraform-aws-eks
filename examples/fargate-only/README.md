# Fargate Only Example

This example demonstrates a completely serverless EKS cluster using only AWS Fargate. No EC2 instances are deployed - all pods run on Fargate with per-pod billing.

## Features

- 100% serverless Kubernetes cluster
- No EC2 node management
- 5 Fargate profiles for different workload namespaces
- IRSA (IAM Roles for Service Accounts) enabled
- CoreDNS configured for Fargate
- Pay-per-pod pricing model

## Architecture

### Fargate Profiles

1. **kube-system**: System namespace (CoreDNS, etc.)
2. **default**: Default application namespace
3. **applications**: Multi-environment (production, staging, development)
4. **monitoring**: Observability tools
5. **cicd**: CI/CD workloads with label selector

All pods matching these selectors automatically run on Fargate.

## Prerequisites

- AWS account with appropriate permissions
- VPC with **private subnets** and **NAT Gateway**
- Terraform >= 1.0
- kubectl and AWS CLI installed

**Critical**: Fargate requires private subnets with internet access via NAT Gateway. Public subnets will not work.

## Subnet Requirements

Fargate pods need:
1. Private subnets (no direct internet gateway route)
2. NAT Gateway for outbound internet access
3. Route table with `0.0.0.0/0 -> NAT Gateway`
4. Proper subnet tags:
   - `kubernetes.io/role/internal-elb = 1`

## Usage

1. Copy the example tfvars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your **private** subnet IDs:
```hcl
vpc_id = "vpc-xxx"
private_subnet_ids = [
  "subnet-private-a",  # Must have NAT route
  "subnet-private-b",
  "subnet-private-c"
]
```

3. Deploy:
```bash
terraform init
terraform plan
terraform apply
```

4. Configure kubectl:
```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1
```

5. Verify Fargate nodes:
```bash
kubectl get nodes -L eks.amazonaws.com/compute-type
```

All nodes should show `compute-type=fargate`.

## CoreDNS on Fargate

CoreDNS requires special handling for Fargate-only clusters:

1. **Automatic patching**: This example includes a `null_resource` that removes the EC2 compute annotation
2. **Configuration**: CoreDNS addon includes `computeType: Fargate`
3. **Restart**: CoreDNS is restarted to run on Fargate

Manual verification:
```bash
kubectl get pods -n kube-system -l k8s-app=coredns -o wide
```

Pods should show Fargate node names.

## Deploying Workloads

### Deploy to default namespace (automatic Fargate):
```bash
kubectl create deployment nginx --image=nginx
kubectl get pods -o wide
```

### Deploy to production namespace:
```bash
kubectl create namespace production
kubectl create deployment app --image=nginx -n production
kubectl get pods -n production -o wide
```

### Deploy with specific Fargate profile (cicd):
```bash
kubectl create namespace cicd
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: build-pod
  namespace: cicd
  labels:
    compute: fargate  # Matches cicd profile selector
spec:
  containers:
  - name: builder
    image: alpine:latest
    command: ["sleep", "3600"]
EOF
```

## Fargate Pod Configuration

### Resource Requests

Fargate allocates resources based on pod requests:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: production
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "1"       # 1 vCPU
        memory: "2Gi"  # 2 GB RAM
```

Fargate rounds up to nearest configuration:
- 0.25 vCPU / 0.5-2 GB
- 0.5 vCPU / 1-4 GB
- 1 vCPU / 2-8 GB
- 2 vCPU / 4-16 GB
- 4 vCPU / 8-30 GB

### Storage

Fargate provides 20 GB ephemeral storage by default:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-app
  namespace: production
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        ephemeral-storage: "20Gi"
      limits:
        ephemeral-storage: "20Gi"
```

Maximum: 200 GB per pod

## Networking

### Service Types

Fargate supports all Kubernetes service types:

```bash
# ClusterIP (default)
kubectl expose deployment nginx --port=80 -n production

# LoadBalancer (requires AWS Load Balancer Controller)
kubectl expose deployment nginx --type=LoadBalancer --port=80 -n production

# NodePort (works with Fargate)
kubectl expose deployment nginx --type=NodePort --port=80 -n production
```

### Ingress

Install AWS Load Balancer Controller for ingress:

```bash
# Add Helm repo
helm repo add eks https://aws.github.io/eks-charts

# Install controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$(terraform output -raw cluster_name) \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<IRSA_ROLE_ARN>
```

## Cost Estimation

Fargate pricing (us-east-1):
- **vCPU**: $0.04048/hour
- **Memory**: $0.004445/GB/hour

### Example Calculations

**Small app** (0.25 vCPU, 0.5 GB):
- vCPU: 0.25 × $0.04048 × 730 hours = $7.39
- Memory: 0.5 × $0.004445 × 730 hours = $1.62
- **Total: ~$9/month per pod**

**Standard app** (1 vCPU, 2 GB):
- vCPU: 1 × $0.04048 × 730 hours = $29.55
- Memory: 2 × $0.004445 × 730 hours = $6.49
- **Total: ~$36/month per pod**

**Large app** (2 vCPU, 4 GB):
- vCPU: 2 × $0.04048 × 730 hours = $59.10
- Memory: 4 × $0.004445 × 730 hours = $12.98
- **Total: ~$72/month per pod**

**Cluster baseline** (EKS + CoreDNS):
- EKS control plane: $73/month
- CoreDNS (2 pods × 0.25 vCPU, 0.25 GB): ~$18/month
- **Total baseline: ~$91/month**

## Advantages of Fargate

1. **No node management**: No patching, scaling, or maintenance
2. **Security**: Pod-level isolation, automatic updates
3. **Right-sizing**: Pay only for pod resources used
4. **Scalability**: Unlimited pod scaling (no node limits)
5. **Compliance**: Pod-level IAM roles via IRSA

## Limitations of Fargate

1. **No DaemonSets**: System daemons not supported
2. **No privileged containers**: Security restriction
3. **No GPU support**: CPU-only workloads
4. **Cold start**: ~60 seconds for pod startup
5. **Storage**: Ephemeral only (max 200 GB)
6. **Costs**: More expensive than EC2 for always-on workloads

## When to Use Fargate

Ideal for:
- Microservices with variable load
- Batch jobs and CI/CD
- Development/test environments
- Multi-tenant workloads
- Security-sensitive applications

Not ideal for:
- GPU workloads
- High-performance computing
- Always-on large-scale deployments
- Applications requiring DaemonSets

## Monitoring

### Pod Metrics

Fargate automatically publishes metrics to CloudWatch:

```bash
# View pod CPU usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/EKS \
  --metric-name pod_cpu_utilization \
  --dimensions Name=ClusterName,Value=$(terraform output -raw cluster_name) \
  --statistics Average \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300
```

### Logging

Configure Fluent Bit for CloudWatch Logs:

```bash
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatch/aws-logging-cloudwatch-configmap.yaml
```

## Troubleshooting

### Pods stuck in Pending

1. Check Fargate profile selectors:
```bash
aws eks describe-fargate-profile \
  --cluster-name $(terraform output -raw cluster_name) \
  --fargate-profile-name applications
```

2. Verify namespace exists:
```bash
kubectl get namespaces
```

3. Check pod labels match selectors:
```bash
kubectl get pods -n production --show-labels
```

### CoreDNS not running

If CoreDNS stays on EC2:
```bash
# Remove EC2 annotation
kubectl patch deployment coredns \
  -n kube-system \
  --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'

# Restart
kubectl rollout restart -n kube-system deployment coredns
```

### Subnet errors

Fargate requires private subnets:
- Check route table has NAT Gateway route
- Verify no direct internet gateway route
- Ensure proper subnet tags

## Cleanup

```bash
# Delete all workloads first
kubectl delete namespace production --ignore-not-found
kubectl delete namespace staging --ignore-not-found
kubectl delete namespace development --ignore-not-found
kubectl delete namespace monitoring --ignore-not-found
kubectl delete namespace cicd --ignore-not-found

# Destroy infrastructure
terraform destroy
```

## Next Steps

- Install AWS Load Balancer Controller for ingress
- Configure Fluent Bit for centralized logging
- Set up Prometheus/Grafana for monitoring
- Implement IRSA for application pods
- Add External Secrets Operator

## Related Examples

- [mixed-compute](../mixed-compute) - Fargate + managed nodes
- [complete](../complete) - Full-featured cluster with nodes
- [basic-managed-nodes](../basic-managed-nodes) - Simple EC2-based cluster
