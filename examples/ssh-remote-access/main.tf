################################################################################
# EKS Cluster - SSH Remote Access Example
#
# This example demonstrates managed node groups with SSH access enabled.
# Useful for debugging, troubleshooting, and administrative tasks.
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

  # Managed Node Groups with SSH Access
  managed_node_groups = {
    # Node group with SSH access via EC2 key pair
    ssh_enabled = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      # Enable remote access with EC2 key pair
      key_name                  = var.ec2_key_pair_name
      source_security_group_ids = var.ssh_source_security_groups

      labels = {
        access-method = "ssh"
        environment   = "development"
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

      # Enable public IP for SSH access (use with caution)
      associate_public_ip_address = var.enable_public_ip
    }

    # Node group with SSH + Session Manager (SSM)
    ssm_access = {
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      # SSH key for emergency access
      key_name = var.ec2_key_pair_name

      labels = {
        access-method = "ssm"
        environment   = "production"
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

      # Private instances (no public IP, use SSM)
      associate_public_ip_address = false

      # Enable detailed monitoring
      enable_monitoring = true
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
# Security Group for SSH Access (Optional - if additional rules needed)
################################################################################

resource "aws_security_group" "ssh_access" {
  count = var.create_ssh_security_group ? 1 : 0

  name_prefix = "${var.account_name}-${var.project_name}-ssh-"
  description = "Security group for SSH access to EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from bastion or VPN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
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
      Name = "${var.account_name}-${var.project_name}-ssh-access"
    }
  )
}
