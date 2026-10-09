#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
readme="${repo_root}/README.md"
contributing="${repo_root}/CONTRIBUTING.md"
security="${repo_root}/SECURITY.md"

for expected in \
  "## Overview" \
  "## How it works" \
  "## Prerequisites" \
  "## Quick start" \
  "## CSV schema" \
  "## Default template" \
  "## Testing and quality" \
  "## Continuous integration" \
  "## Security considerations" \
  "## Cleanup" \
  "## Limitations and extension points" \
  "0.0.0.0/0" \
  "terraform plan"; do
  grep -Fq "${expected}" "${readme}"
done

for expected in \
  "# Contributing" \
  "## Test-driven workflow" \
  "terraform test" \
  "terraform-docs" \
  "pre-commit run --all-files" \
  "RUN_AWS_INTEGRATION_TESTS" \
  "TEST_AWS_REGION"; do
  grep -Fq "${expected}" "${contributing}"
done

for expected in \
  "# Security Policy" \
  "GitHub Security Advisory" \
  "least-privilege" \
  "OIDC" \
  "Terraform state" \
  "CIDR"; do
  grep -Fq "${expected}" "${security}"
done

echo "Documentation contract checks passed."
