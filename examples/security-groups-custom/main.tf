################################################################################
# EKS Cluster - Custom Security Groups Example
#
# Demonstrates using custom security groups instead of module-generated ones.
# Useful for pre-existing security group requirements or strict network policies.
################################################################################

# Custom Cluster Security Group
resource "aws_security_group" "cluster" {
  name_prefix = "${var.account_name}-${var.project_name}-cluster-"
  description = "Custom security group for EKS cluster"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.account_name}-${var.project_name}-cluster-sg"
  })
}

# Custom Node Security Group
resource "aws_security_group" "node" {
  name_prefix = "${var.account_name}-${var.project_name}-node-"
  description = "Custom security group for EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Allow pods to communicate with cluster API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.account_name}-${var.project_name}-node-sg"
  })
}

# Cluster to Node Communication Rules
resource "aws_security_group_rule" "cluster_to_node" {
  description              = "Allow cluster to communicate with nodes"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "node_to_cluster" {
  description              = "Allow nodes to communicate with cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
}

# EKS Module with Custom Security Groups
module "eks" {
  source = "../../eks"

  account_name = var.account_name
  project_name = var.project_name

  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  # Disable auto-creation of security groups
  create_cluster_security_group = false
  create_node_security_group    = false

  # Use custom security groups
  cluster_additional_security_group_ids = [aws_security_group.cluster.id]
  node_additional_security_group_ids    = [aws_security_group.node.id]

  enable_irsa = true

  managed_node_groups = {
    general = {
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = ["t3.medium"]

      labels = {
        security-groups = "custom"
      }
    }
  }

  cluster_addons = {
    vpc-cni    = { before_compute = true, most_recent = true }
    coredns    = { before_compute = false, most_recent = true }
    kube-proxy = { before_compute = false, most_recent = true }
  }

  tags = var.tags
}
