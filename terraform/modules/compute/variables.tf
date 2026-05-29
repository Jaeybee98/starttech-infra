variable "project_name" {
  type        = string
  default     = "starttech"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID from the networking module"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the ASG EC2 instances"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}
