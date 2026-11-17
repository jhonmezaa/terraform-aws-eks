resource "aws_launch_template" "this" {
  count = var.create ? 1 : 0

  name_prefix = "${var.node_group_name}-"
  description = "Launch template for ${var.node_group_name}"

  # SSH access: the EKS API does not allow `remote_access` together with a
  # launch template, so the key pair is set here instead.
  key_name = var.enable_remote_access ? var.remote_access_ec2_ssh_key : null

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = lookup(block_device_mappings.value.ebs, "volume_size", null)
        volume_type           = lookup(block_device_mappings.value.ebs, "volume_type", "gp3")
        iops                  = lookup(block_device_mappings.value.ebs, "iops", null)
        throughput            = lookup(block_device_mappings.value.ebs, "throughput", null)
        encrypted             = lookup(block_device_mappings.value.ebs, "encrypted", true)
        kms_key_id            = lookup(block_device_mappings.value.ebs, "kms_key_id", null)
        delete_on_termination = lookup(block_device_mappings.value.ebs, "delete_on_termination", true)
      }
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.metadata_options_http_tokens
    http_put_response_hop_limit = var.metadata_options_http_put_response_hop_limit
    instance_metadata_tags      = var.enable_instance_metadata_tags ? "enabled" : "disabled"
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = true
    security_groups             = var.security_group_ids
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      var.instance_tags,
      { Name = var.node_group_name }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      var.volume_tags,
      { Name = "${var.node_group_name}-ebs" }
    )
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = merge(
      var.tags,
      { Name = "${var.node_group_name}-eni" }
    )
  }

  user_data = local.has_custom_user_data ? base64encode(local.user_data) : null

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.post_bootstrap_user_data == "" || local.is_custom
      error_message = "post_bootstrap_user_data solo se admite con ami_type = \"CUSTOM\": en AMIs gestionadas EKS añade el bootstrap al final del user data."
    }

    precondition {
      condition     = var.bootstrap_extra_args == "" || local.is_custom || local.is_bottlerocket
      error_message = "bootstrap_extra_args solo se admite con ami_type = \"CUSTOM\" o Bottlerocket (configuración TOML)."
    }

    precondition {
      condition     = var.kubelet_extra_args == "" || local.is_custom || local.is_al2023
      error_message = "kubelet_extra_args solo se admite con AL2023 (se traduce a NodeConfig) o ami_type = \"CUSTOM\"."
    }

    precondition {
      condition     = var.pre_bootstrap_user_data == "" || local.is_custom || local.is_al2 || local.is_al2023
      error_message = "pre_bootstrap_user_data solo se admite con AMIs AL2, AL2023 o ami_type = \"CUSTOM\"."
    }
  }
}

moved {
  from = aws_launch_template.this
  to   = aws_launch_template.this[0]
}

################################################################################
# SSH ingress for remote access
################################################################################

resource "aws_vpc_security_group_ingress_rule" "remote_access" {
  for_each = var.create && var.enable_remote_access ? { for i, sg in var.remote_access_source_security_group_ids : tostring(i) => sg } : {}

  security_group_id            = var.security_group_ids[0]
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH remote access to ${var.node_group_name} nodes"

  tags = merge(
    var.tags,
    { Name = "${var.node_group_name}-ssh-${each.key}" }
  )
}

################################################################################
# User data
################################################################################

locals {
  is_custom       = var.ami_type == "CUSTOM"
  is_al2          = startswith(var.ami_type, "AL2_")
  is_al2023       = startswith(var.ami_type, "AL2023_")
  is_bottlerocket = startswith(var.ami_type, "BOTTLEROCKET_")

  # Only include user_data if there are custom scripts
  # Otherwise, let EKS handle the bootstrap automatically
  has_custom_user_data = var.pre_bootstrap_user_data != "" || var.post_bootstrap_user_data != "" || var.bootstrap_extra_args != "" || var.kubelet_extra_args != ""

  # Shell script part (shebang added when missing)
  pre_bootstrap_script = startswith(var.pre_bootstrap_user_data, "#!") ? var.pre_bootstrap_user_data : "#!/bin/bash\n${var.pre_bootstrap_user_data}"

  # kubelet flags for AL2023 nodeadm (space separated string -> list)
  kubelet_flags = compact(split(" ", trimspace(var.kubelet_extra_args)))

  # EKS managed AMIs (AL2/AL2023): user data must be a MIME multi-part archive.
  # EKS merges its own bootstrap part after ours, so only pre-bootstrap content
  # (and, for AL2023, a partial NodeConfig) can be provided.
  # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data
  mime_user_data = templatefile("${path.module}/templates/mime-user-data.tpl", {
    include_script          = var.pre_bootstrap_user_data != ""
    script                  = local.pre_bootstrap_script
    include_nodeconfig      = local.is_al2023 && length(local.kubelet_flags) > 0
    kubelet_flags_formatted = join("\n", [for f in local.kubelet_flags : "      - ${jsonencode(f)}"])
  })

  # CUSTOM AMIs: the user data is responsible for bootstrapping (AL2 bootstrap.sh)
  custom_user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {
    cluster_name             = var.cluster_name
    cluster_endpoint         = var.cluster_endpoint
    cluster_ca_data          = var.cluster_certificate_authority_data
    pre_bootstrap_user_data  = var.pre_bootstrap_user_data
    post_bootstrap_user_data = var.post_bootstrap_user_data
    bootstrap_extra_args     = var.bootstrap_extra_args
    kubelet_extra_args       = var.kubelet_extra_args
  })

  user_data = !local.has_custom_user_data ? "" : (
    local.is_custom ? local.custom_user_data : (
      local.is_bottlerocket ? var.bootstrap_extra_args : local.mime_user_data
    )
  )
}
