# Plan de Implementación: EKS Module v2.0.0

**Fecha**: 2025-12-23
**Objetivo**: Reestructuración completa con arquitectura de submódulos
**Versión**: 2.0.0 (Breaking Changes)

---

## ARQUITECTURA PROPUESTA

### Estructura de Directorios

```
terraform-aws-eks/
├── eks/                                    # Root module
│   ├── main.tf                             # Module orchestration
│   ├── cluster.tf                          # EKS cluster + cluster IAM role
│   ├── logging.tf                          # CloudWatch log groups + retention
│   ├── kms.tf                              # KMS key creation (optional)
│   ├── access.tf                           # Access entries (modern IAM)
│   ├── security-groups.tf                  # Cluster + node security groups
│   ├── irsa.tf                             # OIDC provider
│   ├── addons.tf                           # EKS managed addons
│   ├── outputs.tf                          # 50+ outputs
│   ├── variables.tf                        # 100+ variables
│   ├── versions.tf                         # Provider constraints
│   ├── data.tf                             # Data sources
│   ├── locals.tf                           # Local values processing
│   │
│   └── modules/                            # Submodules
│       ├── managed-node-group/             # Managed node groups
│       │   ├── main.tf                     # EKS managed node group
│       │   ├── launch-template.tf          # Custom launch template
│       │   ├── iam.tf                      # Node IAM role (optional)
│       │   ├── outputs.tf
│       │   ├── variables.tf
│       │   └── versions.tf
│       │
│       ├── self-managed-node-group/        # Self-managed ASG
│       │   ├── main.tf                     # Auto Scaling Group
│       │   ├── asg.tf                      # ASG configuration
│       │   ├── launch-template.tf          # Launch template
│       │   ├── iam.tf                      # IAM instance profile
│       │   ├── user-data.tf                # Bootstrap scripts
│       │   ├── outputs.tf
│       │   ├── variables.tf
│       │   └── versions.tf
│       │
│       ├── fargate-profile/                # Fargate profiles
│       │   ├── main.tf                     # Fargate profile
│       │   ├── iam.tf                      # Fargate pod execution role
│       │   ├── outputs.tf
│       │   ├── variables.tf
│       │   └── versions.tf
│       │
│       └── kms/                            # KMS key management
│           ├── main.tf                     # KMS key + alias
│           ├── outputs.tf
│           ├── variables.tf
│           └── versions.tf
│
├── examples/                               # Complete examples
│   ├── complete/                           # All features enabled
│   ├── managed-nodes/                      # Managed node groups only
│   ├── self-managed-nodes/                 # Self-managed ASG
│   ├── fargate/                            # Fargate profiles
│   ├── mixed-compute/                      # Managed + Fargate
│   ├── ipv6/                               # IPv6 cluster
│   ├── private-cluster/                    # Private API endpoint
│   └── karpenter/                          # Karpenter ready
│
├── CHANGELOG.md                            # Version history
├── README.md                               # Module documentation
├── CLAUDE.md                               # AI assistant guide
├── ANALYSIS.md                             # Analysis document
└── IMPLEMENTATION_PLAN.md                  # This file
```

---

## FASE 1: CRITICAL FEATURES

### 1.1. Security Groups Auto-Creation

**File**: `eks/security-groups.tf`

**Resources**:
```hcl
resource "aws_security_group" "cluster" {
  count = var.create && var.create_cluster_security_group ? 1 : 0

  name_prefix = "${var.cluster_name}-cluster-"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    var.cluster_security_group_tags,
    { Name = "${var.cluster_name}-cluster" }
  )
}

resource "aws_security_group" "node" {
  count = var.create && var.create_node_security_group ? 1 : 0

  name_prefix = "${var.cluster_name}-node-"
  description = "EKS node security group"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    var.node_security_group_tags,
    { Name = "${var.cluster_name}-node" }
  )
}

# Recommended rules
resource "aws_security_group_rule" "cluster_ingress_node_443" {
  count = var.create && var.create_cluster_security_group && var.create_node_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node[0].id
  security_group_id        = aws_security_group.cluster[0].id
  description              = "Node to cluster API"
}

resource "aws_security_group_rule" "node_ingress_cluster_443" {
  count = var.create && var.create_cluster_security_group && var.create_node_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster[0].id
  security_group_id        = aws_security_group.node[0].id
  description              = "Cluster API to node"
}

resource "aws_security_group_rule" "node_ingress_self" {
  count = var.create && var.create_node_security_group ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.node[0].id
  description       = "Node to node all traffic"
}

resource "aws_security_group_rule" "node_egress_all" {
  count = var.create && var.create_node_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node[0].id
  description       = "Allow all egress"
}

# Dynamic additional rules
resource "aws_security_group_rule" "cluster_additional" {
  for_each = var.create && var.create_cluster_security_group ? var.cluster_security_group_additional_rules : {}

  security_group_id        = aws_security_group.cluster[0].id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  description              = lookup(each.value, "description", null)
}

resource "aws_security_group_rule" "node_additional" {
  for_each = var.create && var.create_node_security_group ? var.node_security_group_additional_rules : {}

  security_group_id        = aws_security_group.node[0].id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  description              = lookup(each.value, "description", null)
}
```

**Variables**:
```hcl
variable "create_cluster_security_group" {
  description = "Create security group for EKS cluster"
  type        = bool
  default     = true
}

variable "create_node_security_group" {
  description = "Create security group for EKS nodes"
  type        = bool
  default     = true
}

variable "cluster_security_group_additional_rules" {
  description = "Additional security group rules for cluster"
  type        = any
  default     = {}
}

variable "node_security_group_additional_rules" {
  description = "Additional security group rules for nodes"
  type        = any
  default     = {}
}

variable "cluster_security_group_tags" {
  description = "Additional tags for cluster security group"
  type        = map(string)
  default     = {}
}

variable "node_security_group_tags" {
  description = "Additional tags for node security group"
  type        = map(string)
  default     = {}
}
```

---

### 1.2. Control Plane Logging

**File**: `eks/logging.tf`

**Resources**:
```hcl
resource "aws_cloudwatch_log_group" "this" {
  count = var.create && length(var.enabled_cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  log_group_class   = var.cloudwatch_log_group_class

  tags = merge(
    var.tags,
    var.cloudwatch_log_group_tags
  )
}
```

**Cluster Config** (in `cluster.tf`):
```hcl
resource "aws_eks_cluster" "this" {
  # ... existing config ...

  enabled_cluster_log_types = var.enabled_cluster_log_types

  depends_on = [
    aws_cloudwatch_log_group.this
  ]
}
```

**Variables**:
```hcl
variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable. Valid values: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 90
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID to encrypt CloudWatch logs"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_class" {
  description = "Log class for CloudWatch log group. Valid values: STANDARD, INFREQUENT_ACCESS"
  type        = string
  default     = "STANDARD"
}

variable "cloudwatch_log_group_tags" {
  description = "Additional tags for CloudWatch log group"
  type        = map(string)
  default     = {}
}
```

---

### 1.3. KMS Encryption

**File**: `eks/kms.tf`

**Resources**:
```hcl
resource "aws_kms_key" "this" {
  count = var.create && var.create_kms_key ? 1 : 0

  description             = "EKS cluster ${var.cluster_name} encryption key"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation

  tags = merge(
    var.tags,
    var.kms_key_tags,
    { Name = "${var.cluster_name}-eks" }
  )
}

resource "aws_kms_alias" "this" {
  count = var.create && var.create_kms_key ? 1 : 0

  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.this[0].key_id
}

# Policy to allow EKS cluster role to use the key
resource "aws_kms_key_policy" "this" {
  count = var.create && var.create_kms_key ? 1 : 0

  key_id = aws_kms_key.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS cluster to use the key"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}
```

**Cluster Config** (in `cluster.tf`):
```hcl
resource "aws_eks_cluster" "this" {
  # ... existing config ...

  encryption_config {
    provider {
      key_arn = var.create_kms_key ? aws_kms_key.this[0].arn : var.cluster_encryption_config_kms_key_arn
    }
    resources = var.cluster_encryption_config_resources
  }
}
```

**Variables**:
```hcl
variable "create_kms_key" {
  description = "Create KMS key for cluster encryption"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window_in_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "kms_key_enable_key_rotation" {
  description = "Enable KMS key rotation"
  type        = bool
  default     = true
}

variable "kms_key_tags" {
  description = "Additional tags for KMS key"
  type        = map(string)
  default     = {}
}

variable "cluster_encryption_config_resources" {
  description = "List of resources to encrypt"
  type        = list(string)
  default     = ["secrets"]
}

variable "cluster_encryption_config_kms_key_arn" {
  description = "Existing KMS key ARN for cluster encryption (if not creating new key)"
  type        = string
  default     = null
}
```

---

### 1.4. Access Entries (Modern IAM)

**File**: `eks/access.tf`

**Resources**:
```hcl
resource "aws_eks_access_entry" "this" {
  for_each = var.create ? var.access_entries : {}

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value.principal_arn
  type              = try(each.value.type, "STANDARD")
  kubernetes_groups = try(each.value.kubernetes_groups, null)
  user_name         = try(each.value.user_name, null)

  tags = merge(
    var.tags,
    try(each.value.tags, {})
  )
}

resource "aws_eks_access_policy_association" "this" {
  for_each = var.create ? local.access_policy_associations : {}

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope.type
    namespaces = try(each.value.access_scope.namespaces, [])
  }

  depends_on = [aws_eks_access_entry.this]
}

# Optional: Cluster creator admin permissions
resource "aws_eks_access_entry" "cluster_creator" {
  count = var.create && var.enable_cluster_creator_admin_permissions ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"

  tags = merge(
    var.tags,
    { Name = "cluster-creator-admin" }
  )
}

resource "aws_eks_access_policy_association" "cluster_creator" {
  count = var.create && var.enable_cluster_creator_admin_permissions ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_creator]
}
```

**Locals** (in `locals.tf`):
```hcl
locals {
  # Flatten access entries with policy associations
  access_policy_associations = merge([
    for entry_key, entry_value in var.access_entries : {
      for policy_key, policy_value in try(entry_value.policy_associations, {}) :
      "${entry_key}-${policy_key}" => {
        principal_arn = entry_value.principal_arn
        policy_arn    = policy_value.policy_arn
        access_scope  = policy_value.access_scope
      }
    }
  ]...)
}
```

**Variables**:
```hcl
variable "access_entries" {
  description = "Map of access entries to create"
  type = map(object({
    principal_arn       = string
    type                = optional(string, "STANDARD")
    kubernetes_groups   = optional(list(string))
    user_name           = optional(string)
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string))
      })
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Create access entry for cluster creator with admin permissions"
  type        = bool
  default     = true
}
```

**Available Policy ARNs**:
```
arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy
arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy
arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy
```

---

### 1.5. Expanded Outputs

**File**: `eks/outputs.tf`

```hcl
################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = try(aws_eks_cluster.this.arn, null)
}

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = try(aws_eks_cluster.this.id, null)
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = try(aws_eks_cluster.this.name, null)
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = try(aws_eks_cluster.this.endpoint, null)
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = try(aws_eks_cluster.this.version, null)
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = try(aws_eks_cluster.this.platform_version, null)
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = try(aws_eks_cluster.this.status, null)
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster"
  value       = try(aws_eks_cluster.this.certificate_authority[0].data, null)
  sensitive   = true
}

output "cluster_primary_security_group_id" {
  description = "Primary security group ID created by EKS for cluster"
  value       = try(aws_eks_cluster.this.vpc_config[0].cluster_security_group_id, null)
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = try(aws_iam_role.cluster[0].arn, null)
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = try(aws_iam_role.cluster[0].name, null)
}

################################################################################
# Security Groups
################################################################################

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster control plane"
  value       = try(aws_security_group.cluster[0].id, null)
}

output "cluster_security_group_arn" {
  description = "ARN of the cluster security group"
  value       = try(aws_security_group.cluster[0].arn, null)
}

output "node_security_group_id" {
  description = "Security group ID attached to the nodes"
  value       = try(aws_security_group.node[0].id, null)
}

output "node_security_group_arn" {
  description = "ARN of the node security group"
  value       = try(aws_security_group.node[0].arn, null)
}

################################################################################
# OIDC Provider (IRSA)
################################################################################

output "oidc_provider" {
  description = "OIDC provider URL without https://"
  value       = try(replace(aws_iam_openid_connect_provider.this[0].url, "https://", ""), null)
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

output "oidc_provider_url" {
  description = "OIDC provider URL"
  value       = try(aws_iam_openid_connect_provider.this[0].url, null)
}

################################################################################
# CloudWatch
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group for cluster logs"
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}

output "cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch log group for cluster logs"
  value       = try(aws_cloudwatch_log_group.this[0].arn, null)
}

################################################################################
# KMS
################################################################################

output "kms_key_id" {
  description = "KMS key ID used for cluster encryption"
  value       = try(aws_kms_key.this[0].id, null)
}

output "kms_key_arn" {
  description = "KMS key ARN used for cluster encryption"
  value       = try(aws_kms_key.this[0].arn, null)
}

################################################################################
# Access Entries
################################################################################

output "access_entries" {
  description = "Map of access entries created"
  value       = aws_eks_access_entry.this
}

output "access_policy_associations" {
  description = "Map of access policy associations created"
  value       = aws_eks_access_policy_association.this
}

################################################################################
# Managed Node Groups
################################################################################

output "managed_node_groups" {
  description = "Map of all managed node groups"
  value       = module.managed_node_group
}

output "managed_node_group_ids" {
  description = "Map of managed node group IDs"
  value       = { for k, v in module.managed_node_group : k => v.node_group_id }
}

output "managed_node_group_arns" {
  description = "Map of managed node group ARNs"
  value       = { for k, v in module.managed_node_group : k => v.node_group_arn }
}

output "managed_node_group_statuses" {
  description = "Map of managed node group statuses"
  value       = { for k, v in module.managed_node_group : k => v.node_group_status }
}

################################################################################
# Self-Managed Node Groups
################################################################################

output "self_managed_node_groups" {
  description = "Map of all self-managed node groups"
  value       = module.self_managed_node_group
}

output "self_managed_node_group_autoscaling_group_ids" {
  description = "Map of self-managed node group ASG IDs"
  value       = { for k, v in module.self_managed_node_group : k => v.autoscaling_group_id }
}

output "self_managed_node_group_autoscaling_group_arns" {
  description = "Map of self-managed node group ASG ARNs"
  value       = { for k, v in module.self_managed_node_group : k => v.autoscaling_group_arn }
}

################################################################################
# Fargate Profiles
################################################################################

output "fargate_profiles" {
  description = "Map of all Fargate profiles"
  value       = module.fargate_profile
}

output "fargate_profile_ids" {
  description = "Map of Fargate profile IDs"
  value       = { for k, v in module.fargate_profile : k => v.fargate_profile_id }
}

output "fargate_profile_arns" {
  description = "Map of Fargate profile ARNs"
  value       = { for k, v in module.fargate_profile : k => v.fargate_profile_arn }
}

################################################################################
# Addons
################################################################################

output "cluster_addons" {
  description = "Map of all cluster addons"
  value = merge(
    aws_eks_addon.before_compute,
    aws_eks_addon.this
  )
}

output "cluster_addon_arns" {
  description = "Map of cluster addon ARNs"
  value = merge(
    { for k, v in aws_eks_addon.before_compute : k => v.arn },
    { for k, v in aws_eks_addon.this : k => v.arn }
  )
}

output "cluster_addon_ids" {
  description = "Map of cluster addon IDs"
  value = merge(
    { for k, v in aws_eks_addon.before_compute : k => v.id },
    { for k, v in aws_eks_addon.this : k => v.id }
  )
}

################################################################################
# Node IAM Role (for Karpenter)
################################################################################

output "node_iam_role_arn" {
  description = "ARN of the node IAM role"
  value       = try(aws_iam_role.node[0].arn, null)
}

output "node_iam_role_name" {
  description = "Name of the node IAM role"
  value       = try(aws_iam_role.node[0].name, null)
}

################################################################################
# Region
################################################################################

output "cluster_region" {
  description = "AWS region where cluster is deployed"
  value       = data.aws_region.current.name
}
```

---

## FASE 2: COMPUTE OPTIONS

### 2.1. Submódulo: Managed Node Group

**Directory**: `eks/modules/managed-node-group/`

**File**: `main.tf`
```hcl
resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.create_iam_role ? aws_iam_role.this[0].arn : var.iam_role_arn
  subnet_ids      = var.subnet_ids

  version         = var.cluster_version
  release_version = var.ami_release_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  capacity_type  = var.capacity_type
  instance_types = var.instance_types

  labels = merge(
    var.labels,
    var.cluster_labels
  )

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  dynamic "remote_access" {
    for_each = var.enable_remote_access ? [1] : []
    content {
      ec2_ssh_key               = var.remote_access_ec2_ssh_key
      source_security_group_ids = var.remote_access_source_security_group_ids
    }
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = var.launch_template_use_latest_version ? "$Latest" : aws_launch_template.this.latest_version
  }

  tags = merge(
    var.tags,
    var.node_group_tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.this
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}
```

**File**: `launch-template.tf`
```hcl
resource "aws_launch_template" "this" {
  name_prefix = "${var.node_group_name}-"
  description = "Launch template for ${var.node_group_name}"

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = lookup(block_device_mappings.value.ebs, "volume_size", null)
        volume_type           = lookup(block_device_mappings.value.ebs, "volume_type", "gp3")
        iops                  = lookup(block_device_mappings.value.ebs, "iops", null)
        throughput            = lookup(block_device_mappings.value.ebs, "throughput", null)
        encrypted             = lookup(block_device_mappings.value.ebs, "encrypted", true)
        kms_key_id            = lookup(block_device_mappings.value.ebs, "kms_key_id", null)
        delete_on_termination = lookup(block_device_mappings.value.ebs, "delete_on_termination", true)
      }
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.metadata_options_http_tokens
    http_put_response_hop_limit = var.metadata_options_http_put_response_hop_limit
    instance_metadata_tags      = var.enable_instance_metadata_tags ? "enabled" : "disabled"
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = true
    security_groups             = var.security_group_ids
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      var.instance_tags,
      { Name = var.node_group_name }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      var.volume_tags,
      { Name = "${var.node_group_name}-ebs" }
    )
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = merge(
      var.tags,
      { Name = "${var.node_group_name}-eni" }
    )
  }

  user_data = base64encode(local.user_data)

  tags = var.tags
}

locals {
  user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {
    cluster_name              = var.cluster_name
    cluster_endpoint          = var.cluster_endpoint
    cluster_ca_data           = var.cluster_certificate_authority_data
    pre_bootstrap_user_data   = var.pre_bootstrap_user_data
    post_bootstrap_user_data  = var.post_bootstrap_user_data
    bootstrap_extra_args      = var.bootstrap_extra_args
    kubelet_extra_args        = var.kubelet_extra_args
  })
}
```

**File**: `templates/user-data.sh.tpl`
```bash
#!/bin/bash
set -ex

# Pre-bootstrap user data
${pre_bootstrap_user_data}

# Bootstrap node to EKS cluster
/etc/eks/bootstrap.sh '${cluster_name}' \
  --b64-cluster-ca '${cluster_ca_data}' \
  --apiserver-endpoint '${cluster_endpoint}' \
  ${bootstrap_extra_args} \
  --kubelet-extra-args '${kubelet_extra_args}'

# Post-bootstrap user data
${post_bootstrap_user_data}
```

**File**: `iam.tf`
```hcl
resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name_prefix = "${var.node_group_name}-node-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  permissions_boundary = var.iam_role_permissions_boundary

  tags = merge(
    var.tags,
    { Name = "${var.node_group_name}-node" }
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.create_iam_role ? var.iam_role_policies : {}

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? var.iam_role_additional_policies : {}

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}
```

**File**: `variables.tf`
```hcl
variable "create" {
  description = "Create node group resources"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  type        = string
}

variable "node_group_name" {
  description = "Name of the node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for node group"
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of unavailable nodes during update"
  type        = number
  default     = 33
}

variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "instance_types" {
  description = "List of instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_release_version" {
  description = "AMI release version"
  type        = string
  default     = null
}

variable "labels" {
  description = "Kubernetes labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "cluster_labels" {
  description = "Cluster-wide labels (e.g., karpenter)"
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []
}

variable "enable_remote_access" {
  description = "Enable SSH remote access"
  type        = bool
  default     = false
}

variable "remote_access_ec2_ssh_key" {
  description = "EC2 SSH key name"
  type        = string
  default     = null
}

variable "remote_access_source_security_group_ids" {
  description = "Source security group IDs for SSH"
  type        = list(string)
  default     = []
}

variable "block_device_mappings" {
  description = "Block device mappings for launch template"
  type        = list(any)
  default = [{
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 100
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }]
}

variable "metadata_options_http_tokens" {
  description = "Metadata service HTTP tokens (optional or required)"
  type        = string
  default     = "required"
}

variable "metadata_options_http_put_response_hop_limit" {
  description = "Metadata service hop limit"
  type        = number
  default     = 2
}

variable "enable_instance_metadata_tags" {
  description = "Enable instance metadata tags"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Associate public IP address"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "Security group IDs for nodes"
  type        = list(string)
}

variable "pre_bootstrap_user_data" {
  description = "User data to run before bootstrap"
  type        = string
  default     = ""
}

variable "post_bootstrap_user_data" {
  description = "User data to run after bootstrap"
  type        = string
  default     = ""
}

variable "bootstrap_extra_args" {
  description = "Extra arguments for bootstrap script"
  type        = string
  default     = ""
}

variable "kubelet_extra_args" {
  description = "Extra arguments for kubelet"
  type        = string
  default     = ""
}

variable "launch_template_use_latest_version" {
  description = "Use $Latest version of launch template"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Create IAM role for nodes"
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "Existing IAM role ARN (if not creating)"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "IAM role permissions boundary"
  type        = string
  default     = null
}

variable "iam_role_policies" {
  description = "IAM policies to attach to role"
  type        = map(string)
  default = {
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

variable "iam_role_additional_policies" {
  description = "Additional IAM policies to attach"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "node_group_tags" {
  description = "Additional tags for node group"
  type        = map(string)
  default     = {}
}

variable "instance_tags" {
  description = "Tags for EC2 instances"
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "Tags for EBS volumes"
  type        = map(string)
  default     = {}
}
```

**File**: `outputs.tf`
```hcl
output "node_group_id" {
  description = "EKS node group ID"
  value       = try(aws_eks_node_group.this.id, null)
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = try(aws_eks_node_group.this.arn, null)
}

output "node_group_status" {
  description = "Status of the node group"
  value       = try(aws_eks_node_group.this.status, null)
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = try(aws_launch_template.this.id, null)
}

output "launch_template_latest_version" {
  description = "Latest version of launch template"
  value       = try(aws_launch_template.this.latest_version, null)
}

output "iam_role_arn" {
  description = "IAM role ARN for nodes"
  value       = try(aws_iam_role.this[0].arn, var.iam_role_arn)
}

output "iam_role_name" {
  description = "IAM role name for nodes"
  value       = try(aws_iam_role.this[0].name, null)
}
```

**File**: `versions.tf`
```hcl
terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

---

### 2.2. Fargate Profile Submódulo

**Directory**: `eks/modules/fargate-profile/`

**File**: `main.tf`
```hcl
resource "aws_eks_fargate_profile" "this" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = var.fargate_profile_name
  pod_execution_role_arn = var.create_iam_role ? aws_iam_role.this[0].arn : var.pod_execution_role_arn
  subnet_ids             = var.subnet_ids

  dynamic "selector" {
    for_each = var.selectors
    content {
      namespace = selector.value.namespace
      labels    = try(selector.value.labels, {})
    }
  }

  tags = merge(
    var.tags,
    var.fargate_profile_tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.pod_execution
  ]
}
```

**File**: `iam.tf`
```hcl
resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name_prefix = "${var.fargate_profile_name}-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  permissions_boundary = var.iam_role_permissions_boundary

  tags = merge(
    var.tags,
    { Name = "${var.fargate_profile_name}-fargate" }
  )
}

resource "aws_iam_role_policy_attachment" "pod_execution" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? var.iam_role_additional_policies : {}

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}
```

**File**: `variables.tf`
```hcl
variable "create" {
  description = "Create Fargate profile resources"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "fargate_profile_name" {
  description = "Name of the Fargate profile"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Fargate profile"
  type        = list(string)
}

variable "selectors" {
  description = "List of selectors for Fargate profile"
  type = list(object({
    namespace = string
    labels    = optional(map(string), {})
  }))
}

variable "create_iam_role" {
  description = "Create IAM role for Fargate pod execution"
  type        = bool
  default     = true
}

variable "pod_execution_role_arn" {
  description = "Existing pod execution role ARN"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "IAM role permissions boundary"
  type        = string
  default     = null
}

variable "iam_role_additional_policies" {
  description = "Additional IAM policies to attach"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "fargate_profile_tags" {
  description = "Additional tags for Fargate profile"
  type        = map(string)
  default     = {}
}
```

**File**: `outputs.tf`
```hcl
output "fargate_profile_id" {
  description = "Fargate profile ID"
  value       = try(aws_eks_fargate_profile.this.id, null)
}

output "fargate_profile_arn" {
  description = "Fargate profile ARN"
  value       = try(aws_eks_fargate_profile.this.arn, null)
}

output "fargate_profile_status" {
  description = "Status of the Fargate profile"
  value       = try(aws_eks_fargate_profile.this.status, null)
}

output "iam_role_arn" {
  description = "IAM role ARN for Fargate pod execution"
  value       = try(aws_iam_role.this[0].arn, var.pod_execution_role_arn)
}

output "iam_role_name" {
  description = "IAM role name for Fargate pod execution"
  value       = try(aws_iam_role.this[0].name, null)
}
```

---

Esta es una implementación parcial del plan. ¿Quieres que continúe con:
1. Self-Managed Node Group submódulo
2. Archivo principal main.tf que orquesta todo
3. Variables completas del root module
4. Ejemplos

O prefieres que implemente todo de una vez en los archivos?
