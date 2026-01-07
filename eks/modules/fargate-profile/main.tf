resource "aws_eks_fargate_profile" "this" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = var.fargate_profile_name
  pod_execution_role_arn = var.create_iam_role ? aws_iam_role.this[0].arn : var.pod_execution_role_arn
  subnet_ids             = var.subnet_ids

  dynamic "selector" {
    for_each = var.selectors
    content {
      namespace = selector.value.namespace
      labels    = try(selector.value.labels, {})
    }
  }

  tags = merge(
    var.tags,
    var.fargate_profile_tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.pod_execution
  ]

  timeouts {
    create = try(var.timeouts.create, null)
    delete = try(var.timeouts.delete, null)
  }
}
