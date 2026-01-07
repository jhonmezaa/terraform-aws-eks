# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-07

### 🚨 BREAKING CHANGES

#### Module Architecture
- **Complete refactor to modular architecture** with submodules for better organization and reusability
- **Removed numbered files** (1-eks.tf through 9-addons.tf) and replaced with descriptive names
- **New file organization**: 0-data.tf, 0-locals.tf, 0-versions.tf, 1-cluster.tf, 2-security-groups.tf, etc.

#### Variable Changes
- `node_groups` → `managed_node_groups` (more explicit naming)
- Removed `subnet_ids` from root level (now part of cluster configuration)
- Restructured node group configuration schema
- New security group variables (breaking: no longer user-provided by default)

#### Output Changes
- `eks_name` → `cluster_name` (backwards compatible alias provided)
- `eks_cluster_endpoint` → `cluster_endpoint` (backwards compatible alias provided)
- `openid_connect_arn` → `oidc_provider_arn` (backwards compatible alias provided)
- `node_role_arn` → `node_iam_role_arn` (backwards compatible alias provided)
- `node_role_name` → `node_iam_role_name` (backwards compatible alias provided)
- `eks_region` → `cluster_region` (backwards compatible alias provided)

#### Security Groups
- **Breaking**: Security groups now created automatically by module (previously user-provided)
- Can opt-out with `create_cluster_security_group = false` and `create_node_security_group = false`
- Additional rules can be added via `cluster_security_group_additional_rules` and `node_security_group_additional_rules`

#### IRSA (IAM Roles for Service Accounts)
- IRSA remains enabled by default but with enhanced configuration options
- OIDC provider now supports additional audiences

### ✨ NEW FEATURES

#### Security & Access Control
- **Access Entries** (Modern IAM) - Replaces aws-auth ConfigMap pattern
  - Support for access policy associations
  - Cluster creator admin permissions (optional)
  - Standard and EC2 access entry types
  - Policy associations: AmazonEKSClusterAdminPolicy, AmazonEKSAdminPolicy, AmazonEKSEditPolicy, AmazonEKSViewPolicy

- **Security Groups Auto-Creation** - Automatic creation with AWS best practices
  - Cluster security group with ingress from nodes on port 443
  - Node security group with self-referencing rule for pod-to-pod communication
  - Node egress to internet
  - Cluster to node communication on port 443
  - Support for additional custom rules

- **KMS Encryption** - Optional KMS key creation for enhanced security
  - Cluster secrets encryption
  - CloudWatch Logs encryption
  - Automatic key rotation enabled by default
  - Configurable deletion window
  - Multi-region key support
  - Automatic key policy for EKS and CloudWatch Logs

#### Logging & Monitoring
- **Control Plane Logging** - Complete CloudWatch integration
  - Support for all 5 log types: api, audit, authenticator, controllerManager, scheduler
  - Configurable log retention (default: 90 days)
  - KMS encryption support
  - Log class support (STANDARD / INFREQUENT_ACCESS)

#### Compute Options
- **Managed Node Groups** (Enhanced)
  - Moved to dedicated submodule (`modules/managed-node-group/`)
  - Custom launch templates with full EBS configuration
  - Kubernetes labels and taints support
  - Remote SSH access (optional)
  - IMDSv2 required by default
  - Instance metadata tags support
  - Pre/post bootstrap user data hooks
  - Dedicated or shared IAM roles

- **Self-Managed Node Groups** (NEW)
  - Complete Auto Scaling Group implementation
  - Dedicated submodule (`modules/self-managed-node-group/`)
  - Instance refresh support for zero-downtime updates
  - Warm pool configuration
  - Spot instance support with multiple instance types
  - Nitro Enclaves support
  - Capacity reservations
  - Mixed instances policy
  - Advanced health checks
  - Custom termination policies
  - Pre/post bootstrap user data

- **Fargate Profiles** (NEW)
  - Serverless container execution
  - Dedicated submodule (`modules/fargate-profile/`)
  - Multiple selector support (namespace + labels)
  - Optional IAM role creation
  - Pod execution role with required policies

- **KMS Key Management** (NEW)
  - Optional submodule (`modules/kms/`)
  - Automatic key rotation
  - Multi-region support
  - Alias creation

#### Network Features
- **IPv6 Support** - Full dual-stack networking
  - Cluster IP family configuration (ipv4 / ipv6)
  - IPv4 and IPv6 service CIDR support
  - IPv6 security group rules

- **Private Clusters** - Enhanced endpoint controls
  - Public/private endpoint configuration
  - Public access CIDR restrictions
  - Endpoint private access options

- **Outpost Support** - On-premises integration
  - Outpost configuration block
  - Control plane placement options

#### Operational Excellence
- **Cluster Access Configuration**
  - Authentication modes: API, CONFIG_MAP, API_AND_CONFIG_MAP
  - Bootstrap cluster creator permissions (optional)

- **Enhanced Tagging** - Comprehensive tag support
  - Global tags across all resources
  - Resource-specific tags (cluster, nodes, security groups, etc.)
  - Kubernetes cluster tags automatic propagation

- **Resource Timeouts** - Configurable timeouts for all operations
  - Cluster create/update/delete timeouts
  - Node group timeouts
  - Fargate profile timeouts
  - Addon timeouts

### 🔧 IMPROVEMENTS

#### Code Quality
- **Terraform Validation** - Module passes `terraform validate` with zero warnings
- **Provider Updates** - Updated to AWS provider >= 5.0, TLS provider >= 3.0
- **Deprecated Attributes** - Removed all deprecated AWS provider attributes

#### Documentation
- **Expanded Outputs** - 60+ outputs covering all resources and submodules
- **Variable Validation** - Input validation for critical variables
- **Comprehensive Examples** - 8 production-ready examples
  - basic-managed-nodes
  - complete (all features)
  - self-managed-nodes
  - fargate-only
  - mixed-compute
  - ipv6-cluster
  - private-cluster
  - karpenter-ready

#### Addon Management
- **Two-Phase Deployment** - Enhanced addon ordering
  - Phase 1 (before_compute): vpc-cni, pod-identity-agent
  - Phase 2 (after_compute): coredns, kube-proxy, ebs-csi-driver
- **Automatic Version Resolution** - Uses latest compatible addon versions
- **Pod Identity Associations** - Support for addon-specific IRSA configurations

#### Karpenter Integration
- **Enhanced Karpenter Support**
  - Shared node IAM role for Karpenter-managed nodes
  - Automatic `karpenter.sh/controller: true` labels
  - Node role outputs for EC2NodeClass configuration
  - Dedicated example configuration

### 🐛 BUG FIXES

- Fixed deprecated `data.aws_region.current.name` usage (replaced with `.id`)
- Removed invalid `elastic_gpu_specifications` block from launch template
- Fixed security group rule dependencies
- Corrected addon deployment ordering for VPC-CNI and CoreDNS
- Fixed OIDC provider certificate data handling

### 📦 SUBMODULES

New modular architecture with 4 dedicated submodules:

#### `modules/managed-node-group/`
- EKS managed node groups with launch templates
- Files: main.tf, launch-template.tf, iam.tf, variables.tf, outputs.tf, versions.tf
- Template: templates/user-data.sh.tpl

#### `modules/self-managed-node-group/`
- Auto Scaling Groups with full control
- Files: main.tf, launch-template.tf, iam.tf, variables.tf, outputs.tf, versions.tf
- Template: templates/user-data.sh.tpl

#### `modules/fargate-profile/`
- Fargate profiles for serverless containers
- Files: main.tf, iam.tf, variables.tf, outputs.tf, versions.tf

#### `modules/kms/`
- KMS key management (optional)
- Files: main.tf, variables.tf, outputs.tf, versions.tf

### 🔄 MIGRATION GUIDE

#### From v1.x to v2.0.0

**1. Update module source** (if using remote source):
```hcl
module "eks" {
  source = "github.com/user/terraform-aws-eks//eks?ref=v2.0.0"
  # ...
}
```

**2. Rename variables**:
```hcl
# Before (v1.x)
node_groups = { ... }

# After (v2.0.0)
managed_node_groups = { ... }
```

**3. Security groups** (BREAKING):
```hcl
# v1.x: User provided security groups
vpc_security_group_ids = [aws_security_group.cluster.id]

# v2.0.0: Module creates security groups automatically
# Option 1: Let module create (recommended)
# No changes needed - module creates automatically

# Option 2: Provide your own (opt-out of auto-creation)
create_cluster_security_group = false
create_node_security_group    = false
cluster_additional_security_group_ids = [aws_security_group.cluster.id]
node_additional_security_group_ids    = [aws_security_group.node.id]
```

**4. Update outputs**:
```hcl
# Before (v1.x)
output "cluster" {
  value = module.eks.eks_name
}

# After (v2.0.0)
output "cluster" {
  value = module.eks.cluster_name  # Or use .eks_name (backwards compatible)
}
```

**5. Optional: Enable new features**:
```hcl
# Access Entries (replaces aws-auth ConfigMap)
access_entries = {
  admin = {
    principal_arn = "arn:aws:iam::123456789012:role/AdminRole"
    policy_associations = {
      admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }
}

# KMS Encryption
create_kms_key                        = true
cluster_encryption_config_resources   = ["secrets"]

# Control Plane Logging
enabled_cluster_log_types              = ["api", "audit", "authenticator"]
cloudwatch_log_group_retention_in_days = 90

# Fargate Profiles
fargate_profiles = {
  default = {
    name = "default"
    selectors = [
      { namespace = "kube-system" }
      { namespace = "default" }
    ]
  }
}
```

### 📊 STATISTICS

- **Total Files**: 35 files (12 root + 23 submodule files)
- **Lines of Code**: ~4,000 lines
- **Variables**: 100+ input variables
- **Outputs**: 60+ outputs
- **Submodules**: 4 dedicated submodules
- **Examples**: 8 production-ready examples

### 🔗 REFERENCES

- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## [1.0.0] - 2024-11-14

### Initial Release

- EKS cluster creation with managed node groups
- IRSA (IAM Roles for Service Accounts) support
- Custom launch templates for node groups
- EKS managed addons with two-phase deployment
- Karpenter integration with node labels
- Basic security configurations
- CloudWatch integration for cluster monitoring

