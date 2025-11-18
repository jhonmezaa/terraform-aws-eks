resource "aws_launch_template" "eks_nodes" {
  for_each = var.node_groups

  name_prefix = "ause1-eks-node-controller-${var.account_name}-${var.project_name}-"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = each.value.disk_size
      volume_type           = each.value.volume_type
      delete_on_termination = each.value.delete_on_termination
      encrypted             = each.value.encrypted
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags_common,
      {
        Name = "ause1-eks-node-controller-${var.account_name}-${var.project_name}-${each.key}"
      }
    )
  }
}
