################################################################################
# EKS Cluster - Upgrade Policy with Extended Support Example
#
# This example demonstrates EKS cluster upgrade policy configuration with
# extended support. Extended support allows running older Kubernetes versions
# beyond standard support lifecycle for compliance or migration needs.
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

  # Cluster Upgrade Policy - Extended Support
  # Allows running versions beyond standard 14-month support window
  cluster_upgrade_policy = {
    # Options:
    # - "STANDARD" - Standard 14-month support lifecycle (default)
    # - "EXTENDED" - Extended support for up to 26 months
    support_type = var.upgrade_support_type
  }

  # Enable cluster creator admin permissions
  cluster_access_config = {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Control Plane Logging - Important for tracking upgrade events
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  cloudwatch_log_group_retention_in_days = 90

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Managed Node Groups
  managed_node_groups = {
    # Primary node group with version tracking
    primary = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        role               = "primary"
        upgrade-policy     = var.upgrade_support_type
        kubernetes-version = var.cluster_version
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

      # Enable detailed monitoring for upgrade tracking
      enable_monitoring = true

      # Update configuration for rolling upgrades
      update_config = {
        max_unavailable_percentage = 33
      }
    }

    # Secondary node group for blue/green upgrades
    secondary = {
      desired_size   = 2
      min_size       = 0
      max_size       = 4
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        role               = "secondary"
        upgrade-policy     = var.upgrade_support_type
        kubernetes-version = var.cluster_version
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

      update_config = {
        max_unavailable_percentage = 50
      }
    }
  }

  # EKS Addons - Keep updated regardless of K8s version
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true # Always use latest compatible version
    }

    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }

    coredns = {
      before_compute = false
      most_recent    = true
      configuration_values = jsonencode({
        replicaCount = 2
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

  tags = merge(
    var.tags,
    {
      UpgradePolicy      = var.upgrade_support_type
      KubernetesVersion  = var.cluster_version
      SupportEndDate     = var.support_end_date
    }
  )
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

################################################################################
# CloudWatch Alarms for Upgrade Monitoring
################################################################################

# Alarm for API server errors (important during upgrades)
resource "aws_cloudwatch_metric_alarm" "api_server_errors" {
  alarm_name          = "${var.account_name}-${var.project_name}-eks-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster/RequestCount"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "EKS API server error rate is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = module.eks.cluster_name
  }

  tags = var.tags
}
