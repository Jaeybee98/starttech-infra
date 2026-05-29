variable "project_name" {
  type        = string
  default     = "starttech"
  description = "Project name prefix for resources"
}

variable "domain_name" {
  type        = string
  default     = "starttech-frontend-app-jaeybee98" # Needs to be globally unique for S3
  description = "Name used for the S3 bucket and identification"
}
