################################################################################
# EKS Cluster - Fargate Only Example
#
# This example demonstrates a serverless EKS cluster using only Fargate profiles.
# No EC2 nodes are deployed - all pods run on AWS Fargate.
################################################################################

module "eks" {
  source = "../../eks"

  # General
  account_name = var.account_name
  project_name = var.project_name

  # Cluster Configuration
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids # Fargate requires private subnets

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # No managed node groups
  managed_node_groups = {}

  # Fargate Profiles
  fargate_profiles = {
    # Default profile for kube-system namespace
    kube_system = {
      selectors = [{
        namespace = "kube-system"
      }]

      subnet_ids = var.private_subnet_ids
    }

    # Default profile for default namespace
    default = {
      selectors = [{
        namespace = "default"
      }]

      subnet_ids = var.private_subnet_ids
    }

    # Application workloads
    applications = {
      selectors = [
        {
          namespace = "production"
        },
        {
          namespace = "staging"
        },
        {
          namespace = "development"
        }
      ]

      subnet_ids = var.private_subnet_ids
    }

    # Monitoring and observability
    monitoring = {
      selectors = [{
        namespace = "monitoring"
      }]

      subnet_ids = var.private_subnet_ids
    }

    # CI/CD workloads
    cicd = {
      selectors = [{
        namespace = "cicd"
        labels = {
          compute = "fargate"
        }
      }]

      subnet_ids = var.private_subnet_ids
    }
  }

  # EKS Addons
  # Note: CoreDNS needs special configuration for Fargate-only clusters
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          # Fargate-specific VPC-CNI configuration
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
      # CoreDNS configuration for Fargate
      configuration_values = jsonencode({
        computeType = "Fargate"
        resources = {
          limits = {
            cpu    = "0.25"
            memory = "256M"
          }
          requests = {
            cpu    = "0.25"
            memory = "256M"
          }
        }
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
# Patch CoreDNS for Fargate
# CoreDNS needs to be patched to remove EC2 compute type annotation
################################################################################

resource "null_resource" "patch_coredns_for_fargate" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${data.aws_region.current.name}

      # Remove the eks.amazonaws.com/compute-type annotation from CoreDNS
      kubectl patch deployment coredns \
        -n kube-system \
        --type json \
        -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]' \
        || true

      # Restart CoreDNS to run on Fargate
      kubectl rollout restart -n kube-system deployment coredns
    EOT
  }
}

data "aws_region" "current" {}
