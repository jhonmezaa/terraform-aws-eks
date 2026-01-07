resource "aws_launch_template" "this" {
  name_prefix = "${var.node_group_name}-"
  description = "Launch template for ${var.node_group_name}"

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

  user_data = base64encode(local.user_data)

  tags = var.tags
}

locals {
  user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {
    cluster_name             = var.cluster_name
    cluster_endpoint         = var.cluster_endpoint
    cluster_ca_data          = var.cluster_certificate_authority_data
    pre_bootstrap_user_data  = var.pre_bootstrap_user_data
    post_bootstrap_user_data = var.post_bootstrap_user_data
    bootstrap_extra_args     = var.bootstrap_extra_args
    kubelet_extra_args       = var.kubelet_extra_args
  })
}
