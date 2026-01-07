output "cluster_name" {
  value = module.eks.cluster_name
}

output "kms_key_id" {
  value = aws_kms_key.eks_multi_region.id
}

output "kms_key_arn" {
  value = aws_kms_key.eks_multi_region.arn
}

output "kms_key_alias" {
  value = aws_kms_alias.eks_multi_region.name
}

output "is_multi_region" {
  value = aws_kms_key.eks_multi_region.multi_region
}
