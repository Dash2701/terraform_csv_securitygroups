#!/usr/bin/env bash
set -euo pipefail

if [[ "${RUN_AWS_INTEGRATION_TESTS:-}" != "true" ]]; then
  echo "RUN_AWS_INTEGRATION_TESTS must be exactly true." >&2
  exit 2
fi

if [[ -z "${TEST_VPC_ID:-}" ]]; then
  echo "TEST_VPC_ID must be set to a dedicated test VPC." >&2
  exit 2
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${repo_root}"

terraform test -test-directory=tests/integration -var="vpc_id=${TEST_VPC_ID}"
