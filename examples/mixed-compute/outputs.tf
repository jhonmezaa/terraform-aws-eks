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

################################################################################
# Managed Node Groups
################################################################################

output "managed_node_group_ids" {
  description = "Map of managed node group IDs"
  value       = module.eks.managed_node_group_ids
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

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}
