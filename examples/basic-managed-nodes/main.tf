# Basic EKS Cluster with Managed Node Groups Example

module "vpc" {
  source = "../../../terraform-aws-vpc/vpc"

  account_name   = var.account_name
  project_name   = var.project_name
  vpc_cidr_block = var.vpc_cidr_block
  azs            = var.azs

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags_common = var.tags_common
}

module "eks" {
  source = "../../eks"

  cluster_name    = "${var.account_name}-${var.project_name}"
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  managed_node_groups = {
    general = {
      name         = "general"
      desired_size = 2
      min_size     = 1
      max_size     = 4

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        role = "general"
      }
    }
  }

  cluster_addons = {
    vpc-cni            = { most_recent = true }
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }

  enable_cluster_creator_admin_permissions = true
  enabled_cluster_log_types                = ["api", "audit"]

  tags = var.tags_common
}
