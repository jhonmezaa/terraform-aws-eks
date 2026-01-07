resource "aws_launch_template" "this" {
  name_prefix            = "${var.autoscaling_group_name}-"
  description            = "Launch template for ${var.autoscaling_group_name}"
  image_id               = var.ami_id != null ? var.ami_id : data.aws_ami.eks_default[0].id
  instance_type          = var.instance_type
  user_data              = base64encode(local.user_data)
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

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
      {
        Name                                        = var.autoscaling_group_name
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      var.volume_tags,
      { Name = "${var.autoscaling_group_name}-ebs" }
    )
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = merge(
      var.tags,
      { Name = "${var.autoscaling_group_name}-eni" }
    )
  }

  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []

    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []

    content {
      capacity_reservation_preference = try(capacity_reservation_specification.value.capacity_reservation_preference, null)

      dynamic "capacity_reservation_target" {
        for_each = try([capacity_reservation_specification.value.capacity_reservation_target], [])

        content {
          capacity_reservation_id                 = try(capacity_reservation_target.value.capacity_reservation_id, null)
          capacity_reservation_resource_group_arn = try(capacity_reservation_target.value.capacity_reservation_resource_group_arn, null)
        }
      }
    }
  }

  dynamic "enclave_options" {
    for_each = var.enable_enclave ? [1] : []

    content {
      enabled = true
    }
  }

  dynamic "instance_market_options" {
    for_each = var.instance_market_options != null ? [var.instance_market_options] : []

    content {
      market_type = instance_market_options.value.market_type

      dynamic "spot_options" {
        for_each = try([instance_market_options.value.spot_options], [])

        content {
          block_duration_minutes         = try(spot_options.value.block_duration_minutes, null)
          instance_interruption_behavior = try(spot_options.value.instance_interruption_behavior, null)
          max_price                      = try(spot_options.value.max_price, null)
          spot_instance_type             = try(spot_options.value.spot_instance_type, null)
          valid_until                    = try(spot_options.value.valid_until, null)
        }
      }
    }
  }

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

data "aws_ami" "eks_default" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }

  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }
}
