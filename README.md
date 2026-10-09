# Terraform CSV Security Groups

This module creates AWS security groups and rules from CSV content.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.66.1, < 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.66.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_security_group.security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.samplesg_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | Optional shared-credentials profile. Leave null for environment or workload credentials. | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region in which to manage security groups. | `string` | `"us-east-1"` | no |
| <a name="input_node_group_cidr"></a> [node\_group\_cidr](#input\_node\_group\_cidr) | CIDR substituted into the default security-group rule template. | `string` | `"10.102.0.0/24"` | no |
| <a name="input_rules_csv_content"></a> [rules\_csv\_content](#input\_rules\_csv\_content) | Optional CSV rule content. When null, securitygrouprules.tpl is rendered. | `string` | `null` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | Tags applied to every security group. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the existing VPC in which to create security groups. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Security group IDs keyed by CSV security-group name. |
| <a name="output_security_group_names"></a> [security\_group\_names](#output\_security\_group\_names) | Sorted, deduplicated security-group names from the CSV input. |
| <a name="output_security_group_rules"></a> [security\_group\_rules](#output\_security\_group\_rules) | Normalized security-group rules decoded from the CSV input. |
| <a name="output_sg_app_details"></a> [sg\_app\_details](#output\_sg\_app\_details) | Compatibility output containing normalized CSV rules. |
| <a name="output_sgs"></a> [sgs](#output\_sgs) | Compatibility list of created security-group IDs. |
<!-- END_TF_DOCS -->
