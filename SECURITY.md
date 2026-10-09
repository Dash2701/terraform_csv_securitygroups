# Security Policy

## Reporting a vulnerability

Report suspected vulnerabilities privately through a GitHub Security Advisory
for this repository. Do not open a public issue containing exploit details,
credentials, state data, account identifiers, or sensitive network ranges.

Maintainers will acknowledge and assess reports as availability permits,
coordinate remediation with the reporter where practical, and publish details
only after a safe resolution. This project does not promise a fixed response
or remediation timeline.

## Terraform state and credentials

Terraform state can contain sensitive infrastructure metadata, even when this
module's inputs are not marked sensitive. Store state in an access-controlled
backend for real environments and never commit:

- `*.tfstate` or state backups;
- saved Terraform plans;
- `.terraform/` provider and module caches;
- `.env`, AWS credential files, private keys, or access tokens.

Run `./scripts/check-repository-hygiene.sh` before committing. The script
reports forbidden paths but does not read or print their contents.

Prefer short-lived environment or workload credentials. GitHub Actions
integration runs must use OIDC and a dedicated least-privilege role rather
than repository secrets containing long-lived AWS keys.

## Required AWS permissions

Grant only the EC2 security-group actions required to create, describe, tag,
authorize/revoke rules, and delete test resources in the selected region and
test VPC. Restrict the trust policy for the GitHub OIDC role to this repository
and the intended workflow context. Do not reuse a production deployment role
for integration tests.

## Reviewing network rules

Every change to CSV content is a network-policy change. Review:

- ingress versus egress direction;
- every IPv4 and IPv6 CIDR, especially `0.0.0.0/0` and `::/0`;
- protocol and port ranges, including `-1` all-protocol rules;
- the target security-group name and VPC;
- duplicate or unexpectedly removed rules in `terraform plan`;
- whether the created security group is attached only to intended resources.

Descriptions and tags aid review but are not enforcement controls. Require
organizational approval for public exposure and broad administrative ports.

## Integration-test safety

The default suite mocks AWS. Real integration requires both
`RUN_AWS_INTEGRATION_TESTS=true` and `TEST_VPC_ID`, and should run only in a
dedicated non-production VPC. Terraform test attempts cleanup after apply.
Treat cleanup failures as incidents: inspect the test output and remove
remaining security groups or rules before rerunning.
