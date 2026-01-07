# Complete EKS Example

This example demonstrates all features of the EKS module v2.0.0, including managed node groups, Fargate profiles, CloudWatch logging, KMS encryption, access entries, and all available EKS addons.

## Features

- **Multiple Compute Types**:
  - Managed node groups (ON_DEMAND and SPOT)
  - ARM-based nodes (t4g instances)
  - Fargate profiles for serverless workloads

- **Security**:
  - KMS encryption for cluster secrets
  - CloudWatch logging for all control plane components
  - Access entries for fine-grained IAM control
  - Security groups with proper network isolation
  - IMDSv2 required on all nodes

- **High Availability**:
  - Multi-AZ deployment
  - Private and public API endpoints
  - Autoscaling node groups

- **Add-ons**:
  - VPC-CNI with prefix delegation
  - EKS Pod Identity Agent
  - CoreDNS with resource limits
  - kube-proxy
  - EBS CSI Driver with IRSA

- **IRSA**: IAM Roles for Service Accounts enabled

## Architecture

### Managed Node Groups (3 groups)

1. **General**:
   - 3 x t3.large (ON_DEMAND)
   - For standard workloads
   - 100GB gp3 volumes with 3000 IOPS

2. **Spot**:
   - 2-10 x t3.large/t3a.large (SPOT)
   - For batch/fault-tolerant workloads
   - Tainted with `spot=true:NO_SCHEDULE`

3. **ARM**:
   - 2 x t4g.medium (ON_DEMAND)
   - ARM64 architecture for cost optimization
   - Amazon Linux 2023

### Fargate Profiles (2 profiles)

1. **kube-system**: For system pods with `fargate=true` label
2. **serverless**: For `serverless` and `batch` namespaces

### Security Features

- **KMS Encryption**: Automatic key creation with rotation
- **CloudWatch Logging**: All 5 log types enabled (90-day retention)
- **Access Entries**: Modern IAM (replaces aws-auth ConfigMap)
  - DevOps team: Full admin access
  - Developer team: Read-only access

## Prerequisites

- AWS account with appropriate permissions
- VPC with private subnets in at least 2 AZs
- IAM roles for DevOps and Developer teams (if using access entries)
- Terraform >= 1.0
- kubectl installed

## Usage

1. Copy and customize the tfvars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Update with your values:
```hcl
vpc_id             = "vpc-xxx"
subnet_ids         = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
private_subnet_ids = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
devops_team_role_arn = "arn:aws:iam::123456789012:role/DevOpsTeam"
```

3. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

4. Configure kubectl:
```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1
```

5. Verify deployment:
```bash
# Check nodes
kubectl get nodes -o wide

# Check Fargate profiles
kubectl get nodes -l eks.amazonaws.com/compute-type=fargate

# Check system pods
kubectl get pods -A

# Verify addons
kubectl get pods -n kube-system
```

## Testing Fargate

Deploy a pod to Fargate:

```bash
# Create serverless namespace
kubectl create namespace serverless

# Deploy test pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: fargate-test
  namespace: serverless
spec:
  containers:
  - name: nginx
    image: nginx:latest
EOF

# Verify it runs on Fargate
kubectl get pod fargate-test -n serverless -o wide
```

## Testing Spot Instances

Deploy to spot nodes with toleration:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-job
spec:
  replicas: 3
  selector:
    matchLabels:
      app: batch
  template:
    metadata:
      labels:
        app: batch
    spec:
      tolerations:
      - key: spot
        operator: Equal
        value: "true"
        effect: NoSchedule
      nodeSelector:
        workload: batch
      containers:
      - name: busybox
        image: busybox
        command: ["sleep", "3600"]
EOF
```

## Testing IRSA (EBS CSI Driver)

The EBS CSI Driver is configured with IRSA:

```bash
# Create a PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 10Gi
EOF

# Verify PVC is bound
kubectl get pvc ebs-claim
```

## Viewing CloudWatch Logs

```bash
# Get log group name
terraform output cloudwatch_log_group_name

# View logs in AWS Console or CLI
aws logs tail "/aws/eks/$(terraform output -raw cluster_name)/cluster" --follow
```

## Access Entries

This example uses modern access entries instead of the aws-auth ConfigMap:

```bash
# List access entries
aws eks list-access-entries --cluster-name $(terraform output -raw cluster_name)

# Describe specific entry
aws eks describe-access-entry \
  --cluster-name $(terraform output -raw cluster_name) \
  --principal-arn arn:aws:iam::123456789012:role/DevOpsTeam
```

## Cost Estimation

Estimated monthly costs (us-east-1):

| Resource | Quantity | Unit Cost | Total |
|----------|----------|-----------|-------|
| EKS Cluster | 1 | $73 | $73 |
| t3.large (general) | 3 | $60 | $180 |
| t4g.medium (ARM) | 2 | $25 | $50 |
| t3.large (spot avg) | 2 | $18 | $36 |
| EBS gp3 (700GB) | - | $0.08/GB | $56 |
| CloudWatch Logs | ~10GB/month | $0.50/GB | $5 |
| KMS Key | 1 | $1 | $1 |
| **Total** | | | **~$401/month** |

*Note: Fargate costs are per-vCPU-hour and GB-hour based on usage*

## Security Best Practices

This example implements:

1. **Encryption at rest**: KMS for secrets, EBS volumes encrypted
2. **Encryption in transit**: TLS for all communications
3. **Least privilege**: Separate IAM roles with minimal permissions
4. **Network isolation**: Private subnets for workloads
5. **Audit logging**: All control plane logs enabled
6. **Metadata protection**: IMDSv2 required on all nodes
7. **Regular updates**: Automatic addon version updates

## Cleanup

To destroy all resources:

```bash
# Delete any deployed workloads first
kubectl delete namespace serverless --ignore-not-found

# Destroy infrastructure
terraform destroy
```

**Important**: Delete any PersistentVolumes manually before destroying:
```bash
kubectl get pv
kubectl delete pv <pv-name>
```

## Troubleshooting

### Fargate pods not starting
- Ensure subnets are private (no IGW route)
- Check Fargate profile selectors match namespace/labels
- Verify subnet tags: `kubernetes.io/role/internal-elb=1`

### Access denied errors
- Check access entry principal ARNs are correct
- Verify IAM role trust relationships
- Ensure caller identity has permissions

### EBS CSI Driver issues
- Verify IRSA role is created and attached
- Check service account annotation in kube-system
- Ensure addon is in ACTIVE state

## Next Steps

After deploying:

1. **Install monitoring**: Add Prometheus, Grafana via Helm
2. **Configure autoscaling**: Deploy Cluster Autoscaler or Karpenter
3. **Add ingress**: Install AWS Load Balancer Controller
4. **Set up CI/CD**: Configure deployment pipelines
5. **Implement GitOps**: Deploy FluxCD or ArgoCD

## Related Examples

- [basic-managed-nodes](../basic-managed-nodes) - Simple cluster setup
- [fargate-only](../fargate-only) - Serverless-only configuration
- [karpenter-ready](../karpenter-ready) - Optimized for Karpenter autoscaling
- [private-cluster](../private-cluster) - Private endpoint only
