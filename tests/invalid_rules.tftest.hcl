mock_provider "aws" {}

variables {
  vpc_cidr = "172.16.0.0/16"
}

run "reject_invalid_vpc_cidr" {
  command = plan

  variables {
    vpc_cidr = "not-a-cidr"
  }

  expect_failures = [var.vpc_cidr]
}

run "reject_duplicate_ids" {
  command = plan

  variables {
    rules_csv_content = file("tests/fixtures/duplicate-id.csv")
  }

  expect_failures = [var.rules_csv_content]
}

run "reject_malformed_csv" {
  command = plan

  variables {
    rules_csv_content = file("tests/fixtures/malformed.csv")
  }

  expect_failures = [var.rules_csv_content]
}

run "reject_missing_columns" {
  command = plan

  variables {
    rules_csv_content = file("tests/fixtures/missing-column.csv")
  }

  expect_failures = [var.rules_csv_content]
}

run "reject_invalid_port_range" {
  command = plan

  variables {
    rules_csv_content = file("tests/fixtures/invalid-port.csv")
  }

  expect_failures = [var.rules_csv_content]
}

run "reject_empty_name_and_invalid_type" {
  command = plan

  variables {
    rules_csv_content = file("tests/fixtures/invalid-rule.csv")
  }

  expect_failures = [var.rules_csv_content]
}
