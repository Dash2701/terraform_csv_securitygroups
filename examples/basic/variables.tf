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

variable "vpc_id" {
  description = "ID of an existing VPC used for the example."
  type        = string
}
