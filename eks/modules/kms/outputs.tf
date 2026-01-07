output "kms_key_id" {
  description = "KMS key ID"
  value       = try(aws_kms_key.this.id, null)
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = try(aws_kms_key.this.arn, null)
}

output "kms_key_key_id" {
  description = "KMS key key_id"
  value       = try(aws_kms_key.this.key_id, null)
}

output "kms_alias_name" {
  description = "KMS alias name"
  value       = try(aws_kms_alias.this[0].name, null)
}

output "kms_alias_arn" {
  description = "KMS alias ARN"
  value       = try(aws_kms_alias.this[0].arn, null)
}
