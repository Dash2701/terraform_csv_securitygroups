
# Create Security group for Sample SG 

resource "aws_security_group" "samplesg" {

  name = "sample-sg"

  vpc_id = aws_vpc.main_vpc.id

}

locals {
  csv_data_app = file("sg/qa/app.csv")
  appip        = csvdecode(local.csv_data_app)

  sg_app_details = flatten([

    for sggr in local.appip : {
      rule_id     = sggr.rule_id
      description = sggr.Description
      protocol    = sggr.protocol
      from_port   = sggr.From_Port
      to_port     = sggr.To_Port
      cidr_blocks = split(",", sggr.source_cidr)
    }
  ])
}

resource "aws_security_group_rule" "samplesg_ingress" {
  count             = length(local.sg_app_details)
  security_group_id = aws_security_group.appsg.id
  type              = "ingress"
  description       = "${local.sg_app_details[count.index].rule_id}-${local.sg_app_details[count.index].description}"
  protocol          = local.sg_app_details[count.index].protocol
  from_port         = local.sg_app_details[count.index].from_port
  to_port           = local.sg_app_details[count.index].to_port
  cidr_blocks       = local.sg_app_details[count.index].cidr_blocks
}

resource "aws_security_group_rule" "samplesg_egress" {
  type              = "egress"
  security_group_id = aws_security_group.appsg.id
  description       = "App SG Egress"
  protocol          = "-1"
  from_port         = "0"
  to_port           = "0"
  cidr_blocks       = ["0.0.0.0/0"]
}
