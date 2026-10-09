mock_provider "aws" {}

variables {
  vpc_id            = "vpc-00000000000000000"
  rules_csv_content = file("tests/fixtures/valid-rules.csv")
  security_group_tags = {
    environment = "test"
    managed_by  = "terraform"
  }
}

run "normalizes_security_group_names" {
  command = plan

  assert {
    condition     = toset(output.security_group_names) == toset(["api", "worker"])
    error_message = "Expected CSV group names to be deduplicated."
  }
}

run "normalizes_security_group_rules" {
  command = plan

  assert {
    condition     = length(output.security_group_rules) == 4
    error_message = "Expected one normalized rule per CSV row."
  }

  assert {
    condition     = { for rule in output.security_group_rules : rule.id => rule }["cidr-list"].cidr_blocks == ["10.0.0.0/24", "10.0.1.0/24", "2001:db8::/64"]
    error_message = "Expected comma-separated CIDRs to be trimmed in source order."
  }

  assert {
    condition     = toset(aws_security_group_rule.samplesg_ingress["cidr-list"].cidr_blocks) == toset(["10.0.0.0/24", "10.0.1.0/24"]) && toset(aws_security_group_rule.samplesg_ingress["cidr-list"].ipv6_cidr_blocks) == toset(["2001:db8::/64"])
    error_message = "Expected IPv4 and IPv6 CIDRs to use their matching AWS rule arguments."
  }

  assert {
    condition     = { for rule in output.security_group_rules : rule.id => rule }["single-443"].from_port == 443 && { for rule in output.security_group_rules : rule.id => rule }["single-443"].to_port == 443
    error_message = "Expected the single HTTPS port to remain 443."
  }

  assert {
    condition     = { for rule in output.security_group_rules : rule.id => rule }["single-443"].type == "ingress"
    error_message = "Expected surrounding rule-type whitespace to be removed during normalization."
  }

  assert {
    condition     = { for rule in output.security_group_rules : rule.id => rule }["port-range"].from_port == 8000 && { for rule in output.security_group_rules : rule.id => rule }["port-range"].to_port == 8080
    error_message = "Expected the worker port range to remain 8000 through 8080."
  }

  assert {
    condition     = { for rule in output.security_group_rules : rule.id => rule }["cidr-list"].description == "DNS to shared networks"
    error_message = "Expected descriptions to be preserved."
  }

  assert {
    condition     = { for rule in output.security_group_rules : rule.id => rule }["single-443"].name == "api" && { for rule in output.security_group_rules : rule.id => rule }["port-range"].name == "worker"
    error_message = "Expected each rule to retain its security-group name."
  }
}
