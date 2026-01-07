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
# OIDC Provider (IRSA)
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA (IAM Roles for Service Accounts)"
  value       = module.eks.oidc_provider_arn
}

################################################################################
# Security Groups
################################################################################

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

################################################################################
# Region
################################################################################

output "cluster_region" {
  description = "AWS region where the EKS cluster is deployed"
  value       = module.eks.cluster_region
}
