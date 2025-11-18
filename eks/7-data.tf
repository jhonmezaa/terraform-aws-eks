# Get current AWS region
data "aws_region" "current" {}

# Get recommended AMI release version for EKS nodes
# This ensures nodes use the latest compatible AMI for the specified EKS version
data "aws_ssm_parameter" "eks_version" {
  name = "/aws/service/eks/optimized-ami/${var.eks_version}/${var.ami_type}/recommended/release_version"
}

# Get addon versions - creates data source for all addons to query compatible versions
# Uses most_recent flag from each addon configuration (defaults to true)
data "aws_eks_addon_version" "this" {
  for_each = var.cluster_addons != null ? var.cluster_addons : {}

  addon_name         = coalesce(each.value.addon_name, each.key)
  kubernetes_version = var.eks_version
  most_recent        = try(each.value.most_recent, true)
}
