# Testing and Documentation Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add deterministic AWS-free tests, opt-in AWS integration coverage, reproducible quality gates, and task-oriented documentation for the CSV-driven security-group configuration.

**Architecture:** Keep the repository root as the reusable Terraform module, but make all environment-specific values explicit inputs and normalize CSV rows in locals before creating AWS resources. Terraform native tests use a mocked AWS provider for the default path; integration tests live in a non-default directory and apply only when invoked explicitly with real AWS credentials.

**Tech Stack:** Terraform 1.15.2, HashiCorp AWS provider 4.66.1, Terraform native test framework, TFLint 0.64.0, Checkov 3.3.26, terraform-docs 0.24.0, pre-commit-terraform 1.109.2, GitHub Actions

**Spec:** `docs/superpowers/specs/2026-10-09-testing-documentation-foundation-design.md`

## Global Constraints

- The default verification path must be deterministic and require no AWS credentials.
- Real AWS tests must remain opt-in and must not run on ordinary pull requests.
- Preserve the existing CSV columns: `id,type,name,cidr_block,protocol,from_port,to_port,description`.
- Preserve existing CSV-driven security-group and rule behavior unless a change is explicitly documented and tested.
- Keep provider access and AWS data lookups at the environment boundary.
- Preserve `.terraform.lock.hcl`; do not commit state, `.terraform/`, credentials, real account IDs, or real VPC IDs.
- Preserve unrelated working-tree changes; inspect the diff before editing every currently modified or untracked file.
- Use only narrowly scoped, documented static-analysis exceptions.

## Review Focus

- Duplicate `id` values must fail validation instead of silently overwriting a rule in the `for_each` map; Task 2 pins this behavior.
- Comma-separated CIDRs with surrounding whitespace must be trimmed and remain in source order; Task 1 pins this behavior.
- Missing CSV headers or malformed CSV must return the documented validation error rather than an expression crash; Task 2 pins this behavior.
- A `from_port` greater than `to_port`, or a port outside `0..65535`, must fail before provider planning; Task 2 pins this behavior.
- Empty security-group names and unsupported rule types must fail validation rather than producing provider-dependent errors; Task 2 pins this behavior.

---

## File Structure

- `versions.tf`: Terraform and AWS provider version constraints.
- `provider.tf`: AWS provider configuration sourced only from input variables.
- `variables.tf`: typed module inputs and cross-row CSV validation.
- `sample-sg.tf`: CSV normalization plus AWS security-group/rule resources.
- `outputs.tf`: stable module outputs used by consumers and tests.
- `tests/security_groups.tftest.hcl`: default mocked-provider plan tests.
- `tests/invalid_rules.tftest.hcl`: expected-failure tests for invalid CSV input.
- `tests/fixtures/*.csv`: synthetic valid and invalid rule fixtures.
- `tests/integration/security_groups.tftest.hcl`: explicit real-AWS apply test.
- `examples/basic/*`: minimal consumer configuration with placeholder inputs.
- `.tflint.hcl`, `.checkov.yml`, `.terraform-docs.yml`, `.pre-commit-config.yaml`: pinned local quality-tool configuration.
- `scripts/check-repository-hygiene.sh`: rejects tracked Terraform state, provider caches, plans, and credential files.
- `.github/workflows/quality.yml`: AWS-free pull-request and push checks.
- `.github/workflows/integration.yml`: manually dispatched OIDC-backed AWS integration test.
- `README.md`: user-facing source of truth with generated input/output tables.
- `CONTRIBUTING.md`: contributor workflow and quality gates.
- `SECURITY.md`: state, AWS permission, rule-review, and reporting guidance.

### Task 1: Typed CSV Transformation and AWS-Free Plan Tests

**Files:**
- Create: `versions.tf`
- Modify: `provider.tf`
- Modify: `variables.tf`
- Modify: `sample-sg.tf`
- Delete: `vpc.tf`
- Create: `outputs.tf`
- Create: `tests/security_groups.tftest.hcl`
- Create: `tests/fixtures/valid-rules.csv`

**Interfaces:**
- Consumes: CSV text with columns `id,type,name,cidr_block,protocol,from_port,to_port,description`.
- Produces: variables `aws_region:string`, `aws_profile:string|null`, `vpc_id:string`, `node_group_cidr:string`, `rules_csv_content:string|null`, and `security_group_tags:map(string)`.
- Produces: normalized local objects with `id`, `type`, `name`, `description`, `protocol`, `from_port:number`, `to_port:number`, and `cidr_blocks:list(string)`.
- Produces: outputs `security_group_ids:map(string)`, `security_group_names:list(string)`, and `security_group_rules:list(object(...))`; preserve existing `sgs` and `sg_app_details` output semantics where compatible.

- [ ] **Step 1: Write the valid fixture and failing mocked-provider tests**

Create `tests/fixtures/valid-rules.csv` with two groups and four rows: one single-port ingress rule, one port-range egress rule, one rule containing `"10.0.0.0/24, 10.0.1.0/24"`, and a second rule for the first group to prove name deduplication.

In `tests/security_groups.tftest.hcl`, declare `mock_provider "aws" {}` and plan runs asserting:

```hcl
assert {
  condition     = toset(output.security_group_names) == toset(["api", "worker"])
  error_message = "Expected CSV group names to be deduplicated."
}

assert {
  condition     = length(output.security_group_rules) == 4
  error_message = "Expected one normalized rule per CSV row."
}

assert {
  condition     = output.security_group_rules[index(output.security_group_rules[*].id, "cidr-list")].cidr_blocks == ["10.0.0.0/24", "10.0.1.0/24"]
  error_message = "Expected comma-separated CIDRs to be trimmed in source order."
}
```

Add assertions for a `443` single port, the `8000..8080` range, description preservation, and each rule's group name.

- [ ] **Step 2: Run the test to verify the current configuration fails**

Run: `terraform test -filter=tests/security_groups.tftest.hcl`

Expected: FAIL because `rules_csv_content`, `vpc_id`, and the stable outputs do not exist.

- [ ] **Step 3: Add explicit Terraform and provider contracts**

Create `versions.tf` with `required_version = ">= 1.7.0, < 2.0.0"` and AWS provider constraint `>= 4.66.1, < 6.0.0`. Update `provider.tf` so `region = var.aws_region` and `profile = var.aws_profile`; remove hard-coded provider access values.

Define all Task 1 variables with descriptions and exact types in `variables.tf`. Use `null` as the default for `aws_profile` and `rules_csv_content`, keep `us-east-1` as the default region, and require `vpc_id` explicitly.

- [ ] **Step 4: Normalize CSV input and wire resources**

In `sample-sg.tf`, select `var.rules_csv_content` when non-null; otherwise render `securitygrouprules.tpl` with `var.node_group_cidr`. Normalize numeric ports with `tonumber`, split and `trimspace` every CIDR, deduplicate group names, set `vpc_id = var.vpc_id`, and set `tags = var.security_group_tags`.

Keep `aws_security_group_rule` keys based on validated row IDs. Replace embedded organization/operator tags with the input map.

Delete the tracked `vpc.tf`: the module must consume an existing VPC ID and must not create the hard-coded `172.168.0.0/16` VPC. This intentionally adopts the existing local deletion because it is part of the environment-boundary change; do not stage the unrelated local deletions of `generate_sg_rules.py` or `ip_mapping.yaml`.

- [ ] **Step 5: Add stable outputs**

Move public outputs to `outputs.tf`. Expose maps/lists with deterministic ordering where Terraform permits it; retain compatibility outputs rather than removing them without a migration note. Remove the literal-string `myoutput` output because it does not expose infrastructure state.

- [ ] **Step 6: Run formatting and the focused tests**

Run: `terraform fmt -recursive && terraform init -backend=false && terraform validate && terraform test -filter=tests/security_groups.tftest.hcl`

Expected: initialization and validation succeed; all valid-input test runs PASS without AWS credentials.

- [ ] **Step 7: Commit**

```bash
git add versions.tf provider.tf variables.tf sample-sg.tf outputs.tf tests/security_groups.tftest.hcl tests/fixtures/valid-rules.csv .terraform.lock.hcl
git add -u -- vpc.tf
git commit -m "feat: make security group inputs testable"
```

### Task 2: Invalid CSV Contract Tests

**Files:**
- Modify: `variables.tf`
- Modify: `sample-sg.tf`
- Create: `tests/invalid_rules.tftest.hcl`
- Create: `tests/fixtures/duplicate-id.csv`
- Create: `tests/fixtures/malformed.csv`
- Create: `tests/fixtures/missing-column.csv`
- Create: `tests/fixtures/invalid-port.csv`
- Create: `tests/fixtures/invalid-rule.csv`

**Interfaces:**
- Consumes: Task 1's `rules_csv_content:string|null` and normalized row shape.
- Produces: one validation contract with a stable error message covering parseability, required fields, unique IDs, supported types, valid port ranges, non-empty group names, and syntactically valid IPv4/IPv6 CIDRs.

- [ ] **Step 1: Write failing expected-failure runs**

Create one synthetic fixture per failure class and runs named:

- `reject_duplicate_ids`
- `reject_malformed_csv`
- `reject_missing_columns`
- `reject_invalid_port_range`
- `reject_empty_name_and_invalid_type`

Each run sets `rules_csv_content = file(...)`, uses `command = plan`, and declares `expect_failures = [var.rules_csv_content]`. Include `from_port = 9000, to_port = 8000`, `from_port = -1`, and `to_port = 65536` across the invalid-port fixture.

- [ ] **Step 2: Run the invalid-input tests to verify they fail for the wrong reasons**

Run: `terraform test -filter=tests/invalid_rules.tftest.hcl`

Expected: FAIL because invalid inputs are not yet rejected through `var.rules_csv_content`.

- [ ] **Step 3: Add cross-row CSV validation**

Add a `validation` block to `rules_csv_content` that permits `null` and otherwise wraps the complete decode/validation expression in `can(...)`. Require:

- all eight named columns on every row;
- non-empty `id` and `name`;
- unique IDs;
- `type` in `["ingress", "egress"]`;
- numeric ports in `0..65535` with `from_port <= to_port`;
- at least one CIDR and every trimmed CIDR accepted by `cidrhost`.

Use this exact error message:

```text
rules_csv_content must be valid CSV with the documented columns, unique non-empty IDs and names, ingress or egress types, valid ordered ports from 0 through 65535, and valid comma-separated CIDRs.
```

- [ ] **Step 4: Run all Terraform tests**

Run: `terraform fmt -check -recursive && terraform validate && terraform test`

Expected: all valid runs and all expected-failure runs PASS without AWS credentials.

- [ ] **Step 5: Commit**

```bash
git add variables.tf sample-sg.tf tests/invalid_rules.tftest.hcl tests/fixtures
git commit -m "test: reject invalid security group CSV"
```

### Task 3: Consumer Example and Opt-In AWS Integration Test

**Files:**
- Create: `examples/basic/main.tf`
- Create: `examples/basic/variables.tf`
- Create: `examples/basic/terraform.tfvars.example`
- Create: `tests/integration/security_groups.tftest.hcl`
- Create: `scripts/run-integration-tests.sh`

**Interfaces:**
- Consumes: Task 1's root module inputs and outputs.
- Produces: a credential-free example with placeholder `vpc_id`, optional `aws_profile`, synthetic CSV content, and no real account identifiers.
- Produces: integration entry point `RUN_AWS_INTEGRATION_TESTS=true TEST_VPC_ID=<test-vpc-id> ./scripts/run-integration-tests.sh`.

- [ ] **Step 1: Write the example validation check and integration test**

Create an integration test with `command = apply`, a unique test-only group name supplied through CSV text, and assertions that the applied security-group ID is non-empty and the normalized rule count is one.

Create `scripts/run-integration-tests.sh` to exit non-zero before invoking Terraform unless `RUN_AWS_INTEGRATION_TESTS` is exactly `true` and `TEST_VPC_ID` is non-empty. Its only Terraform invocation is:

```bash
terraform test -test-directory=tests/integration -var="vpc_id=${TEST_VPC_ID}"
```

Run: `terraform -chdir=examples/basic init -backend=false && terraform -chdir=examples/basic validate`

Expected: FAIL because the example does not exist.

- [ ] **Step 2: Add the minimal consumer example**

Create a root-module call using `source = "../.."`. Require only a caller-supplied placeholder VPC ID, pass synthetic tags, and demonstrate `file("${path.module}/rules.csv")` or inline CSV without account-specific values. Include a `.tfvars.example` containing `vpc-xxxxxxxxxxxxxxxxx`, never a usable VPC ID.

- [ ] **Step 3: Verify the example and default-test isolation**

Run:

```bash
terraform -chdir=examples/basic init -backend=false
terraform -chdir=examples/basic validate
terraform test
```

Expected: example validation succeeds; default `terraform test` succeeds and does not discover or apply `tests/integration/security_groups.tftest.hcl`.

- [ ] **Step 4: Document and dry-run the integration command without credentials**

Run: `./scripts/run-integration-tests.sh`

Expected: FAIL immediately with the explicit opt-in guard, before attempting AWS access. Do not run the real apply until a dedicated test VPC and least-privilege credentials are available.

- [ ] **Step 5: Commit**

```bash
git add examples/basic tests/integration scripts/run-integration-tests.sh
git commit -m "test: add opt-in AWS integration coverage"
```

### Task 4: Local Quality Gates, Generated Reference, and Repository Hygiene

**Files:**
- Modify: `.gitignore`
- Create: `.tflint.hcl`
- Create: `.checkov.yml`
- Create: `.terraform-docs.yml`
- Create: `.pre-commit-config.yaml`
- Create: `scripts/check-repository-hygiene.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: Task 1's Terraform variables and outputs.
- Produces: `terraform-docs markdown table --config .terraform-docs.yml .` output injected between README markers.
- Produces: a zero-exit hygiene command only when `git ls-files` contains no state, backup state, plan, `.terraform/`, credential, or environment-secret files.

- [ ] **Step 1: Establish failing local gate checks**

Run:

```bash
tflint --init
tflint --recursive
checkov --config-file .checkov.yml
terraform-docs markdown table --config .terraform-docs.yml .
./scripts/check-repository-hygiene.sh
```

Expected: FAIL because the configurations/script do not exist and generated documentation markers are absent.

- [ ] **Step 2: Add repository hygiene rules**

Expand `.gitignore` for `.terraform/`, `*.tfstate`, `*.tfstate.*`, `*.tfplan`, `.terraform.tfstate.lock.info`, `crash.log`, `crash.*.log`, `.env`, and local `*.tf__` scratch files. Preserve `.terraform.lock.hcl`.

Create an executable hygiene script using `git ls-files` and anchored patterns. It must print every offending tracked path and exit non-zero; it must not inspect or print file contents. Do not delete unrelated untracked files or stage the user's existing deletions.

- [ ] **Step 3: Configure pinned local tools**

Configure:

- TFLint core rules plus the AWS plugin, with no blanket disabled-rule list;
- Checkov framework `terraform`, compact output, and only resource-level skips that have an adjacent rationale;
- terraform-docs 0.24.0 in inject mode for `README.md`;
- pre-commit-terraform 1.109.2 hooks for `terraform_fmt`, `terraform_validate`, `terraform_tflint`, `terraform_docs`, and `terraform_checkov`, plus a local hygiene hook.

- [ ] **Step 4: Add generated README markers**

Add `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` to `README.md`, generate the variables/outputs table, and keep hand-written content outside the generated block.

- [ ] **Step 5: Run all local quality gates**

Run:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
tflint --init
tflint --recursive
checkov --config-file .checkov.yml
terraform-docs markdown table --config .terraform-docs.yml .
git diff --exit-code README.md
./scripts/check-repository-hygiene.sh
pre-commit run --all-files
```

Expected: every command exits 0. If tools are absent, install the pinned versions only after the missing-command failure.

- [ ] **Step 6: Commit**

```bash
git add .gitignore .tflint.hcl .checkov.yml .terraform-docs.yml .pre-commit-config.yaml scripts/check-repository-hygiene.sh README.md
git commit -m "chore: add Terraform quality gates"
```

### Task 5: GitHub Actions Quality and Integration Workflows

**Files:**
- Create: `.github/workflows/quality.yml`
- Create: `.github/workflows/integration.yml`

**Interfaces:**
- Consumes: Tasks 1-4 commands and committed tool configurations.
- Produces: AWS-free PR/push jobs `terraform`, `tflint`, and `checkov`.
- Produces: manual integration inputs `confirm`, `vpc_id`, and `aws_region`; consumes repository variable `AWS_ROLE_TO_ASSUME` through GitHub OIDC and calls Task 3's integration script.

- [ ] **Step 1: Write workflows and verify their expected commands**

Create `quality.yml` for pull requests and pushes to `main`. Pin:

- `actions/checkout@v7.0.1`
- `hashicorp/setup-terraform@v4.0.1` with Terraform `1.15.2`
- `terraform-linters/setup-tflint@v6.3.2` with TFLint `v0.64.0`
- `bridgecrewio/checkov-action@v12` with Checkov `3.3.26`
- `terraform-docs/gh-actions@v1.4.1` with fail-on-diff behavior

Create `integration.yml` using `workflow_dispatch`, required confirmation and VPC inputs, `permissions: id-token: write, contents: read`, and `aws-actions/configure-aws-credentials@v6.3.0`. Set `RUN_AWS_INTEGRATION_TESTS=true` and `TEST_VPC_ID` from the dispatch input, then call `./scripts/run-integration-tests.sh`. Leave Terraform test cleanup enabled and allow cleanup failures to fail the job.

- [ ] **Step 2: Validate workflow syntax and command parity**

Run: `pre-commit run --all-files`

Expected: PASS, including YAML checks if available.

Compare each workflow command with Task 4's local command list. Expected: PR checks include formatting, init without backend, validation, default tests, generated-doc diff, hygiene, TFLint, and Checkov; no PR job requests AWS credentials.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/quality.yml .github/workflows/integration.yml
git commit -m "ci: verify Terraform configuration"
```

### Task 6: User, Contributor, and Security Documentation

**Files:**
- Modify: `README.md`
- Create: `CONTRIBUTING.md`
- Create: `SECURITY.md`

**Interfaces:**
- Consumes: exact commands, variables, outputs, examples, opt-in integration flow, and CI behavior established in Tasks 1-5.
- Produces: one user guide, one contributor workflow, and one security/reporting policy with no duplicated generated input/output tables.

- [ ] **Step 1: Write a documentation acceptance checklist**

Before editing, verify the current documents do not yet answer:

- what the module creates and how CSV rows flow to AWS resources;
- supported Terraform/provider versions and prerequisites;
- each CSV column and a safe synthetic example;
- quick start, plan/apply, outputs, testing, linting, integration opt-in, and cleanup;
- state/credential handling, least-privilege permissions, rule-review expectations, and vulnerability reporting.

Expected: the checklist fails against the current one-line README.

- [ ] **Step 2: Rewrite the README around user tasks**

Add: overview, architecture/data flow, prerequisites, quick start using `examples/basic`, CSV schema table, template variables, generated inputs/outputs block, local quality commands, CI/integration behavior, security considerations, cleanup, limitations, and extension points.

Clearly warn that CSV content controls network access, plans must be reviewed, state can contain sensitive infrastructure metadata, and `0.0.0.0/0` rules require deliberate review.

- [ ] **Step 3: Add contributor and security guides**

In `CONTRIBUTING.md`, document setup, fixture conventions, red/green Terraform test workflow, generated-doc command, pre-commit installation, exact quality gate, integration prerequisites, and PR expectations.

In `SECURITY.md`, document private vulnerability reporting through GitHub Security Advisories, state/credential non-commitment, OIDC/least-privilege CI requirements, CIDR/port review, and response expectations without inventing a guaranteed response time.

- [ ] **Step 4: Regenerate references and run the complete AWS-free suite**

Run:

```bash
terraform-docs markdown table --config .terraform-docs.yml .
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
tflint --init
tflint --recursive
checkov --config-file .checkov.yml
./scripts/check-repository-hygiene.sh
pre-commit run --all-files
git diff --check
```

Expected: every command exits 0 without AWS credentials and generated documentation has no diff on a second run.

- [ ] **Step 5: Commit**

```bash
git add README.md CONTRIBUTING.md SECURITY.md
git commit -m "docs: explain usage testing and security"
```

### Task 7: Final Compatibility and Clean-Checkout Verification

**Files:**
- Modify only files required by failures found in this task.

**Interfaces:**
- Consumes: all prior task outputs and commands.
- Produces: evidence that a fresh checkout passes the AWS-free quality gate and that no unrelated working-tree changes were included.

- [ ] **Step 1: Review the aggregate diff against the spec**

Run:

```bash
git diff 7cecb7f --stat
git diff 7cecb7f -- . ':!docs/superpowers/plans/2026-10-09-testing-documentation-foundation.md'
git status --short
```

Expected: only planned implementation files are in implementation commits; pre-existing unrelated changes remain identifiable and are not silently reverted or absorbed.

- [ ] **Step 2: Verify from a clean temporary checkout**

Create a temporary checkout of the implementation HEAD, then run the Task 6 AWS-free suite there. Do not copy the current `.terraform/` directory, state, environment files, or credentials into it.

Expected: initialization downloads only declared providers; every AWS-free command exits 0.

- [ ] **Step 3: Verify compatibility outputs and example**

Run:

```bash
terraform -chdir=examples/basic init -backend=false
terraform -chdir=examples/basic validate
terraform test -filter=tests/security_groups.tftest.hcl
```

Expected: PASS; compatibility outputs remain present and the example resolves the root module without real identifiers.

- [ ] **Step 4: Commit only if verification required a fix**

```bash
git add <only-files-fixed-during-verification>
git commit -m "fix: address verification findings"
```

If no fixes were needed, do not create an empty commit.
