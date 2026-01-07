################################################################################
# Cluster
################################################################################

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = module.eks.cluster_platform_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks.cluster_status
}

################################################################################
# OIDC Provider
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC provider URL without https://"
  value       = module.eks.oidc_provider
}

################################################################################
# IAM Roles
################################################################################

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN for EKS nodes"
  value       = module.eks.node_iam_role_arn
}

output "node_iam_role_name" {
  description = "IAM role name for EKS nodes"
  value       = module.eks.node_iam_role_name
}

################################################################################
# Security Groups
################################################################################

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the nodes"
  value       = module.eks.node_security_group_id
}

################################################################################
# Node Groups
################################################################################

output "managed_node_groups" {
  description = "Managed node groups on Outpost"
  value       = module.eks.managed_node_groups
}

################################################################################
# Outpost Information
################################################################################

output "outpost_arn" {
  description = "ARN of the Outpost hosting the cluster"
  value       = var.outpost_arn
}

output "control_plane_instance_type" {
  description = "Instance type used for control plane on Outpost"
  value       = var.control_plane_instance_type
}
