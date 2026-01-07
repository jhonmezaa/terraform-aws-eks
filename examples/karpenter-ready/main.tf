################################################################################
# EKS Cluster - Karpenter Ready Example
#
# This example demonstrates an EKS cluster optimized for Karpenter autoscaling.
# Karpenter is a modern, high-performance autoscaler that can provision nodes
# in seconds based on pending pod requirements.
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

  # IRSA (IAM Roles for Service Accounts) - Required for Karpenter
  enable_irsa = true

  # Enable Karpenter support (adds karpenter.sh/controller label to nodes)
  enable_karpenter = true

  # Managed Node Groups (Initial capacity for Karpenter and system pods)
  managed_node_groups = {
    # System node group for Karpenter controller and critical system pods
    karpenter = {
      desired_size   = 2
      min_size       = 2
      max_size       = 3
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      # Labels for system components
      labels = {
        role     = "karpenter"
        workload = "system"
      }

      # Taint to keep only Karpenter and system pods on these nodes
      taints = [{
        key    = "CriticalAddonsOnly"
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

      # Ensure Karpenter nodes are in specific subnets if needed
      # subnet_ids = var.karpenter_node_subnet_ids
    }
  }

  # EKS Addons
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          # Enable prefix delegation for more IPs per node
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }

    coredns = {
      before_compute = false
      most_recent    = true
      # Run CoreDNS on system nodes
      configuration_values = jsonencode({
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
        nodeSelector = {
          role = "karpenter"
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
# Karpenter IAM Resources
################################################################################

# IAM Role for Karpenter Controller (IRSA)
data "aws_iam_policy_document" "karpenter_controller_assume_role" {
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
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  name               = "${var.account_name}-${var.project_name}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-${var.project_name}-karpenter-controller"
    }
  )
}

# Karpenter Controller IAM Policy
resource "aws_iam_policy" "karpenter_controller" {
  name        = "${var.account_name}-${var.project_name}-karpenter-controller"
  description = "IAM policy for Karpenter controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
          "ec2:DeleteLaunchTemplate",
          "ec2:RunInstances",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = module.eks.node_iam_role_arn
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = module.eks.cluster_arn
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetInstanceProfile"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/aws/service/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

################################################################################
# Karpenter Spot Interruption Handling
################################################################################

# SQS Queue for Spot interruption notifications
resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "${var.account_name}-${var.project_name}-karpenter-interruption"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true

  tags = var.tags
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}

# EventBridge rules for interruption notifications
resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "${var.account_name}-${var.project_name}-spot-interruption"
  description = "Spot instance interruption warning"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "spot_interruption" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "instance_state_change" {
  name        = "${var.account_name}-${var.project_name}-instance-state-change"
  description = "EC2 instance state change"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "instance_state_change" {
  rule      = aws_cloudwatch_event_rule.instance_state_change.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "scheduled_change" {
  name        = "${var.account_name}-${var.project_name}-scheduled-change"
  description = "Scheduled instance changes"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "scheduled_change" {
  rule      = aws_cloudwatch_event_rule.scheduled_change.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

################################################################################
# EBS CSI Driver IAM Role (IRSA)
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
