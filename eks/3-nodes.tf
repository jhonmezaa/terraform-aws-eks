resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.subnet_ids

  capacity_type   = each.value.capacity_type
  instance_types  = each.value.instance_types
  release_version = nonsensitive(data.aws_ssm_parameter.eks_version.value)

  launch_template {
    id      = aws_launch_template.eks_nodes[each.key].id
    version = "$Latest"
  }

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role                      = each.key
    "karpenter.sh/controller" = true
  }

  tags = var.tags_common

  depends_on = [aws_iam_role_policy_attachment.nodes]
}
