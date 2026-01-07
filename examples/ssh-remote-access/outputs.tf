output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the nodes"
  value       = module.eks.node_security_group_id
}

output "ssh_command_example" {
  description = "Example SSH command to connect to nodes"
  value       = "ssh -i ~/.ssh/${var.ec2_key_pair_name}.pem ec2-user@<node-public-ip>"
}

output "ssm_command_example" {
  description = "Example SSM command to connect to nodes"
  value       = "aws ssm start-session --target <instance-id>"
}

output "managed_node_groups" {
  description = "Managed node groups information"
  value       = module.eks.managed_node_groups
}
