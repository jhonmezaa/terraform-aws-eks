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
  description = "Current Kubernetes version of the cluster"
  value       = module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "EKS platform version"
  value       = module.eks.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks.cluster_status
}

################################################################################
# Upgrade Policy
################################################################################

output "upgrade_support_type" {
  description = "Current upgrade support type (STANDARD or EXTENDED)"
  value       = var.upgrade_support_type
}

output "support_end_date" {
  description = "Estimated support end date for current version"
  value       = var.support_end_date
}

################################################################################
# OIDC Provider
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC provider URL"
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
# Node Groups
################################################################################

output "managed_node_groups" {
  description = "Managed node groups information"
  value       = module.eks.managed_node_groups
}

################################################################################
# CloudWatch
################################################################################

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for control plane logs"
  value       = module.eks.cloudwatch_log_group_name
}

output "api_server_alarm_arn" {
  description = "CloudWatch alarm ARN for API server errors"
  value       = aws_cloudwatch_metric_alarm.api_server_errors.arn
}
