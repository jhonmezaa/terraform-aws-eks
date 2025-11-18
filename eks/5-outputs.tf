output "eks_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "openid_connect_arn" {
  description = "ARN of the OIDC provider for IRSA (IAM Roles for Service Accounts)"
  value       = aws_iam_openid_connect_provider.this[0].arn
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "node_role_arn" {
  description = "ARN of the IAM role for EKS nodes (used by Karpenter for node provisioning)"
  value       = aws_iam_role.nodes.arn
}

output "node_role_name" {
  description = "Name of the IAM role for EKS nodes (used by Karpenter for node provisioning)"
  value       = aws_iam_role.nodes.name
}

output "eks_region" {
  description = "AWS region where the EKS cluster is deployed"
  value       = data.aws_region.current.id
}

output "cluster_addons" {
  description = "Map of cluster addons deployed (both before and after compute)"
  value = merge(
    { for k, v in aws_eks_addon.before_compute : k => {
      id                     = v.id
      arn                    = v.arn
      addon_name             = v.addon_name
      addon_version          = v.addon_version
      service_account_role_arn = v.service_account_role_arn
      created_at             = v.created_at
      modified_at            = v.modified_at
    }},
    { for k, v in aws_eks_addon.this : k => {
      id                     = v.id
      arn                    = v.arn
      addon_name             = v.addon_name
      addon_version          = v.addon_version
      service_account_role_arn = v.service_account_role_arn
      created_at             = v.created_at
      modified_at            = v.modified_at
    }}
  )
}
