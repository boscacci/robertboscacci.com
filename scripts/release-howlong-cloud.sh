#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

[[ -z $(git status --porcelain) && $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
[[ $(aws sts get-caller-identity --query Account --output text) == 062008221187 ]]
environment=${1:?Use dev or production}
[[ $environment == dev || $environment == production ]]
state="${XDG_DATA_HOME:-$HOME/.local/share}/howlong/cloud"
commit=${HOWLONG_RELEASE_COMMIT:-$(git rev-parse HEAD)}
[[ $commit =~ ^[0-9a-f]{40}$ ]]
host=howlong-dev.robertboscacci.com
if [[ $environment == production ]]; then
  host=howlong.robertboscacci.com
  approval=${2:?Pass the post-smoke-test approval record}
  tag=$(jq -er '.releaseTag | select(test("^howlong/v[0-9]+\\.[0-9]+\\.[0-9]+$"))' "$approval")
  [[ $(git cat-file -t "refs/tags/$tag") == tag ]]
  commit=$(git rev-parse "refs/tags/$tag^{commit}")
fi
git merge-base --is-ancestor HEAD refs/remotes/origin/main
git merge-base --is-ancestor "$commit" refs/remotes/origin/main
git diff --quiet "$commit" HEAD -- services/howlong
record="$state/releases/$commit.json"
image=$(jq -er --arg commit "$commit" 'select(.commit == $commit) | .image' "$record")
digest=$(jq -er .digest "$record")
[[ $image == "062008221187.dkr.ecr.us-west-2.amazonaws.com/robertboscacci-howlong@$digest" && $digest =~ ^sha256:[a-f0-9]{64}$ ]]
[[ $(aws ecr describe-images --region us-west-2 --repository-name robertboscacci-howlong --image-ids imageTag="$commit" --query 'imageDetails[0].imageDigest' --output text) == "$digest" ]]
instance=$(aws ec2 describe-instances --region us-west-2 --filters Name=tag:Name,Values=howlong-cloud-"$environment" \
  Name=tag:Application,Values=howlong-cloud Name=instance-state-name,Values=running --output json \
  | jq -er '[.Reservations[].Instances[].InstanceId] | select(length == 1) | .[0]')
exec 9>"$state/$environment-deploy.lock"
flock -n 9

remote() {
  local code=$1 command status response
  command=$(aws ssm send-command --region us-west-2 --instance-ids "$instance" --document-name AWS-RunShellScript \
    --comment 'Deploy the reviewed How Long cloud release' --parameters "$(jq -cn --arg code "$code" '{commands:[$code],executionTimeout:["900"]}')" \
    --query Command.CommandId --output text)
  for attempt in {1..225}; do
    response=$(aws ssm get-command-invocation --region us-west-2 --instance-id "$instance" --command-id "$command" --output json 2>/dev/null) || response='{}'
    status=$(jq -r .Status <<<"$response")
    if [[ $status == Success ]]; then jq -r .StandardOutputContent <<<"$response"; return 0; fi
    if [[ $status == Failed || $status == Cancelled || $status == TimedOut ]]; then
      printf 'Cloud command %s returned %s. Inspect the SSM invocation.\n' "$command" "$status" >&2
      return 1
    fi
    sleep 4
  done
  printf 'Cloud command %s did not finish in time.\n' "$command" >&2
  return 1
}
if [[ $environment == production ]]; then
  verified=$(jq -er --arg commit "$commit" --arg digest "$digest" 'select(.commit == $commit and .digest == $digest) | .verifiedAt' "$state/dev.json")
  deployed=$(jq -er '.deployedAt // .verifiedAt' "$state/dev.json")
  jq -ef scripts/howlong-approval.jq --arg host "$host" --arg digest "$digest" --arg commit "$commit" \
    --arg deployed "$deployed" --arg verified "$verified" "$approval" >/dev/null
  bucket=robertboscacci-howlong-archive-production-062008221187
  work=$(mktemp -d "${XDG_RUNTIME_DIR:?}/howlong-approval.XXXXXXXX")
  trap 'find "$work" -depth -delete' EXIT
  audit_key="releases/$tag/approval.json"
  if aws s3api head-object --region us-west-2 --bucket "$bucket" --key "$audit_key" --expected-bucket-owner 062008221187 >/dev/null 2>"$work/audit-error"; then
    aws s3api get-object --region us-west-2 --bucket "$bucket" --key "$audit_key" --expected-bucket-owner 062008221187 "$work/approval.json" >/dev/null
    cmp -s "$approval" "$work/approval.json"
  else
    grep -q '(404)' "$work/audit-error"
    aws s3api put-object --region us-west-2 --bucket "$bucket" --key "$audit_key" --body "$approval" \
      --content-type application/json --if-none-match '*' --server-side-encryption AES256 --expected-bucket-owner 062008221187 >/dev/null
  fi
  find "$work" -depth -delete
  trap - EXIT
fi
owner=$(tailscale whois --json "$(tailscale ip -4)" | jq -er '.UserProfile.LoginName | select(test("^[A-Za-z0-9._+@-]+$"))')
remote 'set -eu; mountpoint -q /var/lib/howlong; test -s /var/lib/howlong/counter/counter.sqlite; systemctl is-active --quiet docker'
encoded=$(base64 -w 0 services/howlong/cloud-install.sh)
if [[ ${HOWLONG_VERIFY_ONLY:-0} != 1 ]]; then
  remote "set -eu; f=\$(mktemp /run/howlong-install.XXXXXXXX); trap 'unlink \"\$f\"' EXIT; printf %s '$encoded' | base64 -d > \"\$f\"; bash \"\$f\" '$environment' '$image' '' '' '$owner'"
fi
container=$(remote 'docker inspect --format "{{.Config.Image}} {{.State.StartedAt}} {{.State.Running}}" howlong-cloud')
read -r running_image started running <<<"$container"
[[ $running_image == "$image" && $running == true ]]
deployed=$(date -u -d "$started" +%FT%TZ)
origin=https://$host
curl -fsS --max-time 10 "$origin/" >/dev/null
curl -fsS --max-time 10 -H "Tailscale-User-Login: $owner" -H 'X-Howlong-User: owner' "$origin/api/counter" | jq -e '.canReset == false and (has("resetHistory") | not)' >/dev/null
[[ $(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' "$origin/api/reset-history.csv") == 403 ]]
[[ $(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' -H "Origin: $origin" -H "Tailscale-User-Login: $owner" --json '{"token":null}' "$origin/api/reset") == 403 ]]
echo "Public counter verified at $origin"
private=https://howlong-$environment.tailbea63b.ts.net:8443
curl -fsS --max-time 10 -H "Origin: $origin" "$private/api/counter" | jq -e '.canReset and (.resetHistory | type == "object")' >/dev/null
curl -fsS --max-time 10 --json '{"token":null}' -H "Origin: $origin" "$private/api/reset" | jq -e '.remaining == 4' >/dev/null
record=$(mktemp "$state/.$environment.XXXXXXXX")
trap 'rm -f "$record"' EXIT
jq -n --arg commit "$commit" --arg digest "$digest" --arg url "$origin" --arg date "$(date -u +%FT%TZ)" \
  --arg deployed "$deployed" --arg tag "${tag:-}" '{commit:$commit,digest:$digest,url:$url,deployedAt:$deployed,verifiedAt:$date} + (if $tag == "" then {} else {releaseTag:$tag} end)' > "$record"
mv -f "$record" "$state/$environment.json"
