mock_provider "aws" {}

variables {
  rules_csv_content = file("tests/fixtures/valid-rules.csv")
}

run "creates_security_groups_with_creator_tags" {
  command = apply

  variables {
    security_group_tags = {
      creatorId   = "original-creator"
      CreatorName = "Original Creator"
      environment = "test"
    }
  }

  assert {
    condition = alltrue([
      for group in concat(values(aws_security_group.security_groups), [aws_default_security_group.main_vpc]) :
      group.tags["creatorId"] == "original-creator" && group.tags["CreatorName"] == "Original Creator"
    ])
    error_message = "Expected configured creator tags to be applied on creation."
  }
}

run "ignores_creator_tag_changes_and_removal" {
  command = plan

  variables {
    security_group_tags = {
      creatorId   = "replacement-creator"
      environment = "updated"
    }
  }

  assert {
    condition = alltrue([
      for group in concat(values(aws_security_group.security_groups), [aws_default_security_group.main_vpc]) :
      group.tags["creatorId"] == "original-creator" && lookup(group.tags, "CreatorName", "") == "Original Creator"
    ])
    error_message = "Expected creator tag changes and removal to be ignored on existing security groups."
  }

  assert {
    condition = alltrue([
      for group in concat(values(aws_security_group.security_groups), [aws_default_security_group.main_vpc]) :
      group.tags["environment"] == "updated"
    ])
    error_message = "Expected ordinary tag changes to remain managed by Terraform."
  }
}
