variable "account_name" {
  description = "Account name for resource naming"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "secure-app"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (no public access)"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of private route table IDs for VPC endpoints"
  type        = list(string)
  default     = []
}

variable "create_vpc_endpoints" {
  description = "Create VPC endpoints for private cluster access to AWS services"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Example     = "private-cluster"
    Security    = "high"
  }
}
