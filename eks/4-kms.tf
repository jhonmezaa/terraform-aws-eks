################################################################################
# KMS Key for Cluster Encryption
################################################################################

resource "aws_kms_key" "this" {
  count = var.create && var.create_kms_key ? 1 : 0

  description             = var.kms_key_description != null ? var.kms_key_description : "EKS cluster ${local.cluster_name} encryption key"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation
  multi_region            = var.kms_key_multi_region

  tags = merge(
    local.tags,
    var.kms_key_tags,
    { Name = "${local.cluster_name}-eks" }
  )
}

resource "aws_kms_alias" "this" {
  count = var.create && var.create_kms_key ? 1 : 0

  name          = "alias/${local.cluster_name}-eks"
  target_key_id = aws_kms_key.this[0].key_id
}

# Policy to allow EKS cluster role and CloudWatch Logs to use the key
resource "aws_kms_key_policy" "this" {
  count = var.create && var.create_kms_key && var.kms_key_enable_default_policy ? 1 : 0

  key_id = aws_kms_key.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "Enable IAM User Permissions"
          Effect = "Allow"
          Principal = {
            AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
          }
          Action   = "kms:*"
          Resource = "*"
        },
        {
          Sid    = "Allow EKS cluster to use the key"
          Effect = "Allow"
          Principal = {
            Service = "eks.${local.dns_suffix}"
          }
          Action = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:CreateGrant"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "kms:ViaService" = [
                "eks.${data.aws_region.current.id}.${local.dns_suffix}"
              ]
            }
          }
        }
      ],
      length(var.enabled_cluster_log_types) > 0 ? [
        {
          Sid    = "Allow CloudWatch Logs to use the key"
          Effect = "Allow"
          Principal = {
            Service = "logs.${data.aws_region.current.id}.${local.dns_suffix}"
          }
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey",
            "kms:CreateGrant",
            "kms:DescribeKey"
          ]
          Resource = "*"
          Condition = {
            ArnLike = {
              "kms:EncryptionContext:aws:logs:arn" = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${local.cloudwatch_log_group_name}"
            }
          }
        }
      ] : [],
      var.kms_key_additional_policy_statements
    )
  })
}
