# Contributing

## Local setup

Install Terraform 1.7 or newer (but lower than 2.0), TFLint 0.64.0,
terraform-docs 0.24.0, Checkov 3.3.26, and pre-commit. Then initialize the
module without a backend:

```bash
terraform init -backend=false
pre-commit install
```

Keep `.terraform.lock.hcl` committed when provider selections change. Never
commit `.terraform/`, state, plans, credentials, or environment files.

## Test-driven workflow

Use red-green-refactor for behavior changes:

1. Add or update a focused `*.tftest.hcl` assertion.
2. Run the focused test and confirm it fails for the intended reason.
3. Make the smallest Terraform change that satisfies the contract.
4. Run the focused test, then the complete AWS-free suite.

```bash
terraform test -filter=tests/security_groups.tftest.hcl
terraform test
```

Put synthetic CSV data in `tests/fixtures/`. Fixtures must not contain real
account IDs, VPC IDs, credentials, internal hostnames, or sensitive production
CIDRs. Add one fixture per invalid-input class so failures remain clear.

Shell entry points in `scripts/` require regression coverage in
`tests/scripts/`.

## Generated documentation

Terraform inputs, outputs, providers, and resources are generated inside the
README markers:

```bash
terraform-docs markdown table --config .terraform-docs.yml .
```

Edit narrative documentation outside those markers. Run the command twice and
confirm the second run makes no change.

## Local quality gate

Run the same AWS-free checks used by pull requests:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
tests/scripts/run-integration-tests.sh
tests/scripts/check-repository-hygiene.sh
tests/scripts/check-workflows.sh
tests/scripts/check-documentation.sh
tflint --init
tflint --recursive
checkov --config-file .checkov.yml
./scripts/check-repository-hygiene.sh
pre-commit run --all-files
git diff --check
```

The integration guard test does not contact AWS. The real integration test is
not part of this gate.

## AWS integration test

Use a dedicated, non-production VPC and a least-privilege role that can create,
describe, tag, and delete security groups and rules. Explicitly opt in:

```bash
RUN_AWS_INTEGRATION_TESTS=true \
TEST_VPC_ID=vpc-replace-with-test-vpc \
TEST_AWS_REGION=us-east-1 \
./scripts/run-integration-tests.sh
```

Do not run the test against a shared or production VPC. Terraform test normally
destroys applied resources; investigate and clean up any failed teardown.

## Pull requests

- Keep behavior changes and their failing-then-passing tests together.
- Explain CSV contract or output compatibility changes.
- Update narrative and generated documentation when interfaces change.
- Document each Checkov exclusion beside the exact resource and explain why
  the module boundary requires it.
- Confirm all AWS-free gates pass before requesting review.
- Do not include generated state, local caches, credentials, or real
  infrastructure identifiers.
