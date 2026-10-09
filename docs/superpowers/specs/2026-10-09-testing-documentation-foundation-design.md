# Testing and Documentation Foundation Design

**Date:** 2026-10-09  
**Status:** Approved for implementation planning

## Goal

Make the Terraform repository safe to change and understandable to new
contributors. The default verification path must be deterministic and
AWS-free, while real AWS integration testing remains available as an explicit
opt-in.

## Current constraints

The root configuration converts CSV/template data into AWS security groups and
rules. It currently has limited documentation, no automated test suite or CI,
loosely typed variables, hard-coded infrastructure and metadata values, and
several work-in-progress files. The existing working tree also contains local
Terraform state/provider artifacts that must not become part of the repository
contract.

The implementation should preserve the existing CSV-driven behavior while
making environment-specific values explicit and testable.

## Testing architecture

### Configuration boundary

Introduce a clear boundary around the CSV-to-security-group transformation.
The boundary should accept explicit inputs for rule data and environment
metadata rather than depending on hard-coded VPC IDs, profiles, account IDs,
or operator metadata. Keep provider access and AWS data lookups at the
environment boundary so pure plan tests can exercise transformation behavior
without credentials.

Add explicit Terraform and provider version constraints. Replace untyped
variables with useful Terraform types, descriptions, and validation rules
where the existing behavior permits it.

### Unit and plan tests

Add deterministic fixture CSV/template inputs under `tests/fixtures/`. Add
Terraform native test files (`*.tftest.hcl`) that run without AWS credentials
and assert:

- expected security-group names and deduplication;
- security-rule count and key attributes;
- CIDR list splitting and preservation;
- single ports, port ranges, and protocol values;
- descriptions and rule-to-security-group association;
- clear failure for malformed or invalid input.

Tests should assert observable plan/configuration behavior rather than
implementation details. Fixtures must not contain real account identifiers or
credentials.

### Integration tests

Keep apply-based tests separate from the default test command. They must
require an explicit opt-in variable and documented AWS credentials, use a
dedicated test naming convention, and clean up resources reliably. CI should
not run them on ordinary pull requests.

## Quality gates

Add a local pre-commit configuration and GitHub Actions workflow. The default
fast path should run:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`
3. `terraform validate`
4. `terraform test`
5. TFLint with its AWS ruleset
6. Checkov (or an equivalent IaC scanner)

Tool configuration should be committed and version-pinned where practical.
Findings may be excluded only with a documented, narrowly scoped rationale;
the configuration must not hide failures through broad ignores or silent
fallbacks.

The workflow should use separate jobs for formatting/validation/tests and
static security analysis. An optional integration workflow must be manually
invoked or restricted to a protected event, use least-privilege AWS
credentials, and expose cleanup failure explicitly.

## Documentation

Rewrite `README.md` as the user-facing source of truth. It should cover:

- purpose and architecture/data flow;
- prerequisites and supported Terraform/provider versions;
- quick start and safe example usage;
- CSV schema, template variables, and examples;
- variables and outputs;
- local test and lint commands;
- CI behavior;
- security, state handling, and cleanup guidance;
- known limitations and extension points.

Add:

- `examples/` with a minimal, credential-free configuration and no real
  account/VPC identifiers;
- `CONTRIBUTING.md` with the local quality-gate commands and pull-request
  expectations;
- `SECURITY.md` covering state-file handling, required AWS permissions,
  security-rule review, and vulnerability reporting.

Generated documentation should be added only where a stable source of truth
and generation check can be established. Otherwise, keep the README and
Terraform descriptions authoritative to avoid stale generated output.

## Repository hygiene

As part of the implementation:

- remove or quarantine obsolete `*.tf__` files and unrelated scratch files
  when confirmed not to be active configuration;
- ensure Terraform state, backups, `.terraform/`, and local artifacts remain
  ignored and are not tracked;
- preserve `.terraform.lock.hcl`;
- replace hard-coded environment values in examples with variables;
- add a repository check that prevents state files and local provider
  directories from being committed.

Existing unrelated working-tree changes must be preserved and reviewed before
editing affected files.

## Acceptance criteria

- A clean checkout can run the fast quality-gate commands without AWS
  credentials.
- `terraform test` covers both representative valid fixtures and invalid
  input paths.
- CI runs the same fast checks as local development.
- Static analysis is enabled with documented, narrow exceptions.
- A new contributor can understand inputs, outputs, safe usage, testing, and
  cleanup from the documentation.
- No state file, local provider directory, credential, or real account
  identifier is required by the examples or committed test fixtures.
- Existing CSV-driven security-group behavior is preserved unless a behavior
  change is explicitly documented and tested.

## Out of scope

- Redesigning the security-group rule model beyond what is necessary to create
  a testable boundary.
- Provisioning shared or production AWS infrastructure from CI.
- Introducing a remote state backend.
- Rewriting all historical data files unless they are active inputs or violate
  the repository hygiene requirements.
