# Terraform CSV Security Groups

## Overview

This Terraform module creates AWS security groups and standalone security-group
rules from CSV content. It is intended for teams that review network rules in a
tabular format while managing their lifecycle through Terraform.

> [!CAUTION]
> CSV content controls network access. Review every `terraform plan` before
> applying it. Rules using `0.0.0.0/0` or `::/0` require deliberate security
> review.

## How it works

1. The module reads `rules_csv_content`, or renders
   `securitygrouprules.tpl` when that input is null.
2. Terraform decodes and validates every row, including unique IDs, rule type,
   ports, and IPv4 or IPv6 CIDRs.
3. The module creates its own VPC from `vpc_cidr`.
4. Group names are deduplicated into `aws_security_group` resources in that
   VPC.
5. Each CSV row becomes one `aws_security_group_rule`. Mixed IPv4 and IPv6
   lists are sent to the matching AWS provider arguments.
6. Outputs expose the VPC ID, security-group IDs, and normalized rules.

The module creates its own VPC. It does not attach security groups to workloads
or configure remote state.

The VPC, generated security groups, and default security group ignore changes
to the case-sensitive `creatorId` and `CreatorName` tags after creation. This
preserves creator metadata maintained outside Terraform while all other tags
remain managed normally. Creator tags supplied in `security_group_tags` are
still applied when security groups are first created.

## Prerequisites

- Terraform `>= 1.7.0, < 2.0.0`
- AWS provider `>= 4.66.1, < 6.0.0`
- Permission to create and delete a VPC, security groups, and rules
- AWS credentials supplied through environment/workload credentials or the
  optional `aws_profile` input

TFLint, Checkov, terraform-docs, and pre-commit are required only for the full
local contributor workflow.

## Quick start

The example creates a VPC using a synthetic private network and contains no
usable account identifier:

```bash
cd examples/basic
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform plan
terraform apply
```

For module usage, copy the module block from `examples/basic/main.tf` and
provide `vpc_cidr`, CSV content, and your required tags. Prefer environment or
workload credentials over a shared-credentials profile.

## CSV schema

CSV must include this exact header:

```csv
id,type,name,cidr_block,protocol,from_port,to_port,description
```

| Column | Contract |
| --- | --- |
| `id` | Unique, non-empty Terraform key for the rule. |
| `type` | `ingress` or `egress` (case-insensitive). |
| `name` | Non-empty security-group name; repeated names share one group. |
| `cidr_block` | One valid IPv4/IPv6 CIDR or a quoted comma-separated list. |
| `protocol` | AWS protocol value such as `tcp`, `udp`, `icmp`, or `-1`. |
| `from_port` | Integer from `0` through `65535`. |
| `to_port` | Integer from `0` through `65535`, not less than `from_port`. |
| `description` | Rule description passed to AWS. |

Example:

```csv
id,type,name,cidr_block,protocol,from_port,to_port,description
api-https,ingress,example-api,10.0.0.0/24,tcp,443,443,HTTPS from app network
dns,egress,example-api,"10.0.1.0/24,2001:db8::/64",udp,53,53,DNS to shared networks
```

Quote `cidr_block` when it contains multiple comma-separated CIDRs. Whitespace
around individual CIDRs is removed.

## Default template

When `rules_csv_content` is null, the module renders
`securitygrouprules.tpl`. The `node_group_cidr` input replaces
`${node_group_cidr}` in that template. Pass explicit CSV content for
environment-specific rule sets; do not put credentials or account identifiers
in CSV fixtures.

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
| [aws_default_security_group.main_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_security_group.security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.samplesg_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc.main_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | Optional shared-credentials profile. Leave null for environment or workload credentials. | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region in which to manage security groups. | `string` | `"us-east-1"` | no |
| <a name="input_node_group_cidr"></a> [node\_group\_cidr](#input\_node\_group\_cidr) | CIDR substituted into the default security-group rule template. | `string` | `"10.102.0.0/24"` | no |
| <a name="input_rules_csv_content"></a> [rules\_csv\_content](#input\_rules\_csv\_content) | Optional CSV rule content. When null, securitygrouprules.tpl is rendered. | `string` | `null` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | Tags applied to every security group. | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | IPv4 CIDR block for the VPC created by this module. | `string` | `"172.16.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Security group IDs keyed by CSV security-group name. |
| <a name="output_security_group_names"></a> [security\_group\_names](#output\_security\_group\_names) | Sorted, deduplicated security-group names from the CSV input. |
| <a name="output_security_group_rules"></a> [security\_group\_rules](#output\_security\_group\_rules) | Normalized security-group rules decoded from the CSV input. |
| <a name="output_sg_app_details"></a> [sg\_app\_details](#output\_sg\_app\_details) | Compatibility output containing normalized CSV rules. |
| <a name="output_sgs"></a> [sgs](#output\_sgs) | Compatibility list of created security-group IDs. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC created by this module. |
<!-- END_TF_DOCS -->

## Testing and quality

The default suite mocks the AWS provider and requires no AWS credentials:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
tflint --init
tflint --recursive
checkov --config-file .checkov.yml
terraform-docs markdown table --config .terraform-docs.yml .
./scripts/check-repository-hygiene.sh
pre-commit run --all-files
```

`terraform test` covers valid transformations, deduplication, mixed IPv4/IPv6
CIDRs, port ranges, descriptions, and invalid CSV contracts.
It also verifies that creator tags are applied on creation, ignored on later
changes or removal, and do not prevent updates to other security-group tags.

The real-AWS test is intentionally excluded from default discovery. It creates
and destroys its own VPC, so use a non-production account and least-privilege
credentials:

```bash
RUN_AWS_INTEGRATION_TESTS=true \
TEST_AWS_REGION=us-east-1 \
./scripts/run-integration-tests.sh
```

Terraform test destroys the VPC and security groups after the apply run. Treat
cleanup failures as failures and remove any remaining test resources manually.

## Continuous integration

`.github/workflows/quality.yml` runs formatting, initialization without a
backend, validation, AWS-free tests, generated-doc checks, repository hygiene,
TFLint, and Checkov on pull requests and pushes to `main`. It does not request
AWS credentials.

`.github/workflows/integration.yml` is manual-only. It requires confirmation,
an AWS region, and a repository variable named `AWS_ROLE_TO_ASSUME`. It obtains
short-lived credentials through GitHub OIDC and calls the same guarded
integration script used locally.

## Security considerations

- Review the complete plan for CIDR, protocol, and port changes before apply.
- Avoid public CIDRs unless the exposure is intentional and approved.
- Terraform state can contain sensitive infrastructure metadata. Do not commit
  state, plans, credentials, environment files, or `.terraform/`.
- Use least-privilege AWS roles. CI should use OIDC rather than long-lived
  access keys.
- The module removes all rules from the created VPC's default security group.
- VPC flow logging is not configured because destinations, retention, and IAM
  policies are deployment-specific; configure it in the calling environment.
- Security groups are created but not attached; consumers must attach the
  returned IDs to the intended AWS resources.

See `SECURITY.md` for reporting and operational guidance.

## Cleanup

For the basic example:

```bash
cd examples/basic
terraform destroy
rm -rf .terraform
rm -f terraform.tfstate terraform.tfstate.backup terraform.tfvars
```

Never delete state until Terraform has destroyed or relinquished the managed
resources. The repository hygiene check reports forbidden tracked artifacts
without printing their contents.

## Limitations and extension points

- The module supports CIDR-based rules only; source security groups, prefix
  lists, and self-references require additional schema fields.
- Security-group names must be unique within the target VPC.
- Rule updates use standalone `aws_security_group_rule` resources and therefore
  follow that provider resource's replacement behavior.
- The default template is an example. Production callers should supply
  reviewed CSV content and organization-specific tags.
- Remote state, workload attachment, and production integration-test
  orchestration are intentionally outside this repository.
- VPC flow logging is intentionally delegated to the calling environment.
