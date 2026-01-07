################################################################################
# General
################################################################################

variable "create" {
  description = "Create EKS cluster and all related resources"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "region_prefix" {
  description = "Region prefix for resource naming (e.g., ause1 for us-east-1)"
  type        = string
  default     = null
}

variable "account_name" {
  description = "Account name for resource naming"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

################################################################################
# Cluster
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster (overrides auto-generated name)"
  type        = string
  default     = null
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (must be in at least two different availability zones)"
  type        = list(string)
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_additional_security_group_ids" {
  description = "Additional security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

variable "cluster_tags" {
  description = "Additional tags for the cluster"
  type        = map(string)
  default     = {}
}

variable "cluster_timeouts" {
  description = "Timeouts for cluster operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "cluster_ip_family" {
  description = "IP family for the cluster (ipv4 or ipv6)"
  type        = string
  default     = null

  validation {
    condition     = var.cluster_ip_family == null ? true : contains(["ipv4", "ipv6"], var.cluster_ip_family)
    error_message = "Cluster IP family must be either ipv4 or ipv6"
  }
}

variable "cluster_service_ipv4_cidr" {
  description = "CIDR block for Kubernetes services (IPv4)"
  type        = string
  default     = null
}

variable "cluster_service_ipv6_cidr" {
  description = "CIDR block for Kubernetes services (IPv6)"
  type        = string
  default     = null
}

variable "outpost_config" {
  description = "Configuration for EKS on Outposts"
  type        = any
  default     = null
}

variable "cluster_upgrade_policy" {
  description = "Cluster upgrade policy configuration"
  type = object({
    support_type = optional(string)
  })
  default = null
}

variable "cluster_access_config" {
  description = "Cluster access configuration"
  type = object({
    authentication_mode                         = optional(string)
    bootstrap_cluster_creator_admin_permissions = optional(bool)
  })
  default = null
}

variable "bootstrap_self_managed_addons" {
  description = "Bootstrap self-managed addons"
  type        = bool
  default     = true
}

################################################################################
# EKS Auto Mode
################################################################################

variable "enable_auto_mode" {
  description = "Enable EKS Auto Mode for fully managed compute infrastructure"
  type        = bool
  default     = false
}

variable "auto_mode_node_pools" {
  description = "List of node pools for EKS Auto Mode (e.g., ['general-purpose'])"
  type        = list(string)
  default     = ["general-purpose"]
}

variable "auto_mode_node_role_arn" {
  description = "IAM role ARN for Auto Mode nodes (uses shared node role if not specified)"
  type        = string
  default     = null
}

################################################################################
# Cluster IAM Role
################################################################################

variable "create_cluster_iam_role" {
  description = "Create IAM role for the cluster"
  type        = bool
  default     = true
}

variable "cluster_iam_role_arn" {
  description = "Existing IAM role ARN for the cluster (if not creating)"
  type        = string
  default     = null
}

variable "cluster_iam_role_name" {
  description = "Name for the cluster IAM role"
  type        = string
  default     = null
}

variable "cluster_iam_role_use_name_prefix" {
  description = "Use name prefix for cluster IAM role"
  type        = bool
  default     = true
}

variable "cluster_iam_role_path" {
  description = "IAM path for the cluster role"
  type        = string
  default     = null
}

variable "cluster_iam_role_description" {
  description = "Description for the cluster IAM role"
  type        = string
  default     = "EKS cluster IAM role"
}

variable "cluster_iam_role_permissions_boundary" {
  description = "Permissions boundary ARN for the cluster IAM role"
  type        = string
  default     = null
}

variable "cluster_iam_role_policies" {
  description = "IAM policies to attach to the cluster role"
  type        = map(string)
  default = {
    AmazonEKSClusterPolicy = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  }
}

variable "cluster_iam_role_additional_policies" {
  description = "Additional IAM policies to attach to the cluster role"
  type        = map(string)
  default     = {}
}

variable "cluster_iam_role_tags" {
  description = "Additional tags for the cluster IAM role"
  type        = map(string)
  default     = {}
}

################################################################################
# Security Groups
################################################################################

variable "create_cluster_security_group" {
  description = "Create security group for the EKS cluster"
  type        = bool
  default     = true
}

variable "cluster_security_group_id" {
  description = "Existing cluster security group ID (if not creating)"
  type        = string
  default     = null
}

variable "cluster_security_group_name" {
  description = "Name for the cluster security group"
  type        = string
  default     = null
}

variable "cluster_security_group_use_name_prefix" {
  description = "Use name prefix for cluster security group"
  type        = bool
  default     = true
}

variable "cluster_security_group_description" {
  description = "Description for the cluster security group"
  type        = string
  default     = "EKS cluster security group"
}

variable "cluster_security_group_tags" {
  description = "Additional tags for the cluster security group"
  type        = map(string)
  default     = {}
}

variable "cluster_security_group_additional_rules" {
  description = "Additional security group rules for the cluster"
  type        = any
  default     = {}
}

variable "create_node_security_group" {
  description = "Create security group for EKS nodes"
  type        = bool
  default     = true
}

variable "node_security_group_id" {
  description = "Existing node security group ID (if not creating)"
  type        = string
  default     = null
}

variable "node_security_group_name" {
  description = "Name for the node security group"
  type        = string
  default     = null
}

variable "node_security_group_use_name_prefix" {
  description = "Use name prefix for node security group"
  type        = bool
  default     = true
}

variable "node_security_group_description" {
  description = "Description for the node security group"
  type        = string
  default     = "EKS node security group"
}

variable "node_security_group_tags" {
  description = "Additional tags for the node security group"
  type        = map(string)
  default     = {}
}

variable "node_security_group_additional_rules" {
  description = "Additional security group rules for nodes"
  type        = any
  default     = {}
}

variable "node_additional_security_group_ids" {
  description = "Additional security group IDs to attach to nodes"
  type        = list(string)
  default     = []
}

################################################################################
# CloudWatch Logging
################################################################################

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable. Valid values: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for log_type in var.enabled_cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Invalid log type. Valid values are: api, audit, authenticator, controllerManager, scheduler"
  }
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain cluster logs"
  type        = number
  default     = 90
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID to encrypt CloudWatch logs"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_class" {
  description = "Log class for CloudWatch log group (STANDARD or INFREQUENT_ACCESS)"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.cloudwatch_log_group_class)
    error_message = "Log class must be either STANDARD or INFREQUENT_ACCESS"
  }
}

variable "cloudwatch_log_group_tags" {
  description = "Additional tags for CloudWatch log group"
  type        = map(string)
  default     = {}
}

################################################################################
# KMS Encryption
################################################################################

variable "create_kms_key" {
  description = "Create KMS key for cluster encryption"
  type        = bool
  default     = false
}

variable "kms_key_description" {
  description = "Description for the KMS key"
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "KMS key deletion window in days (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days"
  }
}

variable "kms_key_enable_key_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

variable "kms_key_multi_region" {
  description = "Create a multi-region KMS key"
  type        = bool
  default     = false
}

variable "kms_key_tags" {
  description = "Additional tags for KMS key"
  type        = map(string)
  default     = {}
}

variable "kms_key_enable_default_policy" {
  description = "Enable default KMS key policy"
  type        = bool
  default     = true
}

variable "kms_key_additional_policy_statements" {
  description = "Additional policy statements for KMS key"
  type        = list(any)
  default     = []
}

variable "cluster_encryption_config_resources" {
  description = "List of resources to encrypt (secrets)"
  type        = list(string)
  default     = ["secrets"]
}

variable "cluster_encryption_config_kms_key_arn" {
  description = "Existing KMS key ARN for cluster encryption (if not creating new key)"
  type        = string
  default     = null
}

################################################################################
# Access Entries (Modern IAM)
################################################################################

variable "access_entries" {
  description = "Map of access entries to create"
  type = map(object({
    principal_arn     = string
    type              = optional(string, "STANDARD")
    kubernetes_groups = optional(list(string))
    user_name         = optional(string)
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string))
      })
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Create access entry for cluster creator with admin permissions. Only creates if cluster_access_config.bootstrap_cluster_creator_admin_permissions is false (when true, AWS creates it automatically)"
  type        = bool
  default     = true
}

################################################################################
# IRSA (IAM Roles for Service Accounts)
################################################################################

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA) by creating OIDC provider"
  type        = bool
  default     = true
}

variable "openid_connect_audiences" {
  description = "Additional audiences for the OIDC provider"
  type        = list(string)
  default     = []
}

variable "custom_oidc_thumbprints" {
  description = "Custom OIDC thumbprints"
  type        = list(string)
  default     = []
}

variable "oidc_provider_tags" {
  description = "Additional tags for OIDC provider"
  type        = map(string)
  default     = {}
}

################################################################################
# Shared Node IAM Role
################################################################################

variable "create_node_iam_role" {
  description = "Create shared IAM role for all node groups"
  type        = bool
  default     = true
}

variable "node_iam_role_arn" {
  description = "Existing IAM role ARN for nodes (if not creating)"
  type        = string
  default     = null
}

variable "node_iam_role_name" {
  description = "Name for the node IAM role"
  type        = string
  default     = null
}

variable "node_iam_role_use_name_prefix" {
  description = "Use name prefix for node IAM role"
  type        = bool
  default     = true
}

variable "node_iam_role_path" {
  description = "IAM path for the node role"
  type        = string
  default     = null
}

variable "node_iam_role_description" {
  description = "Description for the node IAM role"
  type        = string
  default     = "EKS node IAM role"
}

variable "node_iam_role_permissions_boundary" {
  description = "Permissions boundary ARN for the node IAM role"
  type        = string
  default     = null
}

variable "node_iam_policies" {
  description = "IAM policies to attach to node role"
  type        = map(string)
  default = {
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

variable "node_iam_additional_policies" {
  description = "Additional IAM policies to attach to node role"
  type        = map(string)
  default     = {}
}

variable "node_iam_role_tags" {
  description = "Additional tags for node IAM role"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Tags to apply to node resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Managed Node Groups
################################################################################

variable "managed_node_groups" {
  description = "Map of managed node group configurations"
  type        = any
  default     = {}
}

################################################################################
# Self-Managed Node Groups
################################################################################

variable "self_managed_node_groups" {
  description = "Map of self-managed node group configurations"
  type        = any
  default     = {}
}

################################################################################
# Fargate Profiles
################################################################################

variable "fargate_profiles" {
  description = "Map of Fargate profile configurations"
  type        = any
  default     = {}
}

################################################################################
# EKS Managed Addons
################################################################################

variable "cluster_addons" {
  description = "Map of cluster addon configurations"
  type = map(object({
    addon_name                  = optional(string)
    before_compute              = optional(bool, false)
    most_recent                 = optional(bool, true)
    addon_version               = optional(string)
    configuration_values        = optional(string)
    preserve                    = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    tags = optional(map(string), {})
  }))
  default = null
}

variable "cluster_addons_timeouts" {
  description = "Default timeouts for cluster addons"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}

################################################################################
# Karpenter
################################################################################

variable "enable_karpenter" {
  description = "Enable Karpenter support (adds karpenter.sh/controller label to nodes)"
  type        = bool
  default     = false
}

################################################################################
# AMI
################################################################################

variable "ami_type" {
  description = "Default AMI type for data source lookups"
  type        = string
  default     = "amazon-linux-2023/x86_64/standard"
}
