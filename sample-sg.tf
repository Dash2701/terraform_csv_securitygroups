locals {
  rules_csv = var.rules_csv_content != null ? var.rules_csv_content : templatefile(
    "${path.module}/securitygrouprules.tpl",
    { node_group_cidr = var.node_group_cidr }
  )

  decoded_rules = csvdecode(local.rules_csv)

  sg_app_details = [
    for rule in local.decoded_rules : {
      id          = rule.id
      type        = lower(trimspace(rule.type))
      name        = rule.name
      description = rule.description
      protocol    = lower(rule.protocol)
      from_port   = tonumber(rule.from_port)
      to_port     = tonumber(rule.to_port)
      cidr_blocks = [for cidr in split(",", rule.cidr_block) : trimspace(cidr)]
    }
  ]

  sg_app_names = sort(distinct([for rule in local.sg_app_details : rule.name]))
}

resource "aws_security_group" "security_groups" {
  #checkov:skip=CKV2_AWS_5: This reusable module creates security groups for consumers to attach.
  for_each = toset(local.sg_app_names)

  name        = each.key
  description = "Managed from CSV rules for ${each.key}"
  vpc_id      = aws_vpc.main_vpc.id
  tags        = var.security_group_tags

  lifecycle {
    ignore_changes = [tags["creatorId"], tags["CreatorName"]]
  }
}

resource "aws_security_group_rule" "samplesg_ingress" {
  for_each = { for rule in local.sg_app_details : rule.id => rule }

  security_group_id = aws_security_group.security_groups[each.value.name].id
  type              = each.value.type
  description       = each.value.description
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [for cidr in each.value.cidr_blocks : cidr if !strcontains(cidr, ":")]
  ipv6_cidr_blocks  = [for cidr in each.value.cidr_blocks : cidr if strcontains(cidr, ":")]
}
