variable "cluster_name" { type = string }
variable "kubernetes_version" {
  type    = string
  default = "1.31"
}
variable "private_subnet_ids" { type = list(string) }

variable "public_access_cidrs" {
  type        = list(string)
  default     = []
  description = "Office and VPN ranges. Empty disables public API access entirely."
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
