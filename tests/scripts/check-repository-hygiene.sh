#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
checker="${repo_root}/scripts/check-repository-hygiene.sh"
fixture="${repo_root}/.hygiene-test-repository"

cleanup() {
  rm -rf -- "${fixture}"
}
trap cleanup EXIT

cleanup
git init -q "${fixture}"
git -C "${fixture}" config user.email "test@example.invalid"
git -C "${fixture}" config user.name "Hygiene Test"

printf 'safe\n' >"${fixture}/main.tf"
git -C "${fixture}" add main.tf

"${checker}" "${fixture}"

printf 'state\n' >"${fixture}/terraform.tfstate"
printf 'secret\n' >"${fixture}/.env"
git -C "${fixture}" add -f terraform.tfstate .env

set +e
output=$("${checker}" "${fixture}" 2>&1)
status=$?
set -e

if [[ ${status} -eq 0 ]] ||
  [[ ${output} != *".env"* ]] ||
  [[ ${output} != *"terraform.tfstate"* ]] ||
  [[ ${output} == *"secret"* ]]; then
  echo "Expected tracked forbidden paths, but not their contents, in the failure output." >&2
  exit 1
fi

echo "Repository hygiene checks passed."
