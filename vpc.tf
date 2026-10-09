resource "aws_vpc" "main_vpc" {
  #checkov:skip=CKV2_AWS_11: Flow-log destinations, retention, and IAM are deployment-specific.
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  lifecycle {
    ignore_changes = [tags["CreatorId"], tags["CreatorName"]]
  }
}

resource "aws_default_security_group" "main_vpc" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = var.security_group_tags

  lifecycle {
    ignore_changes = [tags["CreatorId"], tags["CreatorName"]]
  }
}
