# Basic EKS Cluster with Managed Node Groups Example

module "eks" {
  source = "../../eks"

  # General
  account_name = var.account_name
  project_name = var.project_name

  # Cluster Configuration
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

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
    vpc-cni    = { most_recent = true }
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    # aws-ebs-csi-driver requires IRSA in K8s 1.34+, omitted for basic example
  }

  enable_cluster_creator_admin_permissions = true
  enabled_cluster_log_types                = ["api", "audit"]

  tags = var.tags_common
}
