################################################################################
# Access Entries (Modern IAM)
################################################################################

resource "aws_eks_access_entry" "this" {
  for_each = var.create ? var.access_entries : {}

  cluster_name      = aws_eks_cluster.this[0].name
  principal_arn     = each.value.principal_arn
  type              = try(each.value.type, "STANDARD")
  kubernetes_groups = try(each.value.kubernetes_groups, null)
  user_name         = try(each.value.user_name, null)

  tags = merge(
    local.tags,
    try(each.value.tags, {})
  )
}

resource "aws_eks_access_policy_association" "this" {
  for_each = var.create ? local.access_policy_associations : {}

  cluster_name  = aws_eks_cluster.this[0].name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope.type
    namespaces = try(each.value.access_scope.namespaces, [])
  }

  depends_on = [aws_eks_access_entry.this]
}

# Optional: Cluster creator admin permissions
# Only create when NOT using bootstrap_cluster_creator_admin_permissions
# If bootstrap_cluster_creator_admin_permissions = true, AWS creates this automatically
resource "aws_eks_access_entry" "cluster_creator" {
  count = var.create && var.enable_cluster_creator_admin_permissions && !try(var.cluster_access_config.bootstrap_cluster_creator_admin_permissions, true) ? 1 : 0

  cluster_name  = aws_eks_cluster.this[0].name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  type          = "STANDARD"

  tags = merge(
    local.tags,
    { Name = "cluster-creator-admin" }
  )
}

resource "aws_eks_access_policy_association" "cluster_creator" {
  count = var.create && var.enable_cluster_creator_admin_permissions && !try(var.cluster_access_config.bootstrap_cluster_creator_admin_permissions, true) ? 1 : 0

  cluster_name  = aws_eks_cluster.this[0].name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_creator]
}
