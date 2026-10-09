#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
runner="${repo_root}/scripts/run-integration-tests.sh"

set +e
output=$("${runner}" 2>&1)
status=$?
set -e

if [[ ${status} -eq 0 ]] || [[ ${output} != *"RUN_AWS_INTEGRATION_TESTS must be exactly true"* ]]; then
  echo "Expected the integration runner to reject missing opt-in." >&2
  exit 1
fi

set +e
output=$(RUN_AWS_INTEGRATION_TESTS=true "${runner}" 2>&1)
status=$?
set -e

if [[ ${status} -eq 0 ]] || [[ ${output} != *"TEST_VPC_ID must be set"* ]]; then
  echo "Expected the integration runner to reject a missing test VPC ID." >&2
  exit 1
fi

echo "Integration guard checks passed."
