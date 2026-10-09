variable "aws_region" {
  description = "AWS region containing the test VPC."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional shared-credentials profile."
  type        = string
  default     = null
  nullable    = true
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC created by the example."
  type        = string
  default     = "172.16.0.0/16"
}
