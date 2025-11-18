# EKS Managed Addons deployed BEFORE node groups are created
# Use before_compute = true for addons that must be present before nodes join the cluster
# Example: vpc-cni, eks-pod-identity-agent
resource "aws_eks_addon" "before_compute" {
  for_each = var.cluster_addons != null ? { for k, v in var.cluster_addons : k => v if try(v.before_compute, false) } : {}

  cluster_name = aws_eks_cluster.this.name
  addon_name   = coalesce(each.value.addon_name, each.key)

  addon_version               = coalesce(each.value.addon_version, data.aws_eks_addon_version.this[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "NONE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  tags = merge(
    var.tags_common,
    try(each.value.tags, {})
  )

  depends_on = [
    aws_eks_cluster.this
  ]
}

# EKS Managed Addons deployed AFTER node groups are created
# Use before_compute = false (default) for addons that require nodes to be present
# Example: coredns, kube-proxy
resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons != null ? { for k, v in var.cluster_addons : k => v if !try(v.before_compute, false) } : {}

  cluster_name = aws_eks_cluster.this.name
  addon_name   = coalesce(each.value.addon_name, each.key)

  addon_version               = coalesce(each.value.addon_version, data.aws_eks_addon_version.this[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "NONE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  tags = merge(
    var.tags_common,
    try(each.value.tags, {})
  )

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}
