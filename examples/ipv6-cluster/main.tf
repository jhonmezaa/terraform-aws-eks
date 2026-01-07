################################################################################
# EKS Cluster - IPv6 Dual-Stack Example
#
# This example demonstrates an EKS cluster with IPv6 dual-stack networking.
# Pods receive both IPv4 and IPv6 addresses, enabling IPv6-native applications.
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

  # IPv6 Configuration
  cluster_ip_family        = "ipv6"
  cluster_service_ipv6_cidr = var.cluster_service_ipv6_cidr # e.g., "fd00::/108"

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Managed Node Groups
  managed_node_groups = {
    general = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        workload    = "general"
        ip-family   = "ipv6"
      }

      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 100
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
        }
      }]

      # Enable IPv6 on network interfaces
      associate_public_ip_address = false
    }
  }

  # EKS Addons with IPv6 support
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          # Enable IPv6 in VPC-CNI
          ENABLE_IPv6                 = "true"
          ENABLE_PREFIX_DELEGATION    = "true"
          ENABLE_POD_ENI              = "false"
          WARM_IP_TARGET              = "3"
          MINIMUM_IP_TARGET           = "2"
        }
      })
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
