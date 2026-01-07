################################################################################
# Cluster
################################################################################

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = module.eks.cluster_version
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

################################################################################
# OIDC Provider (IRSA)
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA (IAM Roles for Service Accounts)"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC provider URL without https:// prefix"
  value       = module.eks.oidc_provider
}

################################################################################
# CloudWatch
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group for cluster logs"
  value       = module.eks.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch log group for cluster logs"
  value       = module.eks.cloudwatch_log_group_arn
}

################################################################################
# KMS
################################################################################

output "kms_key_id" {
  description = "KMS key ID used for cluster encryption"
  value       = module.eks.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for cluster encryption"
  value       = module.eks.kms_key_arn
}

################################################################################
# Access Entries
################################################################################

output "access_entries" {
  description = "Map of access entries created"
  value       = module.eks.access_entries
}

################################################################################
# Managed Node Groups
################################################################################

output "managed_node_group_ids" {
  description = "Map of managed node group IDs"
  value       = module.eks.managed_node_group_ids
}

output "managed_node_group_arns" {
  description = "Map of managed node group ARNs"
  value       = module.eks.managed_node_group_arns
}

output "managed_node_group_statuses" {
  description = "Map of managed node group statuses"
  value       = module.eks.managed_node_group_statuses
}

################################################################################
# Fargate Profiles
################################################################################

output "fargate_profile_ids" {
  description = "Map of Fargate profile IDs"
  value       = module.eks.fargate_profile_ids
}

output "fargate_profile_arns" {
  description = "Map of Fargate profile ARNs"
  value       = module.eks.fargate_profile_arns
}

output "fargate_profile_statuses" {
  description = "Map of Fargate profile statuses"
  value       = module.eks.fargate_profile_statuses
}

################################################################################
# Addons
################################################################################

output "cluster_addon_arns" {
  description = "Map of cluster addon ARNs"
  value       = module.eks.cluster_addon_arns
}

output "cluster_addon_versions" {
  description = "Map of cluster addon versions"
  value       = module.eks.cluster_addon_versions
}

################################################################################
# Security Groups
################################################################################

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

################################################################################
# IAM
################################################################################

output "node_iam_role_arn" {
  description = "ARN of the shared node IAM role"
  value       = module.eks.node_iam_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.arn
}

################################################################################
# Region
################################################################################

output "cluster_region" {
  description = "AWS region where the EKS cluster is deployed"
  value       = module.eks.cluster_region
}
