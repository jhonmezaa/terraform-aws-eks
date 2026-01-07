################################################################################
# EKS Cluster - Self-Managed Nodes Example
#
# This example demonstrates using self-managed Auto Scaling Groups instead of
# EKS managed node groups. This provides more control over instance configuration
# and autoscaling behavior.
################################################################################

module "eks" {
  source = "../../eks"

  # General
  account_name = var.account_name
  project_name = var.project_name

  # Cluster Configuration
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Self-Managed Node Groups
  self_managed_node_groups = {
    # General purpose self-managed nodes
    general = {
      min_size         = 2
      max_size         = 6
      desired_capacity = 3

      instance_type      = "t3.large"
      ami_architecture   = "x86_64"
      key_name           = var.ssh_key_name # Optional SSH key for debugging

      # ASG Configuration
      health_check_type         = "EC2"
      health_check_grace_period = 300
      default_cooldown          = 300
      termination_policies      = ["OldestLaunchTemplate", "OldestInstance"]

      # Enable metrics
      enabled_metrics = [
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupMaxSize",
        "GroupMinSize",
        "GroupPendingInstances",
        "GroupStandbyInstances",
        "GroupTerminatingInstances",
        "GroupTotalInstances"
      ]

      # Instance Refresh for zero-downtime updates
      instance_refresh = {
        strategy = "Rolling"
        preferences = {
          min_healthy_percentage = 66
          instance_warmup        = 300
        }
      }

      # Block device configuration
      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 100
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 125
          encrypted             = true
          delete_on_termination = true
        }
      }]

      # Advanced user data for custom configuration
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        # Install CloudWatch agent
        yum install -y amazon-cloudwatch-agent

        # Configure system settings
        echo "net.ipv4.tcp_max_syn_backlog = 8096" >> /etc/sysctl.conf
        sysctl -p
      EOT

      # Kubelet extra args
      kubelet_extra_args = "--node-labels=workload=general,managed-by=asg --max-pods=110"
    }

    # Compute-optimized nodes for CPU-intensive workloads
    compute = {
      min_size         = 1
      max_size         = 10
      desired_capacity = 2

      instance_type    = "c6i.2xlarge"
      ami_architecture = "x86_64"

      health_check_type         = "EC2"
      health_check_grace_period = 300

      # Spot instance configuration for cost savings
      instance_market_options = {
        market_type = "spot"
        spot_options = {
          max_price          = "0.15" # Maximum price per hour
          spot_instance_type = "one-time"
        }
      }

      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 80
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
        }
      }]

      kubelet_extra_args = "--node-labels=workload=compute,instance-type=spot --max-pods=110"
    }

    # Memory-optimized nodes for data processing
    memory = {
      min_size         = 0
      max_size         = 5
      desired_capacity = 2

      instance_type    = "r6i.xlarge"
      ami_architecture = "x86_64"

      # Warm pool for faster scaling
      warm_pool = {
        pool_state                  = "Stopped"
        min_size                    = 1
        max_group_prepared_capacity = 2
      }

      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 120
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
        }
      }]

      kubelet_extra_args = "--node-labels=workload=memory,instance-type=memory-optimized --max-pods=110"
    }
  }

  # EKS Addons
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
    coredns = {
      before_compute = false
      most_recent    = true
    }
    kube-proxy = {
      before_compute = false
      most_recent    = true
    }
  }

  tags = var.tags
}
