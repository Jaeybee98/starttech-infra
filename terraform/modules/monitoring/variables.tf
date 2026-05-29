variable "project_name" {
  type    = string
  default = "starttech"
}

variable "log_retention_days" {
  type        = number
  default     = 7
  description = "Specifies the number of days to retain log events in the specified log group."
}
