################################################################################
# EKS Cluster - AWS Outposts Example
#
# This example demonstrates EKS on AWS Outposts for on-premises workloads.
# AWS Outposts extends AWS infrastructure to on-premises locations for
# consistent hybrid cloud deployment.
################################################################################

module "eks" {
  source = "../../eks"

  # General
  account_name = var.account_name
  project_name = var.project_name

  # Cluster Configuration
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.outpost_subnet_ids # Must be Outpost subnets

  # AWS Outpost Configuration
  outpost_config = {
    # ARN of the Outpost where control plane instances will run
    outpost_arns = [var.outpost_arn]

    # EC2 instance type for control plane nodes on Outpost
    # Must be available on your Outpost (e.g., m5.xlarge, c5.2xlarge)
    control_plane_instance_type = var.control_plane_instance_type

    # Optional: Control plane placement configuration
    # Specifies placement group for control plane instances
    control_plane_placement = {
      group_name = var.placement_group_name
    }
  }

  # Endpoint Access
  # For Outpost clusters, both endpoints must be enabled
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Managed Node Groups on Outpost
  managed_node_groups = {
    # On-premises workload nodes
    outpost_nodes = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = [var.node_instance_type] # Must be available on Outpost
      capacity_type  = "ON_DEMAND"              # Spot not available on Outposts

      # Ensure nodes are on Outpost subnets
      subnet_ids = var.outpost_subnet_ids

      labels = {
        location = "outpost"
        workload = "on-premises"
      }

      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 100
          volume_type           = "gp2" # Check Outpost supported volume types
          encrypted             = true
          delete_on_termination = true
        }
      }]

      # No public IP on Outpost subnets
      associate_public_ip_address = false

      # IMDSv2 required
      metadata_options_http_tokens                 = "required"
      metadata_options_http_put_response_hop_limit = 2
    }

    # Edge computing nodes
    edge_compute = {
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = [var.edge_instance_type]
      capacity_type  = "ON_DEMAND"

      subnet_ids = var.outpost_subnet_ids

      labels = {
        location = "outpost"
        workload = "edge-computing"
        latency  = "ultra-low"
      }

      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 80
          volume_type           = "gp2"
          encrypted             = true
          delete_on_termination = true
        }
      }]

      associate_public_ip_address = false
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
      # Run CoreDNS on Outpost nodes
      configuration_values = jsonencode({
        nodeSelector = {
          location = "outpost"
        }
        tolerations = [{
          key      = "outpost"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
      })
    }

    kube-proxy = {
      before_compute = false
      most_recent    = true
    }
  }

  tags = var.tags
}

################################################################################
# Local Gateway Route Table Association (for Outpost local connectivity)
################################################################################

# Note: Configure local gateway routes for on-premises connectivity
# This requires additional AWS Outposts networking setup
