#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

[[ -z $(git status --porcelain) && $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
[[ $(aws sts get-caller-identity --query Account --output text) == 062008221187 ]]
commit=$(git rev-parse HEAD)
git merge-base --is-ancestor "$commit" refs/remotes/origin/main
base="${XDG_DATA_HOME:-$HOME/.local/share}/howlong"
state="$base/cloud"
record="$state/releases/$commit.json"
image=$(jq -er --arg commit "$commit" 'select(.commit == $commit) | .image' "$record")
digest=$(jq -er .digest "$record")
[[ $image == "062008221187.dkr.ecr.us-west-2.amazonaws.com/robertboscacci-howlong@$digest" && $digest =~ ^sha256:[a-f0-9]{64}$ ]]
[[ $(aws ecr describe-images --region us-west-2 --repository-name robertboscacci-howlong --image-ids imageTag="$commit" --query 'imageDetails[0].imageDigest' --output text) == "$digest" ]]
instance=$(aws ec2 describe-instances --region us-west-2 --filters Name=tag:Name,Values=howlong-cloud-dev \
  Name=tag:Application,Values=howlong-cloud Name=instance-state-name,Values=running --output json \
  | jq -er '[.Reservations[].Instances[].InstanceId] | select(length == 1) | .[0]')
exec 9>"$state/dev-deploy.lock"
flock -n 9

remote() {
  local code=$1 command status response
  command=$(aws ssm send-command --region us-west-2 --instance-ids "$instance" --document-name AWS-RunShellScript \
    --comment 'Deploy the reviewed How Long cloud release' --parameters "$(jq -cn --arg code "$code" '{commands:[$code],executionTimeout:["300"]}')" \
    --query Command.CommandId --output text)
  for attempt in {1..65}; do
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

# No local counter, archive, or migration data is touched before tailnet enrollment.
expected_suffix=$(tailscale status --json | jq -er '.CurrentTailnet.MagicDNSSuffix | rtrimstr(".") | select(test("^[a-z0-9.-]+\\.ts\\.net$"))')
expected_owner=$(tailscale status --json | jq -er '.Self.UserID | numbers')
cloud_tail=$(remote 'mountpoint -q /var/lib/howlong && tailscale status --json | jq -ce '\''select(.BackendState == "Running" and .Self.Online) | {suffix:.CurrentTailnet.MagicDNSSuffix,owner:.Self.UserID}'\''')
jq -e --arg suffix "$expected_suffix" --argjson owner "$expected_owner" '(.suffix | rtrimstr(".")) == $suffix and .owner == $owner' <<<"$cloud_tail" >/dev/null
has_database=$(remote 'if test -f /var/lib/howlong/counter/counter.sqlite; then echo present; else echo absent; fi')
[[ $has_database == present || $has_database == absent ]]
if [[ $has_database == present && ! -f $state/dev.json ]]; then
  echo 'A staged cloud database exists without a verified cutover record. Reconcile the copies before retrying.' >&2
  exit 1
fi

work=$(mktemp -d "${XDG_RUNTIME_DIR:?}/howlong-cutover.XXXXXXXX")
old_stopped=false
verified=false
migration_version=''
key=''
checksum=''
bucket=robertboscacci-howlong-archive-dev-062008221187
cleanup() {
  if ! $verified && $old_stopped; then
    remote 'systemctl stop howlong-cloud-archive.timer howlong-cloud.service 2>/dev/null || true' >/dev/null || true
    systemctl --user start howlong-dev.service howlong-dev-archive.timer || true
  fi
  if [[ -n $migration_version ]]; then
    aws s3api delete-object --region us-west-2 --bucket "$bucket" --key "$key" --version-id "$migration_version" \
      --expected-bucket-owner 062008221187 >/dev/null || true
  fi
  find "$work" -depth -delete
}
trap cleanup EXIT

if [[ $has_database == absent ]]; then
  [[ $(hostname -s) == optiplex && -s $base/dev/counter.sqlite ]]
  systemctl --user stop howlong-dev-archive.timer
  old_stopped=true
  systemctl --user stop howlong-dev-archive.service howlong-dev.service
  node --no-warnings --input-type=module - "$base/dev/counter.sqlite" "$work/counter.sqlite" <<'JS'
import { backup, DatabaseSync } from 'node:sqlite';
const source = new DatabaseSync(process.argv[2], { readOnly: true });
try {
  if (source.prepare('PRAGMA quick_check').get().quick_check !== 'ok') throw Error('Counter integrity check failed');
  await backup(source, process.argv[3]);
} finally { source.close(); }
JS
  key="migration/dev-$commit-$(openssl rand -hex 6).sqlite"
  checksum=$(sha256sum "$work/counter.sqlite" | cut -d' ' -f1)
  migration_version=$(aws s3api put-object --region us-west-2 --bucket "$bucket" --key "$key" --body "$work/counter.sqlite" \
    --expected-bucket-owner 062008221187 --if-none-match '*' --server-side-encryption AES256 --query VersionId --output text)
  [[ $migration_version != None && -n $migration_version ]]
fi

encoded=$(base64 -w 0 services/howlong/cloud-install.sh)
result=$(remote "set -euo pipefail; install_script=\$(mktemp /run/howlong-control.XXXXXXXX); trap 'unlink \"\$install_script\"' EXIT; printf %s '$encoded' | base64 -d > \"\$install_script\"; bash \"\$install_script\" dev '$image' '$key' '$checksum'")
ready=$(sed -n '/^{"event":"howlong_cloud_ready"/p' <<<"$result")
origin=$(jq -er '.url | select(test("^https://[a-z0-9.-]+\\.ts\\.net$"))' <<<"$ready")
tail=$(jq -er '.tailnetAddress | select(test("^100\\.[0-9.]+$"))' <<<"$ready")
host=${origin#https://}
[[ $(curl -fsS --max-time 10 --resolve "$host:443:$tail" "$origin/healthz") == howlong-ok ]]
curl -fsS --max-time 10 --resolve "$host:443:$tail" -H 'Tailscale-User-Login: forged@example.invalid' "$origin/api/counter" \
  | jq -e '.canReset and (.resetHistory | type) == "object"' >/dev/null
jq -n --arg commit "$commit" --arg digest "$digest" --arg url "$origin" --arg date "$(date -u +%FT%TZ)" \
  '{event:"howlong_cloud_dev_verified",commit:$commit,digest:$digest,url:$url,verifiedAt:$date}' > "$work/dev.json"
mv -f "$work/dev.json" "$state/dev.json"
verified=true
cat "$state/dev.json"
