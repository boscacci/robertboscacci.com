#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test -z "$(git status --porcelain)" || { echo 'Commit and review changes before provisioning.' >&2; exit 1; }
bash scripts/bootstrap-trips-state.sh
tofu -chdir=infra/trips init -input=false
tofu -chdir=infra/trips validate
tofu -chdir=infra/trips plan -input=false -out=trips.tfplan
if test "${1:-}" = --apply; then
  trap 'rm -f infra/trips/trips.tfplan' EXIT
  tofu -chdir=infra/trips apply -input=false trips.tfplan
fi
