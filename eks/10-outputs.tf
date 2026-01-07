################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = try(aws_eks_cluster.this[0].arn, null)
}

output "cluster_id" {
  description = "ID of the EKS cluster (also known as cluster name)"
  value       = try(aws_eks_cluster.this[0].id, null)
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = try(aws_eks_cluster.this[0].name, null)
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = try(aws_eks_cluster.this[0].endpoint, null)
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = try(aws_eks_cluster.this[0].version, null)
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = try(aws_eks_cluster.this[0].platform_version, null)
}

output "cluster_status" {
  description = "Status of the EKS cluster (CREATING, ACTIVE, DELETING, FAILED)"
  value       = try(aws_eks_cluster.this[0].status, null)
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = try(aws_eks_cluster.this[0].certificate_authority[0].data, null)
  sensitive   = true
}

output "cluster_primary_security_group_id" {
  description = "Primary security group ID created by EKS for the cluster (not managed by this module)"
  value       = try(aws_eks_cluster.this[0].vpc_config[0].cluster_security_group_id, null)
}

output "cluster_identity" {
  description = "Cluster identity block"
  value       = try(aws_eks_cluster.this[0].identity, null)
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = try(aws_eks_cluster.this[0].identity[0].oidc[0].issuer, null)
}

################################################################################
# Cluster IAM Role
################################################################################

output "cluster_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster"
  value       = try(aws_iam_role.cluster[0].arn, var.cluster_iam_role_arn)
}

output "cluster_iam_role_name" {
  description = "Name of the IAM role used by the EKS cluster"
  value       = try(aws_iam_role.cluster[0].name, null)
}

output "cluster_iam_role_unique_id" {
  description = "Unique ID of the IAM role used by the EKS cluster"
  value       = try(aws_iam_role.cluster[0].unique_id, null)
}

################################################################################
# Security Groups
################################################################################

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster control plane (managed by this module)"
  value       = try(aws_security_group.cluster[0].id, var.cluster_security_group_id)
}

output "cluster_security_group_arn" {
  description = "ARN of the cluster security group"
  value       = try(aws_security_group.cluster[0].arn, null)
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = try(aws_security_group.node[0].id, var.node_security_group_id)
}

output "node_security_group_arn" {
  description = "ARN of the node security group"
  value       = try(aws_security_group.node[0].arn, null)
}

################################################################################
# OIDC Provider (IRSA)
################################################################################

output "oidc_provider" {
  description = "OIDC provider URL without https:// prefix"
  value       = try(replace(aws_iam_openid_connect_provider.this[0].url, "https://", ""), null)
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA (IAM Roles for Service Accounts)"
  value       = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

output "oidc_provider_url" {
  description = "OIDC provider URL with https:// prefix"
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

output "kms_key_alias_name" {
  description = "KMS key alias name"
  value       = try(aws_kms_alias.this[0].name, null)
}

output "kms_key_alias_arn" {
  description = "KMS key alias ARN"
  value       = try(aws_kms_alias.this[0].arn, null)
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

output "cluster_creator_access_entry" {
  description = "Cluster creator access entry"
  value       = try(aws_eks_access_entry.cluster_creator[0], null)
}

################################################################################
# Shared Node IAM Role
################################################################################

output "node_iam_role_arn" {
  description = "ARN of the shared node IAM role (used by Karpenter for node provisioning)"
  value       = try(aws_iam_role.node[0].arn, var.node_iam_role_arn)
}

output "node_iam_role_name" {
  description = "Name of the shared node IAM role (used by Karpenter for node provisioning)"
  value       = try(aws_iam_role.node[0].name, null)
}

output "node_iam_role_unique_id" {
  description = "Unique ID of the shared node IAM role"
  value       = try(aws_iam_role.node[0].unique_id, null)
}

################################################################################
# Managed Node Groups
################################################################################

output "managed_node_groups" {
  description = "Map of all managed node groups with complete configuration"
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

output "managed_node_group_resources" {
  description = "Map of managed node group resources"
  value       = { for k, v in module.managed_node_group : k => v.node_group_resources }
}

output "managed_node_group_launch_template_ids" {
  description = "Map of managed node group launch template IDs"
  value       = { for k, v in module.managed_node_group : k => v.launch_template_id }
}

output "managed_node_group_launch_template_arns" {
  description = "Map of managed node group launch template ARNs"
  value       = { for k, v in module.managed_node_group : k => v.launch_template_arn }
}

output "managed_node_group_launch_template_latest_versions" {
  description = "Map of managed node group launch template latest versions"
  value       = { for k, v in module.managed_node_group : k => v.launch_template_latest_version }
}

output "managed_node_group_iam_role_arns" {
  description = "Map of managed node group IAM role ARNs"
  value       = { for k, v in module.managed_node_group : k => v.iam_role_arn }
}

################################################################################
# Self-Managed Node Groups
################################################################################

output "self_managed_node_groups" {
  description = "Map of all self-managed node groups with complete configuration"
  value       = module.self_managed_node_group
}

output "self_managed_node_group_autoscaling_group_ids" {
  description = "Map of self-managed node group ASG IDs"
  value       = { for k, v in module.self_managed_node_group : k => v.autoscaling_group_id }
}

output "self_managed_node_group_autoscaling_group_names" {
  description = "Map of self-managed node group ASG names"
  value       = { for k, v in module.self_managed_node_group : k => v.autoscaling_group_name }
}

output "self_managed_node_group_autoscaling_group_arns" {
  description = "Map of self-managed node group ASG ARNs"
  value       = { for k, v in module.self_managed_node_group : k => v.autoscaling_group_arn }
}

output "self_managed_node_group_launch_template_ids" {
  description = "Map of self-managed node group launch template IDs"
  value       = { for k, v in module.self_managed_node_group : k => v.launch_template_id }
}

output "self_managed_node_group_launch_template_arns" {
  description = "Map of self-managed node group launch template ARNs"
  value       = { for k, v in module.self_managed_node_group : k => v.launch_template_arn }
}

output "self_managed_node_group_iam_role_arns" {
  description = "Map of self-managed node group IAM role ARNs"
  value       = { for k, v in module.self_managed_node_group : k => v.iam_role_arn }
}

output "self_managed_node_group_iam_instance_profile_arns" {
  description = "Map of self-managed node group IAM instance profile ARNs"
  value       = { for k, v in module.self_managed_node_group : k => v.iam_instance_profile_arn }
}

################################################################################
# Fargate Profiles
################################################################################

output "fargate_profiles" {
  description = "Map of all Fargate profiles with complete configuration"
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

output "fargate_profile_statuses" {
  description = "Map of Fargate profile statuses"
  value       = { for k, v in module.fargate_profile : k => v.fargate_profile_status }
}

output "fargate_profile_iam_role_arns" {
  description = "Map of Fargate profile IAM role ARNs"
  value       = { for k, v in module.fargate_profile : k => v.iam_role_arn }
}

################################################################################
# Addons
################################################################################

output "cluster_addons" {
  description = "Map of all cluster addons (both before and after compute)"
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

output "cluster_addon_versions" {
  description = "Map of cluster addon versions"
  value = merge(
    { for k, v in aws_eks_addon.before_compute : k => v.addon_version },
    { for k, v in aws_eks_addon.this : k => v.addon_version }
  )
}

################################################################################
# Region
################################################################################

output "cluster_region" {
  description = "AWS region where the EKS cluster is deployed"
  value       = data.aws_region.current.id
}

output "cluster_region_id" {
  description = "AWS region ID where the EKS cluster is deployed"
  value       = data.aws_region.current.id
}

################################################################################
# Useful for External Consumption
################################################################################

output "eks_name" {
  description = "The name of the EKS cluster (alias for cluster_name for backwards compatibility)"
  value       = try(aws_eks_cluster.this[0].name, null)
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint (alias for cluster_endpoint for backwards compatibility)"
  value       = try(aws_eks_cluster.this[0].endpoint, null)
}

output "openid_connect_arn" {
  description = "ARN of the OIDC provider for IRSA (alias for oidc_provider_arn for backwards compatibility)"
  value       = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

output "eks_region" {
  description = "AWS region where the EKS cluster is deployed (alias for cluster_region for backwards compatibility)"
  value       = data.aws_region.current.id
}
