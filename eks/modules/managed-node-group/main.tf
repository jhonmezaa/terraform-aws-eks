data "aws_partition" "current" {}

resource "aws_eks_node_group" "this" {
  count = var.create ? 1 : 0

  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.create_iam_role ? aws_iam_role.this[0].arn : var.iam_role_arn
  subnet_ids      = var.subnet_ids

  version         = var.cluster_version
  release_version = var.ami_release_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable            = var.max_unavailable
    max_unavailable_percentage = var.max_unavailable == null ? var.max_unavailable_percentage : null
  }

  capacity_type  = var.capacity_type
  instance_types = var.instance_types
  ami_type       = var.ami_type

  labels = merge(
    var.labels,
    var.cluster_labels
  )

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  # NOTE: `remote_access` cannot be combined with a launch template (the EKS API
  # rejects it). Remote access is configured through the launch template
  # `key_name` plus SSH ingress rules instead (see launch-template.tf).

  # Always pin the numeric latest version. "$Latest" is converted by the API to a
  # number on read and caused a perpetual diff.
  launch_template {
    id      = aws_launch_template.this[0].id
    version = aws_launch_template.this[0].latest_version
  }

  tags = merge(
    var.tags,
    var.node_group_tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.this
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

moved {
  from = aws_eks_node_group.this
  to   = aws_eks_node_group.this[0]
}
