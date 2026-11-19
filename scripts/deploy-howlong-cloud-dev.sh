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

# Confirm the cloud host and durable volume before touching the local dev services.
has_database=$(remote 'set -e; mountpoint -q /var/lib/howlong; systemctl is-active --quiet docker; if test -f /var/lib/howlong/counter/counter.sqlite; then echo present; else echo absent; fi')
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
    remote 'systemctl stop howlong-cloud-archive.timer howlong-cloud-edge.service howlong-cloud.service 2>/dev/null || true' >/dev/null || true
    systemctl --user start howlong-dev.service howlong-dev-archive.timer || true
  fi
  if [[ -n $migration_version ]]; then
    aws s3api delete-object --region us-west-2 --bucket "$bucket" --key "$key" --version-id "$migration_version" \
      --expected-bucket-owner 062008221187 >/dev/null || true
  fi
  find "$work" -depth -delete
}
trap cleanup EXIT

secret=howlong/cloud/dev/web-login
if ! aws secretsmanager describe-secret --region us-west-2 --secret-id "$secret" >/dev/null 2>"$work/secret-error"; then
  grep -q 'ResourceNotFoundException' "$work/secret-error"
  openssl rand -hex 24 | tr -d '\n' > "$work/password"
  aws secretsmanager create-secret --region us-west-2 --name "$secret" --secret-string "file://$work/password" >/dev/null
  unlink "$work/password"
fi
password=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id "$secret" --query SecretString --output text)
[[ $password =~ ^[a-f0-9]{48}$ ]]
printf 'user = "owner:%s"\n' "$password" > "$work/curl.conf"
unset password

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
origin=$(jq -er '.url | select(. == "https://howlong-dev.robertboscacci.com")' <<<"$ready")
[[ $(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 -H 'X-Howlong-User: owner' "$origin/api/counter") == 401 ]]
curl -fsS --max-time 10 --config "$work/curl.conf" -H 'X-Howlong-User: forged' "$origin/api/counter" \
  | jq -e '.canReset and (.resetHistory | type) == "object"' >/dev/null
jq -n --arg commit "$commit" --arg digest "$digest" --arg url "$origin" --arg date "$(date -u +%FT%TZ)" \
  '{event:"howlong_cloud_dev_verified",commit:$commit,digest:$digest,url:$url,verifiedAt:$date}' > "$work/dev.json"
mv -f "$work/dev.json" "$state/dev.json"
verified=true
cat "$state/dev.json"
