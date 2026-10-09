module "security_groups" {
  source = "../.."

  aws_region  = var.aws_region
  aws_profile = var.aws_profile
  vpc_cidr    = var.vpc_cidr

  rules_csv_content = <<-CSV
    id,type,name,cidr_block,protocol,from_port,to_port,description
    example-https,ingress,example-api,10.0.0.0/24,tcp,443,443,HTTPS from the application network
    example-egress,egress,example-api,10.0.0.0/8,tcp,443,443,HTTPS to private services
  CSV

  security_group_tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}

output "security_group_ids" {
  description = "Security group IDs created by the example."
  value       = module.security_groups.security_group_ids
}
