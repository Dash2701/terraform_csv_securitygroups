#Create VPC 
resource "aws_vpc" "main_vpc" {
  cidr_block           = "172.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
