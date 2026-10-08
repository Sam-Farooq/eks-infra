variable "name" { type = string }
variable "region" { type = string }
variable "cluster_name" { type = string }

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.cidr)) && tonumber(split("/", var.cidr)[1]) <= 20
    error_message = "cidr must be valid and no smaller than /20, or the per-AZ subnets will not fit."
  }
}

variable "az_count" {
  type    = number
  default = 3
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "Share one NAT across all AZs. Cheaper, and a single point of failure."
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "flow_log_retention_days" {
  type    = number
  default = 30
}
