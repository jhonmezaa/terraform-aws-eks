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
# OIDC Provider (IRSA)
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC provider URL without https:// prefix"
  value       = module.eks.oidc_provider
}

################################################################################
# Karpenter
################################################################################

output "karpenter_controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_controller_role_name" {
  description = "Name of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.name
}

output "karpenter_interruption_queue_name" {
  description = "Name of the SQS queue for Karpenter interruption handling"
  value       = aws_sqs_queue.karpenter_interruption.name
}

output "karpenter_interruption_queue_arn" {
  description = "ARN of the SQS queue for Karpenter interruption handling"
  value       = aws_sqs_queue.karpenter_interruption.arn
}

################################################################################
# Node IAM Role (for Karpenter provisioned nodes)
################################################################################

output "node_iam_role_arn" {
  description = "ARN of the node IAM role (used by Karpenter for provisioning)"
  value       = module.eks.node_iam_role_arn
}

output "node_iam_role_name" {
  description = "Name of the node IAM role (used by Karpenter for provisioning)"
  value       = module.eks.node_iam_role_name
}

################################################################################
# Security Groups
################################################################################

output "cluster_security_group_id" {
  description = "Security group ID for the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = module.eks.node_security_group_id
}

################################################################################
# Managed Node Groups
################################################################################

output "managed_node_group_ids" {
  description = "Map of managed node group IDs"
  value       = module.eks.managed_node_group_ids
}

################################################################################
# Karpenter Helm Values
################################################################################

output "karpenter_helm_values" {
  description = "Suggested Helm values for Karpenter installation"
  value = {
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
      }
    }
    settings = {
      clusterName            = module.eks.cluster_name
      clusterEndpoint        = module.eks.cluster_endpoint
      interruptionQueue      = aws_sqs_queue.karpenter_interruption.name
      defaultInstanceProfile = module.eks.node_iam_role_name
    }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
    nodeSelector = {
      role = "karpenter"
    }
  }
}
