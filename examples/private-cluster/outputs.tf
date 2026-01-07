output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Private endpoint for EKS control plane"
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

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "kms_key_arn" {
  description = "KMS key ARN used for cluster encryption"
  value       = module.eks.kms_key_arn
}

output "managed_node_group_ids" {
  description = "Map of managed node group IDs"
  value       = module.eks.managed_node_group_ids
}

output "vpc_endpoint_s3_id" {
  description = "ID of S3 VPC endpoint"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of ECR API VPC endpoint"
  value       = try(aws_vpc_endpoint.ecr_api[0].id, null)
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of ECR DKR VPC endpoint"
  value       = try(aws_vpc_endpoint.ecr_dkr[0].id, null)
}
