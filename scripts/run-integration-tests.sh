#!/usr/bin/env bash
set -euo pipefail

if [[ "${RUN_AWS_INTEGRATION_TESTS:-}" != "true" ]]; then
  echo "RUN_AWS_INTEGRATION_TESTS must be exactly true." >&2
  exit 2
fi

if [[ -z "${TEST_AWS_REGION:-}" ]]; then
  echo "TEST_AWS_REGION must be set to the AWS region for the test resources." >&2
  exit 2
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${repo_root}"

terraform test -test-directory=tests/integration -var="aws_region=${TEST_AWS_REGION}"
