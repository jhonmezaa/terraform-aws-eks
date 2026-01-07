# EKS Auto Mode Example

This example demonstrates how to deploy an Amazon EKS cluster with **Auto Mode** enabled, AWS's fully managed compute infrastructure for Kubernetes.

## What is EKS Auto Mode?

Amazon EKS Auto Mode is a new deployment option (released December 2024) that provides fully managed Kubernetes infrastructure where AWS handles:

- **Compute provisioning** - Automatic node provisioning and scaling
- **Infrastructure management** - Patching, updates, and optimization
- **Resource optimization** - Cost optimization while maintaining flexibility
- **Security** - Automated security patches and compliance

### Key Features

✅ **Zero Infrastructure Management** - No node groups to configure
✅ **Automatic Scaling** - Nodes scale based on pod requirements
✅ **Cost Optimized** - Pay only for running pods
✅ **Security Patches** - Automatic node patching (max 21-day instance lifetime)
✅ **Simplified Operations** - Reduced operational overhead

### Limitations

⚠️ **No SSH/SSM Access** - EC2 instances are not directly accessible
⚠️ **Kubernetes >= 1.31** - Required minimum version
⚠️ **AWS Provider >= 5.79** - Terraform provider requirement
⚠️ **Custom AMIs** - Uses AWS-managed AMIs optimized for Auto Mode
⚠️ **Additional Cost** - ~12% of EC2 instance costs

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         EKS Auto Mode Cluster                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Control Plane (AWS Managed)                                    │
│  ├── API Server                                                 │
│  ├── Controller Manager                                         │
│  ├── Scheduler                                                  │
│  └── etcd                                                       │
│                                                                  │
│  Compute (Auto Mode - AWS Managed)                              │
│  ├── Node Pool: general-purpose                                 │
│  │   ├── Automatic node provisioning                            │
│  │   ├── Dynamic scaling based on pods                          │
│  │   └── Automatic patching (max 21-day lifetime)               │
│  │                                                               │
│  └── IAM Policies (Auto-attached)                               │
│      ├── AmazonEKSComputePolicy                                 │
│      ├── AmazonEKSBlockStoragePolicy                            │
│      ├── AmazonEKSLoadBalancingPolicy                           │
│      └── AmazonEKSNetworkingPolicy                              │
│                                                                  │
│  Security                                                        │
│  ├── Auto-created Security Groups                               │
│  ├── IRSA (IAM Roles for Service Accounts)                      │
│  ├── Modern Access Entries (IAM-based)                          │
│  └── Optional KMS Encryption                                    │
│                                                                  │
│  Monitoring                                                      │
│  └── Control Plane Logs → CloudWatch (5 log types)              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **AWS Account** with appropriate permissions
- **VPC** with at least 2 subnets in different AZs
- **Terraform** >= 1.3
- **AWS Provider** >= 5.79
- **Kubernetes** version >= 1.31

## Usage

### 1. Configure Variables

Copy the example vars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
account_name = "dev"
project_name = "automode"

cluster_version = "1.31"

vpc_id = "vpc-0123456789abcdef0"
subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0123456789abcdef1",
  "subnet-0123456789abcdef2"
]

cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true

create_kms_key = false

tags = {
  Environment = "development"
  Team        = "platform"
}
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

### 4. Verify Auto Mode

Check that Auto Mode is enabled:
```bash
# Describe the cluster
aws eks describe-cluster --name <cluster-name> --query 'cluster.computeConfig'

# Output should show:
{
  "enabled": true,
  "nodeRoleArn": "arn:aws:iam::...:role/...",
  "nodePools": ["general-purpose"]
}
```

### 5. Deploy a Test Workload

```bash
kubectl create deployment nginx --image=nginx --replicas=3
kubectl get pods -w
```

Auto Mode will automatically provision nodes to run your pods.

## Configuration

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `vpc_id` | VPC ID | `string` |
| `subnet_ids` | List of subnet IDs (min 2 AZs) | `list(string)` |

### Optional Variables

| Name | Description | Default |
|------|-------------|---------|
| `account_name` | Account name | `"dev"` |
| `project_name` | Project name | `"automode"` |
| `cluster_version` | Kubernetes version | `"1.31"` |
| `cluster_endpoint_private_access` | Enable private endpoint | `true` |
| `cluster_endpoint_public_access` | Enable public endpoint | `true` |
| `create_kms_key` | Create KMS key | `false` |
| `tags` | Resource tags | `{}` |

## What's Included

This example configures:

✅ **EKS Cluster** with Auto Mode enabled
✅ **Auto Mode Node Pool** - general-purpose
✅ **Auto-created Security Groups** - Cluster + Node
✅ **IAM Roles** - Cluster + Node with Auto Mode policies
✅ **IRSA** - IAM Roles for Service Accounts
✅ **Modern Access Entries** - API_AND_CONFIG_MAP
✅ **Control Plane Logging** - All 5 log types to CloudWatch
✅ **Optional KMS Encryption** - For secrets and logs

## Auto Mode vs Traditional Node Groups

| Feature | Auto Mode | Managed Node Groups |
|---------|-----------|-------------------|
| **Node Provisioning** | ✅ Automatic | ❌ Manual |
| **Scaling** | ✅ Pod-based | ⚠️ Metrics-based (HPA/CA) |
| **Patching** | ✅ Automatic | ❌ Manual |
| **Instance Types** | ✅ AWS-optimized | ✅ User-defined |
| **SSH Access** | ❌ No access | ✅ Allowed |
| **Cost** | ⚠️ +12% EC2 cost | ✅ No overhead |
| **Operational Overhead** | ✅ Minimal | ⚠️ Medium |
| **Customization** | ❌ Limited | ✅ Full control |

## Cost Considerations

**Auto Mode Pricing:**
- Base cluster cost: $0.10/hour (~$73/month)
- Auto Mode fee: ~12% of EC2 instance costs
- EC2 instance costs: Standard rates

**Example Monthly Cost (us-east-1):**
- 3 x t3.medium instances (730 hours)
  - EC2 cost: ~$91
  - Auto Mode fee (12%): ~$11
  - **Total: ~$175/month**

**Benefits vs Cost:**
- ✅ No manual patching labor
- ✅ Automatic scaling optimization
- ✅ Reduced operational complexity
- ✅ Faster incident response

## Monitoring and Troubleshooting

### View Control Plane Logs

```bash
# CloudWatch Log Groups
aws logs tail /aws/eks/<cluster-name>/cluster --follow

# Available log streams:
- api                  # Kubernetes API server
- audit                # Audit logs
- authenticator        # IAM authenticator
- controllerManager    # Controller manager
- scheduler            # Scheduler
```

### Check Node Pools

```bash
aws eks list-node-pools --cluster-name <cluster-name>
```

### Verify IAM Policies

```bash
aws iam list-attached-role-policies --role-name <node-role-name>

# Should include:
- AmazonEKSComputePolicy
- AmazonEKSBlockStoragePolicy
- AmazonEKSLoadBalancingPolicy
- AmazonEKSNetworkingPolicy
```

## Scaling

Auto Mode automatically scales nodes based on:
- Pending pods (can't be scheduled)
- Resource requests (CPU/memory)
- Pod priorities

**No manual scaling configuration needed!**

## Cleanup

```bash
# Delete all workloads first
kubectl delete all --all

# Destroy the cluster
terraform destroy
```

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Kubernetes API endpoint |
| `auto_mode_enabled` | Auto Mode status |
| `auto_mode_node_pools` | Configured node pools |
| `auto_mode_node_role_arn` | Node IAM role ARN |
| `oidc_provider_arn` | OIDC provider ARN for IRSA |

## Next Steps

1. **Deploy Applications** - Use `kubectl` to deploy workloads
2. **Configure IRSA** - Bind service accounts to IAM roles
3. **Install Add-ons** - Deploy AWS Load Balancer Controller, External Secrets, etc.
4. **Monitor Costs** - Track Auto Mode costs in Cost Explorer
5. **Enable Metrics** - Install Prometheus/Grafana for observability

## References

- [AWS EKS Auto Mode Documentation](https://aws.amazon.com/blogs/containers/introducing-amazon-eks-auto-mode/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)

## Support

For issues and questions:
- Open an issue on GitHub
- Review the [CHANGELOG](../../CHANGELOG.md)
- Check [module documentation](../../README.md)

---

**Note:** EKS Auto Mode is a relatively new feature (December 2024). Always test in non-production environments first.
