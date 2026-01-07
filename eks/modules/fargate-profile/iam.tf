resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name_prefix = "${var.fargate_profile_name}-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  permissions_boundary = var.iam_role_permissions_boundary

  tags = merge(
    var.tags,
    { Name = "${var.fargate_profile_name}-fargate" }
  )
}

resource "aws_iam_role_policy_attachment" "pod_execution" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? var.iam_role_additional_policies : {}

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}
