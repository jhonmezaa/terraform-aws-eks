data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# TLS certificate for OIDC provider
data "tls_certificate" "this" {
  count = var.create && var.enable_irsa ? 1 : 0

  url = aws_eks_cluster.this[0].identity[0].oidc[0].issuer
}

# Latest EKS optimized AMI
data "aws_ssm_parameter" "eks_ami_release_version" {
  count = var.create ? 1 : 0

  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/${var.ami_type}/recommended/release_version"
}

# EKS addon versions
data "aws_eks_addon_version" "this" {
  for_each = var.create && var.cluster_addons != null ? var.cluster_addons : {}

  addon_name         = try(each.value.addon_name, each.key)
  kubernetes_version = var.cluster_version
  most_recent        = try(each.value.most_recent, true)
}
