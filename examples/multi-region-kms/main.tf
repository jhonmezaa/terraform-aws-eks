################################################################################
# EKS Cluster - Multi-Region KMS Example
#
# Demonstrates EKS cluster with multi-region KMS key for encryption.
# Useful for disaster recovery and multi-region deployments.
################################################################################

# Multi-Region KMS Key (Primary)
resource "aws_kms_key" "eks_multi_region" {
  description             = "Multi-region KMS key for EKS cluster ${var.account_name}-${var.project_name}"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  multi_region            = true # Enable multi-region replication

  tags = merge(var.tags, {
    Name = "${var.account_name}-${var.project_name}-eks-mr-key"
  })
}

resource "aws_kms_alias" "eks_multi_region" {
  name          = "alias/${var.account_name}-${var.project_name}-eks-mr"
  target_key_id = aws_kms_key.eks_multi_region.key_id
}

# KMS Key Policy for EKS
resource "aws_kms_key_policy" "eks_multi_region" {
  key_id = aws_kms_key.eks_multi_region.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.id}.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

# EKS Module
module "eks" {
  source = "../../eks"

  account_name = var.account_name
  project_name = var.project_name

  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  # Use external multi-region KMS key
  create_kms_key                        = false
  cluster_encryption_config_kms_key_arn = aws_kms_key.eks_multi_region.arn
  cluster_encryption_config_resources   = ["secrets"]

  # CloudWatch logging with KMS encryption
  enabled_cluster_log_types              = ["api", "audit"]
  cloudwatch_log_group_kms_key_id        = aws_kms_key.eks_multi_region.arn
  cloudwatch_log_group_retention_in_days = 90

  enable_irsa = true

  managed_node_groups = {
    general = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = ["t3.large"]

      labels = {
        encryption = "multi-region-kms"
      }

      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 100
          volume_type           = "gp3"
          encrypted             = true
          kms_key_id            = aws_kms_key.eks_multi_region.arn
          delete_on_termination = true
        }
      }]
    }
  }

  cluster_addons = {
    vpc-cni    = { before_compute = true, most_recent = true }
    coredns    = { before_compute = false, most_recent = true }
    kube-proxy = { before_compute = false, most_recent = true }
  }

  tags = merge(var.tags, {
    KMSEncryption = "multi-region"
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
