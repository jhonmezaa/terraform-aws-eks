output "node_group_id" {
  description = "EKS node group ID"
  value       = try(aws_eks_node_group.this.id, null)
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = try(aws_eks_node_group.this.arn, null)
}

output "node_group_status" {
  description = "Status of the node group"
  value       = try(aws_eks_node_group.this.status, null)
}

output "node_group_resources" {
  description = "Resources associated with the node group"
  value       = try(aws_eks_node_group.this.resources, null)
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = try(aws_launch_template.this.id, null)
}

output "launch_template_arn" {
  description = "Launch template ARN"
  value       = try(aws_launch_template.this.arn, null)
}

output "launch_template_latest_version" {
  description = "Latest version of launch template"
  value       = try(aws_launch_template.this.latest_version, null)
}

output "iam_role_arn" {
  description = "IAM role ARN for nodes"
  value       = try(aws_iam_role.this[0].arn, var.iam_role_arn)
}

output "iam_role_name" {
  description = "IAM role name for nodes"
  value       = try(aws_iam_role.this[0].name, null)
}
