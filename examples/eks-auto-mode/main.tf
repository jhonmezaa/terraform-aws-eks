################################################################################
# EKS Auto Mode Example
################################################################################

module "eks" {
  source = "../../eks"

  # General Configuration
  account_name = var.account_name
  project_name = var.project_name

  # Cluster Configuration
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  # Endpoint Access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  # EKS Auto Mode Configuration
  enable_auto_mode     = true
  auto_mode_node_pools = ["general-purpose"]

  # Enable IRSA
  enable_irsa = true

  # Modern IAM with Access Entries
  cluster_access_config = {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # CloudWatch Log Group Configuration
  cloudwatch_log_group_retention_in_days = 90
  cloudwatch_log_group_class             = "STANDARD"

  # KMS Encryption (optional)
  create_kms_key = var.create_kms_key

  # Security Groups - Auto-created
  create_cluster_security_group = true
  create_node_security_group    = true

  # Tags
  tags = var.tags
}
