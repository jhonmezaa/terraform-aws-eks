variable "eks_version" {
  description = "Desired Kubernetes master version."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet ids. Must be in at least two different availability zones."
  type        = list(string)
}

variable "node_iam_policies" {
  description = "List of IAM Policies to attach to EKS-managed nodes."
  type        = map(any)
  default = {
    1 = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    2 = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    3 = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    4 = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

variable "node_groups" {
  description = "EKS node groups."
  type        = map(any)
}

variable "enable_irsa" {
  description = "Determines wheter to create an OpenID Connect Provider for EKS."
  type        = bool
  default     = true
}

variable "tags_common" {
  description = "Tags"
  type        = map(any)
}

variable "account_name" {
  description = "Account name."
  type        = string
}

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "ami_type" {
  description = "AMI type."
  type        = string
  default     = "amazon-linux-2023/arm64/standard"
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `addon_name`."
  type = map(object({
    addon_name                  = optional(string)
    before_compute              = optional(bool, false)
    most_recent                 = optional(bool, true)
    addon_version               = optional(string)
    configuration_values        = optional(string)
    preserve                    = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    tags = optional(map(string), {})
  }))
  default = null
}

variable "cluster_addons_timeouts" {
  description = "Default timeouts for cluster addons."
  type = object({
    create = optional(string, null)
    update = optional(string, null)
    delete = optional(string, null)
  })
  default = {}
}
