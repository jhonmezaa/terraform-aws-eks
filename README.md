# Terraform AWS EKS Module

Production-ready Terraform module for deploying Amazon Elastic Kubernetes Service (EKS) clusters with managed node groups, Fargate profiles, and comprehensive addon management.

## Features

### Cluster Management
- **EKS Cluster**: Kubernetes versions 1.21 - 1.34 supported
- **EKS Auto Mode**: Fully managed compute infrastructure (AWS-managed nodes and storage)
- **Flexible Networking**: Public, private, or hybrid endpoint configurations
- **IPv6 Support**: Dual-stack networking with IPv6 CIDR allocation
- **Outpost Support**: EKS on AWS Outposts for edge deployments

### Compute Options
- **Managed Node Groups**: EC2-based worker nodes with custom launch templates
- **Fargate Profiles**: Serverless compute for Kubernetes workloads
- **Multi-Architecture**: x86_64 and ARM64 (Graviton) support
- **Spot Instances**: Cost-optimized workloads with EC2 Spot
- **Mixed Compute**: Combine managed nodes and Fargate in single cluster

### Security & IAM
- **IRSA (IAM Roles for Service Accounts)**: OIDC provider for fine-grained permissions
- **Access Entries**: Modern IAM authentication (replaces aws-auth ConfigMap)
- **KMS Encryption**: Cluster secrets encryption with AWS KMS
- **Security Groups**: Auto-configured or custom security groups
- **CloudWatch Logging**: Complete control plane audit logs

### Add-on Management
- **Two-Phase Deployment**: Intelligent addon ordering (before/after compute)
- **Version Management**: Automatic latest version resolution or pinning
- **Configuration Overrides**: JSON-based addon customization
- **Built-in Addons**: vpc-cni, CoreDNS, kube-proxy, EBS CSI Driver, Pod Identity Agent

### Advanced Features
- **Karpenter Ready**: Pre-configured for Karpenter autoscaling
- **Upgrade Policy**: STANDARD (14 months) or EXTENDED (26 months) support
- **SSH Remote Access**: Optional SSH access to worker nodes
- **Custom Taints & Labels**: Fine-grained workload scheduling
- **Launch Templates**: Full EC2 launch template customization

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | ~> 6.0 |
| tls | ~> 3.0 |

## Usage

### Basic Example

```hcl
module "eks" {
  source = "github.com/your-org/terraform-aws-eks//eks"

  account_name = "prod"
  project_name = "myapp"

  cluster_version = "1.34"
  vpc_id          = "vpc-abc123"
  subnet_ids      = ["subnet-123", "subnet-456"]

  managed_node_groups = {
    general = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = ["t3.large"]
    }
  }

  cluster_addons = {
    vpc-cni    = { before_compute = true, most_recent = true }
    coredns    = { before_compute = false, most_recent = true }
    kube-proxy = { before_compute = false, most_recent = true }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Complete Example

See [examples/complete](./examples/complete) for a full-featured configuration including:
- Multiple node groups (on-demand, spot, ARM)
- Fargate profiles for serverless workloads
- CloudWatch logging
- KMS encryption
- Access entries for team permissions
- EBS CSI Driver with IRSA

### Cluster Naming Convention

Clusters are automatically named following this pattern:

```
{region_prefix}-eks-cluster-{account_name}-{project_name}
```

**Example**: `ause1-eks-cluster-prod-myapp` (us-east-1, account: prod, project: myapp)

**Region Prefix Mapping**:
- `us-east-1` → `ause1`
- `us-west-2` → `usw2`
- `eu-west-1` → `euw1`
- `ap-southeast-1` → `apse1`

Override with `cluster_name` variable if needed.

## Key Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `account_name` | Account name for resource naming | `string` |
| `project_name` | Project name for resource naming | `string` |
| `cluster_version` | Kubernetes version (e.g., "1.34") | `string` |
| `vpc_id` | VPC ID where cluster will be deployed | `string` |
| `subnet_ids` | List of subnet IDs (minimum 2 AZs) | `list(string)` |

### Cluster Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `cluster_name` | Override auto-generated cluster name | `string` | `null` |
| `cluster_endpoint_private_access` | Enable private API endpoint | `bool` | `false` |
| `cluster_endpoint_public_access` | Enable public API endpoint | `bool` | `true` |
| `cluster_endpoint_public_access_cidrs` | CIDRs allowed to access public endpoint | `list(string)` | `["0.0.0.0/0"]` |
| `cluster_ip_family` | IP family (ipv4 or ipv6) | `string` | `null` |
| `cluster_upgrade_policy` | Upgrade policy configuration | `object` | `null` |

### Logging & Encryption

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enabled_cluster_log_types` | Control plane logs to enable | `list(string)` | `[]` |
| `cloudwatch_log_group_retention_in_days` | Log retention period | `number` | `90` |
| `create_kms_key` | Create KMS key for encryption | `bool` | `false` |
| `kms_key_enable_key_rotation` | Enable automatic key rotation | `bool` | `true` |

### Compute Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `managed_node_groups` | Map of managed node group configs | `map(any)` | `{}` |
| `fargate_profiles` | Map of Fargate profile configs | `map(any)` | `{}` |
| `enable_auto_mode` | Enable EKS Auto Mode | `bool` | `false` |
| `enable_karpenter` | Add Karpenter labels to nodes | `bool` | `false` |

### IAM & Security

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_irsa` | Enable OIDC provider for IRSA | `bool` | `true` |
| `access_entries` | Map of IAM access entries | `map(object)` | `{}` |
| `enable_cluster_creator_admin_permissions` | Grant admin to cluster creator | `bool` | `true` |
| `create_cluster_security_group` | Create cluster security group | `bool` | `true` |
| `create_node_security_group` | Create node security group | `bool` | `true` |

### Add-ons

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `cluster_addons` | Map of EKS addon configurations | `map(object)` | `null` |

## Outputs

### Cluster Information

| Name | Description |
|------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Kubernetes API endpoint |
| `cluster_version` | Kubernetes version |
| `cluster_arn` | Cluster ARN |
| `cluster_certificate_authority_data` | Base64 CA certificate |

### IAM & Security

| Name | Description |
|------|-------------|
| `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `cluster_iam_role_arn` | Cluster IAM role ARN |
| `node_iam_role_arn` | Shared node IAM role ARN (for Karpenter) |
| `cluster_security_group_id` | Cluster security group ID |
| `node_security_group_id` | Node security group ID |

### Node Groups & Fargate

| Name | Description |
|------|-------------|
| `managed_node_group_ids` | Map of node group IDs |
| `managed_node_group_arns` | Map of node group ARNs |
| `managed_node_group_statuses` | Map of node group statuses |
| `fargate_profile_ids` | Map of Fargate profile IDs |
| `fargate_profile_arns` | Map of Fargate profile ARNs |

### Add-ons

| Name | Description |
|------|-------------|
| `cluster_addons` | Map of all addon resources |
| `cluster_addon_versions` | Map of deployed addon versions |

### Encryption & Logging

| Name | Description |
|------|-------------|
| `kms_key_arn` | KMS key ARN for encryption |
| `cloudwatch_log_group_name` | CloudWatch log group name |

## Managed Node Groups Configuration

```hcl
managed_node_groups = {
  general = {
    # Scaling
    desired_size = 3
    min_size     = 2
    max_size     = 6

    # Instance configuration
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND" # or "SPOT"
    ami_type       = "AL2023_x86_64_STANDARD"

    # Storage
    block_device_mappings = [{
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 125
        encrypted             = true
        delete_on_termination = true
      }
    }]

    # Labels and taints
    labels = {
      workload = "general"
    }

    taints = [{
      key    = "dedicated"
      value  = "gpu"
      effect = "NO_SCHEDULE"
    }]

    # Networking
    enable_monitoring = true

    # Metadata service (IMDSv2)
    metadata_options_http_tokens                 = "required"
    metadata_options_http_put_response_hop_limit = 2

    # Update configuration
    update_config = {
      max_unavailable_percentage = 33
    }
  }
}
```

## Fargate Profiles Configuration

```hcl
fargate_profiles = {
  serverless = {
    selectors = [
      {
        namespace = "serverless"
      },
      {
        namespace = "batch"
        labels = {
          compute = "fargate"
        }
      }
    ]

    subnet_ids = ["subnet-private-1", "subnet-private-2"]
  }
}
```

## EKS Add-ons Configuration

### Two-Phase Deployment

EKS addons support two deployment phases via the `before_compute` flag:

- **Phase 1** (`before_compute = true`): Deployed before node groups
  - Required for: `vpc-cni`, `eks-pod-identity-agent`
  - These addons must be present before nodes join the cluster

- **Phase 2** (`before_compute = false`): Deployed after node groups
  - Standard for: `coredns`, `kube-proxy`, `aws-ebs-csi-driver`
  - These addons require worker nodes to be operational

```hcl
cluster_addons = {
  # Phase 1: Before compute
  vpc-cni = {
    before_compute       = true
    most_recent          = true
    configuration_values = jsonencode({
      env = {
        ENABLE_PREFIX_DELEGATION = "true"
        ENABLE_POD_ENI           = "true"
      }
    })
  }

  eks-pod-identity-agent = {
    before_compute = true
    most_recent    = true
  }

  # Phase 2: After compute
  coredns = {
    before_compute = false
    most_recent    = true
  }

  kube-proxy = {
    before_compute = false
    most_recent    = true
  }

  # EBS CSI Driver with IRSA
  aws-ebs-csi-driver = {
    before_compute           = false
    most_recent              = true
    service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  }
}
```

### Available Add-ons

- `vpc-cni` - Amazon VPC CNI plugin (networking)
- `coredns` - CoreDNS for cluster DNS
- `kube-proxy` - Kubernetes network proxy
- `aws-ebs-csi-driver` - EBS storage driver
- `eks-pod-identity-agent` - Pod identity for IAM
- `aws-efs-csi-driver` - EFS storage driver
- `aws-guardduty-agent` - GuardDuty security monitoring
- `amazon-cloudwatch-observability` - CloudWatch metrics/logs

## EKS Auto Mode

EKS Auto Mode provides fully managed compute infrastructure where AWS handles node provisioning, scaling, and lifecycle management.

```hcl
module "eks" {
  source = "./eks"

  enable_auto_mode     = true
  auto_mode_node_pools = ["general-purpose", "system"]

  # Auto Mode doesn't require managed_node_groups or fargate_profiles
  # AWS manages all compute automatically
}
```

**Benefits**:
- AWS manages node provisioning and scaling
- Automatic node health monitoring and replacement
- No need to manage node groups or Fargate profiles
- Simplified operational overhead

**Requires**: AWS Provider >= 5.79, Kubernetes >= 1.31

## Tested Examples (Kubernetes 1.34)

The following examples have been validated with Kubernetes 1.34:

### ✅ Complete Example
**Path**: `examples/complete`

Full-featured cluster with managed nodes and Fargate profiles.

**Features**:
- 3 managed node groups (general, spot, arm)
- 2 Fargate profiles (kube-system, serverless)
- CloudWatch logging (all control plane types)
- KMS encryption
- IRSA with EBS CSI Driver
- 5 EKS addons

**Resources**: ~41 resources
**Deploy time**: ~20 minutes

### ✅ Private Cluster
**Path**: `examples/private-cluster`

Fully private cluster with no public endpoint access.

**Features**:
- Private API endpoint only
- VPC endpoints (S3, ECR API, ECR DKR)
- Route table configuration for gateway endpoints
- KMS encryption
- CloudWatch logging
- 3 managed nodes (t3.large)

**Resources**: ~30 resources
**Deploy time**: ~18 minutes

**Note**: Requires VPN/Direct Connect or bastion host for kubectl access.

### ✅ Security Groups Custom
**Path**: `examples/security-groups-custom`

Cluster with custom security groups instead of module-generated.

**Features**:
- Custom cluster security group
- Custom node security group
- Explicit ingress/egress rules
- 2 managed nodes (t3.medium)

**Resources**: ~25 resources
**Deploy time**: ~15 minutes

**Use case**: Pre-existing security group requirements or strict network policies.

### ✅ Upgrade Policy
**Path**: `examples/upgrade-policy`

Cluster with upgrade policies and CloudWatch monitoring.

**Features**:
- STANDARD support type (14 months)
- Support end date configuration
- 2 node groups (primary: 3 nodes, secondary: 2 nodes)
- CloudWatch alarms for API errors
- Full control plane logging
- Rolling update configuration (33% max unavailable)

**Resources**: ~35 resources
**Deploy time**: ~20 minutes

### 🚀 Ready for Testing

Additional examples ready for deployment:

1. **basic-managed-nodes** - Simple managed node group
2. **karpenter-ready** - Pre-configured for Karpenter autoscaling
3. **eks-auto-mode** - Fully managed compute (AWS Auto Mode)
4. **fargate-only** - Serverless-only cluster
5. **mixed-compute** - EC2 + Fargate hybrid
6. **ipv6-cluster** - Dual-stack IPv6 networking
7. **multi-region-kms** - Multi-region KMS encryption
8. **ssh-remote-access** - SSH access to worker nodes
9. **outpost-cluster** - EKS on AWS Outposts

## Architecture

### Module Structure

```
eks/
├── 0-data.tf              # Data sources (region, AMI versions)
├── 0-locals.tf            # Local variables and naming logic
├── 0-versions.tf          # Provider version constraints
├── 1-cluster.tf           # EKS cluster resource
├── 2-security-groups.tf   # Cluster and node security groups
├── 3-logging.tf           # CloudWatch log groups
├── 4-kms.tf               # KMS key for encryption
├── 5-access.tf            # Access entries (modern IAM)
├── 6-irsa.tf              # OIDC provider for IRSA
├── 7-addons.tf            # EKS managed addons
├── 8-main.tf              # Node groups and Fargate profiles
├── 9-variables.tf         # Input variables
├── 10-outputs.tf          # Output values
└── modules/
    ├── managed-node-group/    # Managed node group submodule
    ├── fargate-profile/       # Fargate profile submodule
    └── kms/                   # KMS encryption submodule
```

### Resource Naming

All resources follow a consistent naming pattern:

```
{region_prefix}-{resource_type}-{account_name}-{project_name}[-{identifier}]
```

**Examples**:
- Cluster: `ause1-eks-cluster-prod-myapp`
- Node IAM Role: `ause1-role-eks-node-prod-myapp`
- Security Group: `ause1-sg-eks-cluster-prod-myapp`

### Dependency Flow

```
VPC/Subnets
    ↓
Cluster IAM Role → EKS Cluster → OIDC Provider (IRSA)
    ↓                   ↓
Node IAM Role    Addons (Phase 1: vpc-cni, pod-identity-agent)
    ↓                   ↓
Managed Node Groups / Fargate Profiles
    ↓
Addons (Phase 2: coredns, kube-proxy, ebs-csi-driver)
```

## Integration with Other Modules

### With VPC Module

```hcl
module "vpc" {
  source = "github.com/your-org/terraform-aws-vpc//vpc"

  account_name   = "prod"
  project_name   = "myapp"
  vpc_cidr_block = "10.0.0.0/16"
  azs            = ["a", "b", "c"]

  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

module "eks" {
  source = "github.com/your-org/terraform-aws-eks//eks"

  account_name = "prod"
  project_name = "myapp"

  cluster_version = "1.34"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  managed_node_groups = {
    general = {
      desired_size   = 3
      instance_types = ["t3.large"]
    }
  }
}
```

### With Helm Addons Module

```hcl
module "helm_addons" {
  source = "github.com/your-org/terraform-aws-eks-helm-addons//helm-addons"

  account_name         = "prod"
  project_name         = "myapp"
  eks_name             = module.eks.cluster_name
  eks_cluster_endpoint = module.eks.cluster_endpoint
  openid_provider_arn  = module.eks.oidc_provider_arn
  node_role_arn        = module.eks.node_iam_role_arn
  node_role_name       = module.eks.node_iam_role_name

  enable_karpenter        = true
  enable_external_secrets = true
  enable_keda             = true
}
```

## Upgrade Guides

### Upgrading Kubernetes Version

```bash
# 1. Update cluster version
terraform apply -var="cluster_version=1.34"

# 2. Update kubeconfig
aws eks update-kubeconfig --name ause1-eks-cluster-prod-myapp --region us-east-1

# 3. Verify cluster version
kubectl version --short

# 4. Update node groups (automatically uses new AMI)
# Node groups will rolling update to new Kubernetes version
```

### Enabling IRSA on Existing Cluster

```hcl
module "eks" {
  # ... existing config ...

  enable_irsa = true  # Add this
}
```

Terraform will create the OIDC provider without recreating the cluster.

## Troubleshooting

### CoreDNS Stuck in "Creating"

**Cause**: No worker nodes available.

**Solution**:
```bash
# Check node groups
kubectl get nodes

# Check Auto Scaling
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name>
```

### Addon Conflicts

**Cause**: Addon deployed before nodes when `before_compute = false`.

**Solution**: Set `before_compute = true` for vpc-cni and pod-identity-agent.

### Access Denied to Cluster

**Cause**: Missing access entry or RBAC permissions.

**Solution**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Check access entries
aws eks list-access-entries --cluster-name <cluster-name>
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Authors

Maintained by Jhon Meza

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with tests

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
