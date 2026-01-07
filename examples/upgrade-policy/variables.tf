################################################################################
# General
################################################################################

variable "account_name" {
  description = "Account name for resource naming"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Cluster Configuration
################################################################################

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

################################################################################
# Upgrade Policy Configuration
################################################################################

variable "upgrade_support_type" {
  description = <<-EOT
    Cluster upgrade support type:
    - STANDARD: Standard 14-month support lifecycle (default)
    - EXTENDED: Extended support for up to 26 months (additional cost applies)
  EOT
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.upgrade_support_type)
    error_message = "Support type must be either STANDARD or EXTENDED"
  }
}

variable "support_end_date" {
  description = "Estimated end date for current version support (for tracking purposes)"
  type        = string
  default     = ""
}
