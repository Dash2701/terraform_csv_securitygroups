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

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC created by this module."
  type        = string
  default     = "172.168.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
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

  validation {
    condition = var.rules_csv_content == null ? true : (
      can(csvdecode(var.rules_csv_content)) &&
      try(
        length(csvdecode(var.rules_csv_content)) > 0 &&
        alltrue([
          for rule in csvdecode(var.rules_csv_content) :
          length(setsubtract(
            toset(["id", "type", "name", "cidr_block", "protocol", "from_port", "to_port", "description"]),
            toset(keys(rule))
          )) == 0 &&
          trimspace(rule.id) != "" &&
          trimspace(rule.name) != "" &&
          contains(["ingress", "egress"], lower(trimspace(rule.type))) &&
          tonumber(rule.from_port) >= 0 &&
          tonumber(rule.from_port) <= 65535 &&
          tonumber(rule.to_port) >= 0 &&
          tonumber(rule.to_port) <= 65535 &&
          tonumber(rule.from_port) <= tonumber(rule.to_port) &&
          length([for cidr in split(",", rule.cidr_block) : cidr if trimspace(cidr) != ""]) > 0 &&
          alltrue([
            for cidr in split(",", rule.cidr_block) :
            can(cidrhost(trimspace(cidr), 0))
          ])
        ]) &&
        length(distinct([
          for rule in csvdecode(var.rules_csv_content) : trimspace(rule.id)
        ])) == length(csvdecode(var.rules_csv_content)),
        false
      )
    )
    error_message = "rules_csv_content must be valid CSV with the documented columns, unique non-empty IDs and names, ingress or egress types, valid ordered ports from 0 through 65535, and valid comma-separated CIDRs."
  }
}

variable "security_group_tags" {
  description = "Tags applied to every security group."
  type        = map(string)
  default     = {}
}
