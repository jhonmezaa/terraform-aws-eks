variable "create" {
  description = "Create KMS key resources"
  type        = bool
  default     = true
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = "EKS cluster encryption key"
}

variable "deletion_window_in_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days"
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Create a multi-region KMS key"
  type        = bool
  default     = false
}

variable "policy" {
  description = "KMS key policy JSON"
  type        = string
  default     = null
}

variable "create_alias" {
  description = "Create KMS key alias"
  type        = bool
  default     = true
}

variable "alias_name" {
  description = "KMS key alias name (must start with 'alias/')"
  type        = string
  default     = null

  validation {
    condition     = var.alias_name == null || can(regex("^alias/", var.alias_name))
    error_message = "Alias name must start with 'alias/'"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_tags" {
  description = "Additional tags for KMS key"
  type        = map(string)
  default     = {}
}
