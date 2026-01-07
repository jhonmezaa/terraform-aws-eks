resource "aws_autoscaling_group" "this" {
  name                = var.autoscaling_group_name
  vpc_zone_identifier = var.subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown

  force_delete              = var.force_delete
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  placement_group           = var.placement_group
  enabled_metrics           = var.enabled_metrics
  metrics_granularity       = var.metrics_granularity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  service_linked_role_arn   = var.service_linked_role_arn
  max_instance_lifetime     = var.max_instance_lifetime

  launch_template {
    id      = aws_launch_template.this.id
    version = var.launch_template_use_latest_version ? "$Latest" : aws_launch_template.this.latest_version
  }

  dynamic "tag" {
    for_each = merge(
      var.tags,
      var.autoscaling_group_tags,
      {
        Name                                        = var.autoscaling_group_name
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      }
    )

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []

    content {
      strategy = instance_refresh.value.strategy

      dynamic "preferences" {
        for_each = try([instance_refresh.value.preferences], [])

        content {
          checkpoint_delay       = try(preferences.value.checkpoint_delay, null)
          checkpoint_percentages = try(preferences.value.checkpoint_percentages, null)
          instance_warmup        = try(preferences.value.instance_warmup, null)
          min_healthy_percentage = try(preferences.value.min_healthy_percentage, null)
          skip_matching          = try(preferences.value.skip_matching, null)
        }
      }

      triggers = try(instance_refresh.value.triggers, null)
    }
  }

  dynamic "warm_pool" {
    for_each = var.warm_pool != null ? [var.warm_pool] : []

    content {
      pool_state                  = try(warm_pool.value.pool_state, null)
      min_size                    = try(warm_pool.value.min_size, null)
      max_group_prepared_capacity = try(warm_pool.value.max_group_prepared_capacity, null)

      dynamic "instance_reuse_policy" {
        for_each = try([warm_pool.value.instance_reuse_policy], [])

        content {
          reuse_on_scale_in = try(instance_reuse_policy.value.reuse_on_scale_in, null)
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  depends_on = [
    aws_iam_instance_profile.this
  ]
}
