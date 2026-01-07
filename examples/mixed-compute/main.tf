################################################################################
# EKS Cluster - Mixed Compute Example
#
# This example demonstrates a hybrid cluster using both managed node groups
# and Fargate profiles. This provides flexibility to run different workload
# types on the most appropriate compute platform.
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

  # Managed Node Groups (for stateful workloads, DaemonSets, etc.)
  managed_node_groups = {
    # System node group for DaemonSets and system pods
    system = {
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        workload = "system"
        compute  = "ec2"
      }

      # Taint to keep only system pods on these nodes
      taints = [{
        key    = "node-role"
        value  = "system"
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

    # Stateful workloads (databases, caches)
    stateful = {
      desired_size   = 2
      min_size       = 1
      max_size       = 6
      instance_types = ["r6i.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        workload = "stateful"
        compute  = "ec2"
      }

      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 200
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 125
          encrypted             = true
          delete_on_termination = true
        }
      }]
    }
  }

  # Fargate Profiles (for stateless workloads, batch jobs, etc.)
  fargate_profiles = {
    # Web applications (stateless)
    web = {
      selectors = [{
        namespace = "web"
        labels = {
          compute = "fargate"
        }
      }]

      subnet_ids = var.private_subnet_ids
    }

    # API services
    api = {
      selectors = [{
        namespace = "api"
      }]

      subnet_ids = var.private_subnet_ids
    }

    # Batch processing
    batch = {
      selectors = [{
        namespace = "batch"
      }]

      subnet_ids = var.private_subnet_ids
    }

    # Development environments
    development = {
      selectors = [
        {
          namespace = "dev"
        },
        {
          namespace = "test"
        }
      ]

      subnet_ids = var.private_subnet_ids
    }
  }

  # EKS Addons
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
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
      # Run CoreDNS on EC2 nodes (not Fargate)
      configuration_values = jsonencode({
        tolerations = [{
          key      = "node-role"
          operator = "Equal"
          value    = "system"
          effect   = "NoSchedule"
        }]
        nodeSelector = {
          workload = "system"
        }
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
