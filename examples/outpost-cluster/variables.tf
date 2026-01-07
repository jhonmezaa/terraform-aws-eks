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
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the Outpost is located"
  type        = string
}

################################################################################
# AWS Outpost Configuration
################################################################################

variable "outpost_arn" {
  description = "ARN of the AWS Outpost"
  type        = string
}

variable "outpost_subnet_ids" {
  description = "List of subnet IDs on the Outpost (must be in at least two AZs)"
  type        = list(string)
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for EKS control plane on Outpost (e.g., m5.xlarge, c5.2xlarge)"
  type        = string
  default     = "m5.xlarge"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes on Outpost"
  type        = string
  default     = "m5.large"
}

variable "edge_instance_type" {
  description = "EC2 instance type for edge computing nodes"
  type        = string
  default     = "c5.large"
}

variable "placement_group_name" {
  description = "Placement group name for control plane instances (optional)"
  type        = string
  default     = null
}
