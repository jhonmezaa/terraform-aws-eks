################################################################################
# EKS Cluster - Private Cluster Example
#
# This example demonstrates a fully private EKS cluster with:
# - Private-only API endpoint
# - No public access to control plane
# - VPN or Direct Connect required for access
################################################################################

module "eks" {
  source = "../../eks"

  # General
  account_name = var.account_name
  project_name = var.project_name

  # Cluster Configuration
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids # Private subnets only

  # Private API Endpoint
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false # Completely private

  # CloudWatch Logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]
  cloudwatch_log_group_retention_in_days = 90

  # KMS Encryption
  create_kms_key                  = true
  kms_key_description             = "EKS private cluster encryption key"
  kms_key_deletion_window_in_days = 30
  kms_key_enable_key_rotation     = true

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Managed Node Groups in private subnets
  managed_node_groups = {
    private = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      # Must be in private subnets
      subnet_ids = var.private_subnet_ids

      labels = {
        workload = "private"
        network  = "isolated"
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

      # No public IP
      associate_public_ip_address = false

      # IMDSv2 required
      metadata_options_http_tokens                 = "required"
      metadata_options_http_put_response_hop_limit = 2
    }
  }

  # EKS Addons
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }

    eks-pod-identity-agent = {
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

################################################################################
# VPC Endpoints for Private Access (Optional but recommended)
################################################################################

# S3 VPC Endpoint (Gateway type - free)
resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-${var.project_name}-s3-endpoint"
    }
  )
}

# ECR API VPC Endpoint (Interface type)
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-${var.project_name}-ecr-api-endpoint"
    }
  )
}

# ECR DKR VPC Endpoint (Interface type)
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-${var.project_name}-ecr-dkr-endpoint"
    }
  )
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name_prefix = "${var.account_name}-${var.project_name}-vpc-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-${var.project_name}-vpc-endpoints-sg"
    }
  )
}

data "aws_region" "current" {}
data "aws_vpc" "selected" {
  id = var.vpc_id
}
