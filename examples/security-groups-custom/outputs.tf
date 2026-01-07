output "cluster_name" {
  value = module.eks.cluster_name
}

output "custom_cluster_security_group_id" {
  value = aws_security_group.cluster.id
}

output "custom_node_security_group_id" {
  value = aws_security_group.node.id
}
