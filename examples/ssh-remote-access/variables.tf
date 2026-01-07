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

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "ec2_key_pair_name" {
  description = "EC2 key pair name for SSH access to nodes"
  type        = string
}

variable "ssh_source_security_groups" {
  description = "Security group IDs allowed to SSH into nodes"
  type        = list(string)
  default     = []
}

variable "enable_public_ip" {
  description = "Enable public IP on nodes (use for dev/testing only)"
  type        = bool
  default     = false
}

variable "create_ssh_security_group" {
  description = "Create additional security group for SSH access"
  type        = bool
  default     = false
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}
