locals {
  # Auto-generate region prefix if not provided
  region_prefix_map = {
    "us-east-1"      = "ause1"
    "us-east-2"      = "ause2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-west-3"      = "euw3"
    "eu-central-1"   = "euc1"
    "eu-north-1"     = "eun1"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-south-1"     = "aps1"
    "sa-east-1"      = "sae1"
    "ca-central-1"   = "cac1"
  }

  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(local.region_prefix_map, data.aws_region.current.region, "aws")

  # Name prefix: includes region prefix with trailing dash, or empty string
  name_prefix = var.use_region_prefix ? "${local.region_prefix}-" : ""

  # Cluster name
  cluster_name = var.cluster_name != null ? var.cluster_name : "${local.name_prefix}eks-cluster-${var.account_name}-${var.project_name}"

  # IAM role names (AWS limits: name <= 64 chars, name_prefix <= 38 chars).
  # Truncation only affects names that would otherwise be rejected by AWS.
  cluster_iam_role_name        = substr(coalesce(var.cluster_iam_role_name, "${local.cluster_name}-cluster"), 0, 64)
  cluster_iam_role_name_prefix = substr("${local.cluster_name}-cluster-", 0, 38)
  node_iam_role_name           = substr(coalesce(var.node_iam_role_name, "${local.cluster_name}-node"), 0, 64)
  node_iam_role_name_prefix    = substr("${local.cluster_name}-node-", 0, 38)

  # Security group names
  cluster_security_group_name = coalesce(var.cluster_security_group_name, "${local.cluster_name}-cluster")
  node_security_group_name    = coalesce(var.node_security_group_name, "${local.cluster_name}-node")

  # Partition-aware managed policy prefix
  iam_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  # Security groups
  cluster_security_group_id = var.create && var.create_cluster_security_group ? try(aws_security_group.cluster[0].id, null) : var.cluster_security_group_id
  node_security_group_id    = var.create && var.create_node_security_group ? try(aws_security_group.node[0].id, null) : var.node_security_group_id

  # Combine cluster security groups
  cluster_security_group_ids = compact(concat(
    [local.cluster_security_group_id],
    var.cluster_additional_security_group_ids
  ))

  # Combine node security groups
  node_security_group_ids = compact(concat(
    [local.node_security_group_id],
    var.node_additional_security_group_ids
  ))

  # KMS key ARN for cluster encryption
  cluster_encryption_kms_key_arn = var.create_kms_key ? try(aws_kms_key.this[0].arn, null) : var.cluster_encryption_config_kms_key_arn

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

  # CloudWatch log group name
  cloudwatch_log_group_name = "/aws/eks/${local.cluster_name}/cluster"

  # Partition DNS suffix
  dns_suffix = data.aws_partition.current.dns_suffix

  # Cluster IAM role ARN
  cluster_iam_role_arn = var.create_cluster_iam_role ? try(aws_iam_role.cluster[0].arn, null) : var.cluster_iam_role_arn

  # Node IAM role ARN (for shared node role)
  node_iam_role_arn = var.create_node_iam_role ? try(aws_iam_role.node[0].arn, null) : var.node_iam_role_arn

  # Node role used by EKS Auto Mode
  auto_mode_node_role_arn = var.auto_mode_node_role_arn != null ? var.auto_mode_node_role_arn : (var.create_node_iam_role ? try(aws_iam_role.node[0].arn, null) : null)

  # OIDC provider URL without https://
  oidc_provider_url = try(replace(aws_eks_cluster.this[0].identity[0].oidc[0].issuer, "https://", ""), "")

  # Fargate profiles with defaults
  fargate_profiles = {
    for k, v in var.fargate_profiles : k => merge(
      {
        create_iam_role = true
      },
      v
    )
  }

  # Addons before compute
  addons_before_compute = var.cluster_addons != null ? {
    for k, v in var.cluster_addons : k => v
    if try(v.before_compute, false)
  } : {}

  # Addons after compute
  addons_after_compute = var.cluster_addons != null ? {
    for k, v in var.cluster_addons : k => v
    if !try(v.before_compute, false)
  } : {}

  # Tags
  tags = merge(
    var.tags_common,
    var.tags,
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
      ManagedBy                                     = "Terraform"
    }
  )

  # Cluster tags
  cluster_tags = merge(
    local.tags,
    var.cluster_tags
  )

  # Node tags
  node_tags = merge(
    local.tags,
    var.node_tags
  )
}
