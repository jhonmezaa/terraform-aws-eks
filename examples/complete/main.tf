################################################################################
# EKS Cluster - Complete Example
#
# This example demonstrates all features of the EKS module:
# - Managed node groups with custom configurations
# - Fargate profiles for serverless workloads
# - CloudWatch logging for control plane
# - KMS encryption for cluster secrets
# - Access entries for IAM users/roles
# - IRSA with OIDC provider
# - All EKS addons with proper deployment ordering
################################################################################

################################################################################
# KMS Key for Cluster Encryption (Optional - can use existing key)
################################################################################

module "eks" {
  source = "../../eks"

  # General
  account_name = var.account_name
  project_name = var.project_name

  # Cluster Configuration
  cluster_version                      = var.cluster_version
  vpc_id                               = var.vpc_id
  subnet_ids                           = var.subnet_ids
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # CloudWatch Logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  cloudwatch_log_group_retention_in_days = 90
  cloudwatch_log_group_class             = "STANDARD"

  # KMS Encryption
  create_kms_key                  = true
  kms_key_description             = "EKS cluster encryption key for ${var.project_name}"
  kms_key_deletion_window_in_days = 30
  kms_key_enable_key_rotation     = true

  # Access Entries (Modern IAM - replaces aws-auth ConfigMap)
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # Admin access for DevOps team
    devops_admin = {
      principal_arn     = var.devops_team_role_arn
      type              = "STANDARD"
      kubernetes_groups = ["system:masters"]

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # Read-only access for developers
    developer_readonly = {
      principal_arn     = var.developer_team_role_arn
      type              = "STANDARD"
      kubernetes_groups = ["developers"]

      policy_associations = {
        view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Managed Node Groups
  managed_node_groups = {
    # General purpose node group
    general = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        workload = "general"
        tier     = "standard"
      }

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

      # Enable detailed monitoring
      enable_monitoring = true

      # Metadata service v2 (IMDSv2) required
      metadata_options_http_tokens                 = "required"
      metadata_options_http_put_response_hop_limit = 2
    }

    # Spot instances for batch workloads
    spot = {
      desired_size   = 2
      min_size       = 0
      max_size       = 10
      instance_types = ["t3.large", "t3a.large"]
      capacity_type  = "SPOT"

      labels = {
        workload     = "batch"
        tier         = "spot"
        spot-enabled = "true"
      }

      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]

      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 80
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
        }
      }]
    }

    # ARM-based nodes for cost optimization
    arm = {
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = ["t4g.medium"]
      capacity_type  = "ON_DEMAND"
      ami_type       = "AL2023_ARM_64_STANDARD"

      labels = {
        workload     = "general"
        architecture = "arm64"
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
    }
  }

  # Fargate Profiles
  fargate_profiles = {
    # Fargate profile for kube-system namespace
    kube_system = {
      selectors = [{
        namespace = "kube-system"
        labels = {
          fargate = "true"
        }
      }]

      # Use private subnets for Fargate
      subnet_ids = var.private_subnet_ids
    }

    # Fargate profile for serverless workloads
    serverless = {
      selectors = [
        {
          namespace = "serverless"
        },
        {
          namespace = "batch"
          labels = {
            compute = "fargate"
          }
        }
      ]

      subnet_ids = var.private_subnet_ids
    }
  }

  # EKS Addons with proper deployment ordering
  cluster_addons = {
    # Phase 1: Deploy before nodes
    vpc-cni = {
      before_compute       = true
      most_recent          = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          ENABLE_POD_ENI           = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }

    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }

    # Phase 2: Deploy after nodes
    coredns = {
      before_compute       = false
      most_recent          = true
      configuration_values = jsonencode({
        replicaCount = 2
        resources = {
          limits = {
            cpu    = "100m"
            memory = "150Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "150Mi"
          }
        }
      })
    }

    kube-proxy = {
      before_compute = false
      most_recent    = true
    }

    aws-ebs-csi-driver = {
      before_compute           = false
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
  }

  tags = var.tags
}

################################################################################
# IAM Role for EBS CSI Driver (IRSA)
################################################################################

data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.account_name}-${var.project_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-${var.project_name}-ebs-csi-driver"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
