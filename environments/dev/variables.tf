variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-training"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
