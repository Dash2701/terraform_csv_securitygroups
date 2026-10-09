variable "aws_region" {
  description = "AWS region in which to manage security groups."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional shared-credentials profile. Leave null for environment or workload credentials."
  type        = string
  default     = null
  nullable    = true
}

variable "vpc_id" {
  description = "ID of the existing VPC in which to create security groups."
  type        = string
}

variable "node_group_cidr" {
  description = "CIDR substituted into the default security-group rule template."
  type        = string
  default     = "10.102.0.0/24"
}

variable "rules_csv_content" {
  description = "Optional CSV rule content. When null, securitygrouprules.tpl is rendered."
  type        = string
  default     = null
  nullable    = true
}

variable "security_group_tags" {
  description = "Tags applied to every security group."
  type        = map(string)
  default     = {}
}
