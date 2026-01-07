variable "create" {
  description = "Create self-managed node group resources"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Name of the autoscaling group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for autoscaling group"
  type        = list(string)
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 5
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 3
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "default_cooldown" {
  description = "Default cooldown in seconds"
  type        = number
  default     = 300
}

variable "force_delete" {
  description = "Force delete autoscaling group"
  type        = bool
  default     = false
}

variable "termination_policies" {
  description = "List of termination policies"
  type        = list(string)
  default     = ["Default"]
}

variable "suspended_processes" {
  description = "List of suspended processes"
  type        = list(string)
  default     = []
}

variable "placement_group" {
  description = "Placement group name"
  type        = string
  default     = null
}

variable "enabled_metrics" {
  description = "List of enabled metrics"
  type        = list(string)
  default     = []
}

variable "metrics_granularity" {
  description = "Metrics granularity"
  type        = string
  default     = "1Minute"
}

variable "wait_for_capacity_timeout" {
  description = "Wait for capacity timeout"
  type        = string
  default     = "10m"
}

variable "service_linked_role_arn" {
  description = "Service linked role ARN"
  type        = string
  default     = null
}

variable "max_instance_lifetime" {
  description = "Maximum instance lifetime in seconds"
  type        = number
  default     = null
}

variable "instance_refresh" {
  description = "Instance refresh configuration"
  type = object({
    strategy = string
    preferences = optional(object({
      checkpoint_delay       = optional(number)
      checkpoint_percentages = optional(list(number))
      instance_warmup        = optional(number)
      min_healthy_percentage = optional(number)
      skip_matching          = optional(bool)
    }))
    triggers = optional(list(string))
  })
  default = null
}

variable "warm_pool" {
  description = "Warm pool configuration"
  type = object({
    pool_state                  = optional(string)
    min_size                    = optional(number)
    max_group_prepared_capacity = optional(number)
    instance_reuse_policy = optional(object({
      reuse_on_scale_in = optional(bool)
    }))
  })
  default = null
}

variable "launch_template_use_latest_version" {
  description = "Use $Latest version of launch template"
  type        = bool
  default     = true
}

variable "ami_id" {
  description = "AMI ID for instances (auto-detected if not provided)"
  type        = string
  default     = null
}

variable "ami_architecture" {
  description = "AMI architecture (x86_64 or arm64)"
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.ami_architecture)
    error_message = "AMI architecture must be either x86_64 or arm64"
  }
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Security group IDs for instances"
  type        = list(string)
}

variable "block_device_mappings" {
  description = "Block device mappings for launch template"
  type        = list(any)
  default = [{
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 100
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }]
}

variable "metadata_options_http_tokens" {
  description = "Metadata service HTTP tokens (optional or required)"
  type        = string
  default     = "required"

  validation {
    condition     = contains(["optional", "required"], var.metadata_options_http_tokens)
    error_message = "Metadata HTTP tokens must be either 'optional' or 'required'"
  }
}

variable "metadata_options_http_put_response_hop_limit" {
  description = "Metadata service hop limit"
  type        = number
  default     = 2
}

variable "enable_instance_metadata_tags" {
  description = "Enable instance metadata tags"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Associate public IP address"
  type        = bool
  default     = false
}

variable "pre_bootstrap_user_data" {
  description = "User data to run before bootstrap"
  type        = string
  default     = ""
}

variable "post_bootstrap_user_data" {
  description = "User data to run after bootstrap"
  type        = string
  default     = ""
}

variable "bootstrap_extra_args" {
  description = "Extra arguments for bootstrap script"
  type        = string
  default     = ""
}

variable "kubelet_extra_args" {
  description = "Extra arguments for kubelet"
  type        = string
  default     = ""
}

variable "create_iam_role" {
  description = "Create IAM role for instances"
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "Existing IAM role name (if not creating)"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "IAM role permissions boundary"
  type        = string
  default     = null
}

variable "iam_role_policies" {
  description = "IAM policies to attach to role"
  type        = map(string)
  default = {
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

variable "iam_role_additional_policies" {
  description = "Additional IAM policies to attach"
  type        = map(string)
  default     = {}
}

variable "credit_specification" {
  description = "Credit specification for T2/T3 instances"
  type = object({
    cpu_credits = string
  })
  default = null
}

variable "elastic_gpu_specifications" {
  description = "Elastic GPU specifications"
  type = object({
    type = string
  })
  default = null
}

variable "capacity_reservation_specification" {
  description = "Capacity reservation specification"
  type        = any
  default     = null
}

variable "enable_enclave" {
  description = "Enable Nitro Enclaves"
  type        = bool
  default     = false
}

variable "instance_market_options" {
  description = "Instance market options for Spot instances"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "autoscaling_group_tags" {
  description = "Additional tags for autoscaling group"
  type        = map(string)
  default     = {}
}

variable "instance_tags" {
  description = "Tags for EC2 instances"
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "Tags for EBS volumes"
  type        = map(string)
  default     = {}
}
