variable "account_name" {
  description = "Account name for resource naming"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "myapp"
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

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster control plane (must be in at least two different availability zones)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Fargate profiles (must be private subnets)"
  type        = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "devops_team_role_arn" {
  description = "ARN of IAM role for DevOps team (admin access)"
  type        = string
  default     = ""
}

variable "developer_team_role_arn" {
  description = "ARN of IAM role for Developer team (read-only access)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Example     = "complete"
  }
}
