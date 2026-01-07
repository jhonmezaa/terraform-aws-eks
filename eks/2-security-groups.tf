################################################################################
# Cluster Security Group
################################################################################

resource "aws_security_group" "cluster" {
  count = var.create && var.create_cluster_security_group ? 1 : 0

  name        = var.cluster_security_group_name != null ? var.cluster_security_group_name : "${local.cluster_name}-cluster"
  name_prefix = var.cluster_security_group_name == null && var.cluster_security_group_use_name_prefix ? "${local.cluster_name}-cluster-" : null
  description = var.cluster_security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    var.cluster_security_group_tags,
    { Name = "${local.cluster_name}-cluster" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cluster_ingress_node_443" {
  count = var.create && var.create_cluster_security_group && var.create_node_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node[0].id
  security_group_id        = aws_security_group.cluster[0].id
  description              = "Node to cluster API communication"
}

resource "aws_security_group_rule" "cluster_egress_all" {
  count = var.create && var.create_cluster_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster[0].id
  description       = "Allow all egress"
}

resource "aws_security_group_rule" "cluster_additional" {
  for_each = var.create && var.create_cluster_security_group ? var.cluster_security_group_additional_rules : {}

  security_group_id        = aws_security_group.cluster[0].id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
  description              = lookup(each.value, "description", null)
}

################################################################################
# Node Security Group
################################################################################

resource "aws_security_group" "node" {
  count = var.create && var.create_node_security_group ? 1 : 0

  name        = var.node_security_group_name != null ? var.node_security_group_name : "${local.cluster_name}-node"
  name_prefix = var.node_security_group_name == null && var.node_security_group_use_name_prefix ? "${local.cluster_name}-node-" : null
  description = var.node_security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    var.node_security_group_tags,
    {
      Name                                          = "${local.cluster_name}-node"
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "node_ingress_self" {
  count = var.create && var.create_node_security_group ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.node[0].id
  description       = "Node to node all traffic"
}

resource "aws_security_group_rule" "node_ingress_cluster_443" {
  count = var.create && var.create_cluster_security_group && var.create_node_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster[0].id
  security_group_id        = aws_security_group.node[0].id
  description              = "Cluster API to node communication (443)"
}

resource "aws_security_group_rule" "node_ingress_cluster_kubelet" {
  count = var.create && var.create_cluster_security_group && var.create_node_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster[0].id
  security_group_id        = aws_security_group.node[0].id
  description              = "Cluster API to node kubelet communication"
}

resource "aws_security_group_rule" "node_ingress_cluster_primary" {
  count = var.create && var.create_cluster_security_group && var.create_node_security_group ? 1 : 0

  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = try(aws_eks_cluster.this[0].vpc_config[0].cluster_security_group_id, "")
  security_group_id        = aws_security_group.node[0].id
  description              = "Cluster primary security group to node all traffic"
}

resource "aws_security_group_rule" "node_egress_all" {
  count = var.create && var.create_node_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node[0].id
  description       = "Allow all egress"
}

resource "aws_security_group_rule" "node_additional" {
  for_each = var.create && var.create_node_security_group ? var.node_security_group_additional_rules : {}

  security_group_id        = aws_security_group.node[0].id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
  description              = lookup(each.value, "description", null)
}
