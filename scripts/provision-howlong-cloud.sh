#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

environment=${1:-dev}
[[ $environment == dev || $environment == production ]]
[[ -z $(git status --porcelain) ]]
[[ $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
[[ $(aws sts get-caller-identity --query Account --output text) == 062008221187 ]]
commit=$(git rev-parse HEAD)
git merge-base --is-ancestor "$commit" refs/remotes/origin/main
if [[ $environment == production ]]; then
  approval=${2:?Pass the post-smoke-test production approval record}
  tag=$(jq -er '.releaseTag | select(test("^howlong/v[0-9]+\\.[0-9]+\\.[0-9]+$"))' "$approval")
  [[ $(git cat-file -t "refs/tags/$tag") == tag && $(git rev-parse "refs/tags/$tag^{commit}") == "$commit" ]]
  dev="${XDG_DATA_HOME:-$HOME/.local/share}/howlong/cloud/dev.json"
  digest=$(jq -er --arg commit "$commit" 'select(.commit == $commit) | .digest | select(test("^sha256:[0-9a-f]{64}$"))' "$dev")
  verified_at=$(jq -er '.verifiedAt | fromdateiso8601' "$dev")
  jq -e --arg digest "$digest" --argjson verified "$verified_at" '
    .target == "howlong.robertboscacci.com" and .artifact == $digest and (.instruction | length > 0) and (.recordedAt | fromdateiso8601 >= $verified)
  ' "$approval" >/dev/null
fi

work=$(mktemp -d)
trap 'find "$work" -depth -delete' EXIT
export TF_DATA_DIR="$work/tofu"
tofu -chdir=infra/howlong-cloud init -input=false -lockfile=readonly -no-color -backend-config="key=howlong/cloud-$environment.tfstate"
tofu -chdir=infra/howlong-cloud apply -input=false -auto-approve -no-color -var="environment=$environment"
instance=$(tofu -chdir=infra/howlong-cloud output -raw instance_id)
jq -cn --arg instance "$instance" --arg environment "$environment" '{event:"howlong_cloud_host_provisioned",instance:$instance,environment:$environment}'
