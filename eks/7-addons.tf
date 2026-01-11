################################################################################
# EKS Managed Addons - Before Compute
################################################################################

resource "aws_eks_addon" "before_compute" {
  for_each = var.create ? local.addons_before_compute : {}

  cluster_name = aws_eks_cluster.this[0].name
  addon_name   = coalesce(each.value.addon_name, each.key)

  addon_version               = try(each.value.addon_version, data.aws_eks_addon_version.this[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "NONE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  tags = merge(
    local.tags,
    try(each.value.tags, {})
  )

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }
}

################################################################################
# EKS Managed Addons - After Compute
################################################################################

resource "aws_eks_addon" "this" {
  for_each = var.create ? local.addons_after_compute : {}

  cluster_name = aws_eks_cluster.this[0].name
  addon_name   = coalesce(each.value.addon_name, each.key)

  addon_version               = try(each.value.addon_version, data.aws_eks_addon_version.this[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "NONE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  tags = merge(
    local.tags,
    try(each.value.tags, {})
  )

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  depends_on = [
    module.managed_node_group,
    module.fargate_profile,
  ]
}
