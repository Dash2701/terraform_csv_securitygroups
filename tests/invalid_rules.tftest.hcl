mock_provider "aws" {}

variables {
  vpc_id = "vpc-00000000000000000"
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
