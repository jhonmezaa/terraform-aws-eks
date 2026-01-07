resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name_prefix = "${var.autoscaling_group_name}-node-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  permissions_boundary = var.iam_role_permissions_boundary

  tags = merge(
    var.tags,
    { Name = "${var.autoscaling_group_name}-node" }
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.create_iam_role ? var.iam_role_policies : {}

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? var.iam_role_additional_policies : {}

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.autoscaling_group_name}-"
  role        = var.create_iam_role ? aws_iam_role.this[0].name : var.iam_role_name

  tags = merge(
    var.tags,
    { Name = "${var.autoscaling_group_name}-instance-profile" }
  )

  lifecycle {
    create_before_destroy = true
  }
}
