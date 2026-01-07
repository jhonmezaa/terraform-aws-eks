resource "aws_eks_node_group" "this" {
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
    max_unavailable_percentage = var.max_unavailable_percentage
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

  dynamic "remote_access" {
    for_each = var.enable_remote_access ? [1] : []
    content {
      ec2_ssh_key               = var.remote_access_ec2_ssh_key
      source_security_group_ids = var.remote_access_source_security_group_ids
    }
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = var.launch_template_use_latest_version ? "$Latest" : aws_launch_template.this.latest_version
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
