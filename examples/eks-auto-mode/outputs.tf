################################################################################
# Cluster Outputs
################################################################################

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

################################################################################
# Auto Mode Outputs
################################################################################

output "auto_mode_enabled" {
  description = "Whether EKS Auto Mode is enabled"
  value       = module.eks.auto_mode_enabled
}

output "auto_mode_node_pools" {
  description = "List of node pools configured for Auto Mode"
  value       = module.eks.auto_mode_node_pools
}

output "auto_mode_node_role_arn" {
  description = "IAM role ARN used by Auto Mode nodes"
  value       = module.eks.auto_mode_node_role_arn
}

################################################################################
# Security Group Outputs
################################################################################

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

################################################################################
# IRSA Outputs
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_url
}
