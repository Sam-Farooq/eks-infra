variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "admin_cidrs" {
  type        = list(string)
  description = "Ranges allowed to reach the public Kubernetes API endpoint."
  default     = []
  validation {
    condition     = !contains(var.admin_cidrs, "0.0.0.0/0")
    error_message = "The Kubernetes API must not be open to the internet."
  }
}
