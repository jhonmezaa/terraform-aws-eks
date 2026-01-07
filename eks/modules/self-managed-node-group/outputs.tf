output "autoscaling_group_id" {
  description = "Autoscaling group ID"
  value       = try(aws_autoscaling_group.this.id, null)
}

output "autoscaling_group_name" {
  description = "Autoscaling group name"
  value       = try(aws_autoscaling_group.this.name, null)
}

output "autoscaling_group_arn" {
  description = "Autoscaling group ARN"
  value       = try(aws_autoscaling_group.this.arn, null)
}

output "autoscaling_group_min_size" {
  description = "Minimum size of the autoscaling group"
  value       = try(aws_autoscaling_group.this.min_size, null)
}

output "autoscaling_group_max_size" {
  description = "Maximum size of the autoscaling group"
  value       = try(aws_autoscaling_group.this.max_size, null)
}

output "autoscaling_group_desired_capacity" {
  description = "Desired capacity of the autoscaling group"
  value       = try(aws_autoscaling_group.this.desired_capacity, null)
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
  description = "IAM role ARN for instances"
  value       = try(aws_iam_role.this[0].arn, null)
}

output "iam_role_name" {
  description = "IAM role name for instances"
  value       = try(aws_iam_role.this[0].name, var.iam_role_name)
}

output "iam_instance_profile_arn" {
  description = "IAM instance profile ARN"
  value       = try(aws_iam_instance_profile.this.arn, null)
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value       = try(aws_iam_instance_profile.this.name, null)
}
