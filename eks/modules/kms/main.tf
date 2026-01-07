resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region
  policy                  = var.policy

  tags = merge(
    var.tags,
    var.kms_key_tags
  )
}

resource "aws_kms_alias" "this" {
  count = var.create_alias ? 1 : 0

  name          = var.alias_name
  target_key_id = aws_kms_key.this.key_id
}
