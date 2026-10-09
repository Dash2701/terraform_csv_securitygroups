#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
runner="${repo_root}/scripts/run-integration-tests.sh"
fake_bin="${repo_root}/.integration-runner-test-bin"

cleanup() {
  rm -rf -- "${fake_bin}"
}
trap cleanup EXIT

cleanup

set +e
output=$("${runner}" 2>&1)
status=$?
set -e

if [[ ${status} -eq 0 ]] || [[ ${output} != *"RUN_AWS_INTEGRATION_TESTS must be exactly true"* ]]; then
  echo "Expected the integration runner to reject missing opt-in." >&2
  exit 1
fi

mkdir -p "${fake_bin}"
cat >"${fake_bin}/terraform" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*"
EOF
chmod +x "${fake_bin}/terraform"

set +e
output=$(PATH="${fake_bin}:${PATH}" RUN_AWS_INTEGRATION_TESTS=true "${runner}" 2>&1)
status=$?
set -e

if [[ ${status} -eq 0 ]] || [[ ${output} != *"TEST_AWS_REGION must be set"* ]]; then
  echo "Expected the integration runner to reject a missing AWS region." >&2
  exit 1
fi

output=$(PATH="${fake_bin}:${PATH}" RUN_AWS_INTEGRATION_TESTS=true TEST_AWS_REGION=eu-west-1 "${runner}")

if [[ ${output} != *'-var=aws_region=eu-west-1'* ]] || [[ ${output} == *"vpc_id"* ]]; then
  echo "Expected the integration runner to pass its AWS region to Terraform." >&2
  exit 1
fi

echo "Integration guard checks passed."
