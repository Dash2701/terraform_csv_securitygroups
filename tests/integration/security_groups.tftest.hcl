variables {
  rules_csv_content = <<-CSV
    id,type,name,cidr_block,protocol,from_port,to_port,description
    integration-https,ingress,terraform-csv-securitygroups-integration,10.255.255.255/32,tcp,443,443,Terraform integration test
  CSV
  security_group_tags = {
    environment = "integration-test"
    managed_by  = "terraform"
  }
}

run "applies_security_group_and_rule" {
  command = apply

  assert {
    condition     = output.security_group_ids["terraform-csv-securitygroups-integration"] != ""
    error_message = "Expected AWS to return a security-group ID."
  }

  assert {
    condition     = length(output.security_group_rules) == 1
    error_message = "Expected exactly one integration-test rule."
  }
}
