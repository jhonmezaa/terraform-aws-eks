################################################################################
# OIDC Provider (IRSA - IAM Roles for Service Accounts)
################################################################################

resource "aws_iam_openid_connect_provider" "this" {
  count = var.create && var.enable_irsa ? 1 : 0

  client_id_list  = distinct(compact(concat(["sts.${local.dns_suffix}"], var.openid_connect_audiences)))
  thumbprint_list = concat([data.tls_certificate.this[0].certificates[0].sha1_fingerprint], var.custom_oidc_thumbprints)
  url             = aws_eks_cluster.this[0].identity[0].oidc[0].issuer

  tags = merge(
    local.tags,
    var.oidc_provider_tags,
    { Name = local.cluster_name }
  )
}
