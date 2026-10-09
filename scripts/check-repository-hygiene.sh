#!/usr/bin/env bash
set -euo pipefail

repo_root=${1:-$(git rev-parse --show-toplevel)}
offenders=""

while IFS= read -r path; do
  case "${path}" in
    .terraform/* | */.terraform/* | *.tfstate | *.tfstate.* | *.tfplan | .terraform.tfstate.lock.info | */.terraform.tfstate.lock.info | .env | */.env | *.pem | *.key | credentials | */credentials)
      offenders="${offenders}${path}"$'\n'
      ;;
  esac
done < <(git -C "${repo_root}" ls-files)

if [[ -n "${offenders}" ]]; then
  echo "Forbidden tracked repository paths:" >&2
  printf '%s' "${offenders}" >&2
  exit 1
fi

echo "Repository hygiene check passed."
