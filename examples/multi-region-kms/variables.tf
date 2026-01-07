variable "account_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "kms_deletion_window" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
