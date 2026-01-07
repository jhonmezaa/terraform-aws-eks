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
# Self-Managed Node Groups
################################################################################

output "self_managed_node_group_autoscaling_group_ids" {
  description = "Map of self-managed node group ASG IDs"
  value       = module.eks.self_managed_node_group_autoscaling_group_ids
}

output "self_managed_node_group_autoscaling_group_names" {
  description = "Map of self-managed node group ASG names"
  value       = module.eks.self_managed_node_group_autoscaling_group_names
}

output "self_managed_node_group_autoscaling_group_arns" {
  description = "Map of self-managed node group ASG ARNs"
  value       = module.eks.self_managed_node_group_autoscaling_group_arns
}

output "self_managed_node_group_launch_template_ids" {
  description = "Map of self-managed node group launch template IDs"
  value       = module.eks.self_managed_node_group_launch_template_ids
}

output "self_managed_node_group_iam_role_arns" {
  description = "Map of self-managed node group IAM role ARNs"
  value       = module.eks.self_managed_node_group_iam_role_arns
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

################################################################################
# Region
################################################################################

output "cluster_region" {
  description = "AWS region where the EKS cluster is deployed"
  value       = module.eks.cluster_region
}
