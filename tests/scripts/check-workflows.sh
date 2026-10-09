#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
quality="${repo_root}/.github/workflows/quality.yml"
integration="${repo_root}/.github/workflows/integration.yml"

for expected in \
  "actions/checkout@v7.0.1" \
  "hashicorp/setup-terraform@v4.0.1" \
  "terraform fmt -check -recursive" \
  "terraform init -backend=false" \
  "terraform validate" \
  "terraform test" \
  "terraform-docs/gh-actions@v1.4.1" \
  "scripts/check-repository-hygiene.sh" \
  "terraform-linters/setup-tflint@v6.3.2" \
  "tflint --recursive" \
  "bridgecrewio/checkov-action@v12" \
  "3.3.26"; do
  grep -Fq "${expected}" "${quality}"
done

if grep -Fq "AWS_ROLE_TO_ASSUME" "${quality}"; then
  echo "The AWS-free quality workflow must not request AWS credentials." >&2
  exit 1
fi

for expected in \
  "workflow_dispatch:" \
  "id-token: write" \
  "aws-actions/configure-aws-credentials@v6.3.0" \
  "AWS_ROLE_TO_ASSUME" \
  "RUN_AWS_INTEGRATION_TESTS: \"true\"" \
  "TEST_VPC_ID:" \
  "TEST_AWS_REGION:" \
  "./scripts/run-integration-tests.sh"; do
  grep -Fq "${expected}" "${integration}"
done

echo "Workflow contract checks passed."
