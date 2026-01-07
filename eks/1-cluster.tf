################################################################################
# Cluster IAM Role
################################################################################

resource "aws_iam_role" "cluster" {
  count = var.create && var.create_cluster_iam_role ? 1 : 0

  name        = !var.cluster_iam_role_use_name_prefix ? coalesce(var.cluster_iam_role_name, "${local.cluster_name}-cluster") : null
  name_prefix = var.cluster_iam_role_use_name_prefix ? "${local.cluster_name}-cluster-" : null
  path        = var.cluster_iam_role_path
  description = var.cluster_iam_role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.${local.dns_suffix}"
        }
      }
    ]
  })

  permissions_boundary = var.cluster_iam_role_permissions_boundary

  tags = merge(
    local.tags,
    var.cluster_iam_role_tags,
    { Name = "${local.cluster_name}-cluster" }
  )
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = var.create && var.create_cluster_iam_role ? var.cluster_iam_role_policies : {}

  role       = aws_iam_role.cluster[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "cluster_additional" {
  for_each = var.create && var.create_cluster_iam_role ? var.cluster_iam_role_additional_policies : {}

  role       = aws_iam_role.cluster[0].name
  policy_arn = each.value
}

################################################################################
# EKS Cluster
################################################################################

resource "aws_eks_cluster" "this" {
  count = var.create ? 1 : 0

  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = local.cluster_iam_role_arn

  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = compact(concat([local.cluster_security_group_id], var.cluster_additional_security_group_ids))
    subnet_ids              = var.subnet_ids
  }

  dynamic "encryption_config" {
    for_each = var.create_kms_key || var.cluster_encryption_config_kms_key_arn != null ? [1] : []

    content {
      provider {
        key_arn = local.cluster_encryption_kms_key_arn
      }
      resources = var.cluster_encryption_config_resources
    }
  }

  dynamic "kubernetes_network_config" {
    for_each = var.cluster_ip_family != null || var.cluster_service_ipv4_cidr != null || var.cluster_service_ipv6_cidr != null || var.enable_auto_mode ? [1] : []

    content {
      ip_family         = var.cluster_ip_family
      service_ipv4_cidr = var.cluster_service_ipv4_cidr
      service_ipv6_cidr = var.cluster_service_ipv6_cidr

      dynamic "elastic_load_balancing" {
        for_each = var.enable_auto_mode ? [1] : []

        content {
          enabled = true
        }
      }
    }
  }

  dynamic "outpost_config" {
    for_each = var.outpost_config != null ? [var.outpost_config] : []

    content {
      control_plane_instance_type = outpost_config.value.control_plane_instance_type
      outpost_arns                = outpost_config.value.outpost_arns

      dynamic "control_plane_placement" {
        for_each = try([outpost_config.value.control_plane_placement], [])

        content {
          group_name = control_plane_placement.value.group_name
        }
      }
    }
  }

  dynamic "upgrade_policy" {
    for_each = var.cluster_upgrade_policy != null ? [var.cluster_upgrade_policy] : []

    content {
      support_type = try(upgrade_policy.value.support_type, null)
    }
  }

  dynamic "access_config" {
    for_each = var.cluster_access_config != null ? [var.cluster_access_config] : []

    content {
      authentication_mode                         = try(access_config.value.authentication_mode, "API_AND_CONFIG_MAP")
      bootstrap_cluster_creator_admin_permissions = try(access_config.value.bootstrap_cluster_creator_admin_permissions, true)
    }
  }

  dynamic "compute_config" {
    for_each = var.enable_auto_mode ? [1] : []

    content {
      enabled       = true
      node_pools    = var.auto_mode_node_pools
      node_role_arn = var.auto_mode_node_role_arn != null ? var.auto_mode_node_role_arn : (var.create_node_iam_role ? aws_iam_role.node[0].arn : null)
    }
  }

  dynamic "storage_config" {
    for_each = var.enable_auto_mode ? [1] : []

    content {
      block_storage {
        enabled = true
      }
    }
  }

  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons

  tags = merge(
    local.cluster_tags,
    var.cluster_tags
  )

  timeouts {
    create = try(var.cluster_timeouts.create, null)
    update = try(var.cluster_timeouts.update, null)
    delete = try(var.cluster_timeouts.delete, null)
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.this,
    aws_security_group_rule.cluster_ingress_node_443,
    aws_security_group_rule.node_ingress_cluster_443,
  ]
}

################################################################################
# Shared Node IAM Role (for all node groups)
################################################################################

resource "aws_iam_role" "node" {
  count = var.create && var.create_node_iam_role ? 1 : 0

  name        = !var.node_iam_role_use_name_prefix ? coalesce(var.node_iam_role_name, "${local.cluster_name}-node") : null
  name_prefix = var.node_iam_role_use_name_prefix ? "${local.cluster_name}-node-" : null
  path        = var.node_iam_role_path
  description = var.node_iam_role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.${local.dns_suffix}"
        }
      }
    ]
  })

  permissions_boundary = var.node_iam_role_permissions_boundary

  tags = merge(
    local.tags,
    var.node_iam_role_tags,
    { Name = "${local.cluster_name}-node" }
  )
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = var.create && var.create_node_iam_role ? var.node_iam_policies : {}

  role       = aws_iam_role.node[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "node_additional" {
  for_each = var.create && var.create_node_iam_role ? var.node_iam_additional_policies : {}

  role       = aws_iam_role.node[0].name
  policy_arn = each.value
}

# Auto Mode IAM Policies
resource "aws_iam_role_policy_attachment" "node_auto_mode" {
  for_each = var.create && var.create_node_iam_role && var.enable_auto_mode ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  ]) : []

  role       = aws_iam_role.node[0].name
  policy_arn = each.value
}
