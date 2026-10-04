variable "name" { type = string }

variable "transition_to_ia_days" {
  type        = number
  default     = 90
  description = "Days before the prefix moves to STANDARD_IA. 0 disables the rule."
}

variable "transition_prefix" {
  type    = string
  default = "bronze/"
}

variable "tags" {
  type    = map(string)
  default = {}
}
