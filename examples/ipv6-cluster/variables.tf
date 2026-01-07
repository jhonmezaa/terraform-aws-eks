variable "account_name" {
  description = "Account name for resource naming"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ipv6-app"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed (must have IPv6 CIDR block)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs with IPv6 CIDR blocks"
  type        = list(string)
}

variable "cluster_service_ipv6_cidr" {
  description = "IPv6 CIDR block for Kubernetes services (e.g., fd00::/108)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Example     = "ipv6-cluster"
    IPFamily    = "dual-stack"
  }
}
