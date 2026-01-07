variable "create" {
  description = "Create node group resources"
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

variable "node_group_name" {
  description = "Name of the node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for node group"
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of unavailable nodes during update"
  type        = number
  default     = 33
}

variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT"
  }
}

variable "instance_types" {
  description = "List of instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2_x86_64"

  validation {
    condition = contains([
      "AL2_x86_64",
      "AL2_x86_64_GPU",
      "AL2_ARM_64",
      "CUSTOM",
      "BOTTLEROCKET_ARM_64",
      "BOTTLEROCKET_x86_64",
      "AL2023_x86_64_STANDARD",
      "AL2023_ARM_64_STANDARD"
    ], var.ami_type)
    error_message = "Invalid AMI type. Must be one of: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64, AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD"
  }
}

variable "ami_release_version" {
  description = "AMI release version"
  type        = string
  default     = null
}

variable "labels" {
  description = "Kubernetes labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "cluster_labels" {
  description = "Cluster-wide labels (e.g., karpenter)"
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []

  validation {
    condition = alltrue([
      for taint in var.taints : contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], taint.effect)
    ])
    error_message = "Taint effect must be one of: NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE"
  }
}

variable "enable_remote_access" {
  description = "Enable SSH remote access"
  type        = bool
  default     = false
}

variable "remote_access_ec2_ssh_key" {
  description = "EC2 SSH key name"
  type        = string
  default     = null
}

variable "remote_access_source_security_group_ids" {
  description = "Source security group IDs for SSH"
  type        = list(string)
  default     = []
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

variable "security_group_ids" {
  description = "Security group IDs for nodes"
  type        = list(string)
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

variable "launch_template_use_latest_version" {
  description = "Use $Latest version of launch template"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Create IAM role for nodes"
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "Existing IAM role ARN (if not creating)"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "node_group_tags" {
  description = "Additional tags for node group"
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
