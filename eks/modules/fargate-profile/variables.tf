variable "create" {
  description = "Create Fargate profile resources"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "fargate_profile_name" {
  description = "Name of the Fargate profile"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Fargate profile (must be private subnets)"
  type        = list(string)
}

variable "selectors" {
  description = "List of selectors for Fargate profile"
  type = list(object({
    namespace = string
    labels    = optional(map(string), {})
  }))

  validation {
    condition     = length(var.selectors) > 0
    error_message = "At least one selector must be provided"
  }
}

variable "create_iam_role" {
  description = "Create IAM role for Fargate pod execution"
  type        = bool
  default     = true
}

variable "pod_execution_role_arn" {
  description = "Existing pod execution role ARN"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "IAM role permissions boundary"
  type        = string
  default     = null
}

variable "iam_role_additional_policies" {
  description = "Additional IAM policies to attach"
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Timeouts for Fargate profile operations"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "fargate_profile_tags" {
  description = "Additional tags for Fargate profile"
  type        = map(string)
  default     = {}
}
