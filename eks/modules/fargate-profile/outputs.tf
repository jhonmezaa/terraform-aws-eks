output "fargate_profile_id" {
  description = "Fargate profile ID"
  value       = try(aws_eks_fargate_profile.this.id, null)
}

output "fargate_profile_arn" {
  description = "Fargate profile ARN"
  value       = try(aws_eks_fargate_profile.this.arn, null)
}

output "fargate_profile_status" {
  description = "Status of the Fargate profile"
  value       = try(aws_eks_fargate_profile.this.status, null)
}

output "iam_role_arn" {
  description = "IAM role ARN for Fargate pod execution"
  value       = try(aws_iam_role.this[0].arn, var.pod_execution_role_arn)
}

output "iam_role_name" {
  description = "IAM role name for Fargate pod execution"
  value       = try(aws_iam_role.this[0].name, null)
}
