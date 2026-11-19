#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

approval=$(realpath "${1:?Pass the production approval record}")
[[ -z $(git status --porcelain) && $(hostname -s) == optiplex ]]
[[ $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
[[ $(aws sts get-caller-identity --query Account --output text) == 062008221187 ]]
operator_commit=$(git rev-parse HEAD)
git merge-base --is-ancestor "$operator_commit" refs/remotes/origin/main

tag=$(jq -er '.releaseTag | select(test("^howlong/v[0-9]+\\.[0-9]+\\.[0-9]+$"))' "$approval")
[[ $(git cat-file -t "refs/tags/$tag") == tag ]]
commit=$(git rev-parse "refs/tags/$tag^{commit}")
git merge-base --is-ancestor "$commit" refs/remotes/origin/main
git diff --quiet "$commit" HEAD -- services/howlong
base="${XDG_DATA_HOME:-$HOME/.local/share}/howlong"
state="$base/cloud"
legacy="$base/production"
database="$legacy/counter.sqlite"
host=howlong.robertboscacci.com
zone=Z1BDNRWTPWQNUU
bucket=robertboscacci-howlong-archive-production-062008221187
alarm=robertboscacci-howlong-archive-production-offline

exec 9>"$state/production-deploy.lock"
flock -n 9
digest=$(jq -er --arg commit "$commit" 'select(.commit == $commit) | .digest | select(test("^sha256:[a-f0-9]{64}$"))' "$state/dev.json")
verified_at=$(jq -er '.verifiedAt | fromdateiso8601' "$state/dev.json")
jq -e --arg commit "$commit" --arg digest "$digest" --arg host "$host" --argjson verified "$verified_at" '
  .commit == $commit and .artifact == $digest and .target == $host and
  (.instruction | length > 0) and (.recordedAt | fromdateiso8601 >= $verified)
' "$approval" >/dev/null
[[ $(aws ecr describe-images --region us-west-2 --repository-name robertboscacci-howlong --image-ids imageTag="$commit" --query 'imageDetails[0].imageDigest' --output text) == "$digest" ]]
image="062008221187.dkr.ecr.us-west-2.amazonaws.com/robertboscacci-howlong@$digest"
test -s "$database"

public_addresses() {
  aws route53 list-resource-record-sets --hosted-zone-id "$zone" --output json \
    | jq -cer --arg name "$host." '[.ResourceRecordSets[] | select(.Name == $name and .Type == "A") | .ResourceRecords[].Value]'
}

work=$(mktemp -d "${XDG_RUNTIME_DIR:?}/howlong-production.XXXXXXXX")
frozen=false
migration_version=''
key=''
cleanup() {
  if $frozen && [[ $(public_addresses) == '[]' ]]; then
    systemctl --user start howlong-production.service || true
  fi
  if [[ -n $migration_version ]]; then
    aws s3api delete-object --region us-west-2 --bucket "$bucket" --key "$key" \
      --version-id "$migration_version" --expected-bucket-owner 062008221187 >/dev/null || true
  fi
  find "$work" -depth -delete
}
trap cleanup EXIT

remote() {
  local code=$1 command response status
  command=$(aws ssm send-command --region us-west-2 --instance-ids "$instance" --document-name AWS-RunShellScript \
    --comment 'Promote the approved How Long production release' --parameters "$(jq -cn --arg code "$code" '{commands:[$code],executionTimeout:["300"]}')" \
    --query Command.CommandId --output text)
  for attempt in {1..78}; do
    response=$(aws ssm get-command-invocation --region us-west-2 --instance-id "$instance" --command-id "$command" --output json 2>/dev/null) || response='{}'
    status=$(jq -r .Status <<<"$response")
    case "$status" in
      Success) jq -r .StandardOutputContent <<<"$response"; return ;;
      Failed|Cancelled|TimedOut) break ;;
    esac
    sleep 4
  done
  printf 'Cloud command %s ended in %s. Inspect the SSM invocation.\n' "$command" "$status" >&2
  return 1
}

archive() { TF_DATA_DIR="$work/archive-tofu" tofu -chdir=infra/howlong-archive "$@"; }
archive init -input=false -lockfile=readonly -no-color -backend-config='key=howlong/archive-production.tfstate'
actions=$(aws cloudwatch describe-alarms --region us-east-1 --alarm-names "$alarm" --output json | jq -r '.MetricAlarms[0].ActionsEnabled // false')
archive apply -input=false -auto-approve -no-color -var='environment=production' -var='cloud_runtime=true' -var="notifications_enabled=$actions"

audit_key="releases/$tag/approval.json"
if aws s3api head-object --region us-west-2 --bucket "$bucket" --key "$audit_key" --expected-bucket-owner 062008221187 >/dev/null 2>"$work/audit-error"; then
  aws s3api get-object --region us-west-2 --bucket "$bucket" --key "$audit_key" --expected-bucket-owner 062008221187 "$work/approval.json" >/dev/null
  cmp -s "$approval" "$work/approval.json"
else
  grep -q '(404)' "$work/audit-error"
  aws s3api put-object --region us-west-2 --bucket "$bucket" --key "$audit_key" --body "$approval" \
    --content-type application/json --if-none-match '*' --server-side-encryption AES256 --expected-bucket-owner 062008221187 >/dev/null
fi

secret=howlong/cloud/production/web-login
if ! aws secretsmanager describe-secret --region us-west-2 --secret-id "$secret" >/dev/null 2>"$work/secret-error"; then
  grep -q ResourceNotFoundException "$work/secret-error"
  openssl rand -hex 24 | tr -d '\n' > "$work/password"
  aws secretsmanager create-secret --region us-west-2 --name "$secret" --secret-string "file://$work/password" >/dev/null
  unlink "$work/password"
fi
password=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id "$secret" --query SecretString --output text)
[[ $password =~ ^[a-f0-9]{48}$ ]]
printf 'user = "owner:%s"\n' "$password" > "$work/curl.conf"
unset password

addresses=$(public_addresses)
phase=stage
if [[ $addresses != '[]' ]]; then
  # An earlier invocation may have published DNS before it finished local retirement.
  [[ $(systemctl --user is-active howlong-production.service || true) == inactive ]]
  phase=publish
fi
host_record=$(bash scripts/provision-howlong-cloud.sh production "$approval" "$phase")
instance=$(jq -er '.instance | select(test("^i-[0-9a-f]+$"))' <<<"$host_record")
ip=$(jq -er '.ip | select(test("^[0-9]+(\\.[0-9]+){3}$"))' <<<"$host_record")
expected=$(jq -cn --arg ip "$ip" '[$ip]')
[[ $addresses == '[]' || $addresses == "$expected" ]]

for attempt in {1..90}; do
  ping=$(aws ssm describe-instance-information --region us-west-2 --filters "Key=InstanceIds,Values=$instance" \
    --query 'InstanceInformationList[0].PingStatus' --output text)
  if [[ $ping == Online ]]; then break; fi
  if [[ $attempt == 90 ]]; then echo 'The production instance never registered with SSM.' >&2; exit 1; fi
  sleep 4
done
staged=$(remote 'set -eu; for attempt in $(seq 1 80); do if mountpoint -q /var/lib/howlong && systemctl is-active --quiet docker; then break; fi; test "$attempt" -lt 80; sleep 3; done; if test -s /var/lib/howlong/counter/counter.sqlite; then echo present; else echo absent; fi')
[[ $staged == present || ( $staged == absent && $phase == stage ) ]]
if [[ $staged == absent ]]; then
  node --no-warnings scripts/howlong-migration.mjs "$database" "$work/counter.sqlite" >/dev/null
  key="migration/production-$commit-$(openssl rand -hex 6).sqlite"
  checksum=$(sha256sum "$work/counter.sqlite" | cut -d' ' -f1)
  migration_version=$(aws s3api put-object --region us-west-2 --bucket "$bucket" --key "$key" --body "$work/counter.sqlite" \
    --expected-bucket-owner 062008221187 --if-none-match '*' --server-side-encryption AES256 --query VersionId --output text)
  [[ $migration_version != None && -n $migration_version ]]
fi

if [[ $phase == stage ]]; then
  encoded=$(base64 -w 0 services/howlong/cloud-install.sh)
  remote "set -euo pipefail; install_script=\$(mktemp /run/howlong-control.XXXXXXXX); trap 'unlink \"\$install_script\"' EXIT; printf %s '$encoded' | base64 -d > \"\$install_script\"; bash \"\$install_script\" production '$image' '$key' '${checksum:-}'" \
    | grep '"event":"howlong_cloud_ready"'
fi
[[ $(remote 'docker inspect --format "{{.Config.Image}}" howlong-cloud') == "$image" ]]

probe() {
  local origin="https://$host" path
  for path in / /app.mjs /api/counter /api/reset-history.csv; do
    [[ $(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 "$@" -H 'X-Howlong-User: owner' "$origin$path") == 401 ]] || return 1
  done
  curl -fsS --max-time 10 "$@" --config "$work/curl.conf" -H 'X-Howlong-User: forged' "$origin/api/counter" \
    | jq -e '.canReset and (.resetHistory | type) == "object"' >/dev/null || return 1
  curl -fsS --max-time 10 "$@" --config "$work/curl.conf" "$origin/api/reset-history.csv" -o "$work/history.csv" || return 1
  grep -q '^reset_number,reset_at_utc' "$work/history.csv"
}
probe --resolve "$host:443:$ip"

for attempt in {1..18}; do
  alarm_state=$(aws cloudwatch describe-alarms --region us-east-1 --alarm-names "$alarm" --query 'MetricAlarms[0].StateValue' --output text)
  if [[ $alarm_state == OK ]]; then break; fi
  if [[ $attempt == 18 ]]; then echo 'Production health heartbeat has not cleared the alarm.' >&2; exit 1; fi
  sleep 10
done
if [[ $actions == false ]]; then
  archive apply -input=false -auto-approve -no-color -var='environment=production' -var='cloud_runtime=true' -var='notifications_enabled=true'
fi

remaining_local_hosts() {
  local tail_ip
  tail_ip=$(tailscale ip -4)
  docker exec pihole cat /etc/pihole/hosts/custom.list \
    | jq -Rcen --arg host "$host" --arg exact "$tail_ip $host" '
      [inputs | select(length > 0 and (startswith("#") | not))] as $current |
      select(all($current[]; (split(" ") | index($host) == null) or . == $exact)) |
      {changed: ($current | index($exact) != null), hosts: ($current | map(select(. != $exact)))}
    '
}
remaining_local_hosts >/dev/null

if [[ $phase == stage ]]; then
  encoded=$(base64 -w 0 scripts/howlong-migration.mjs)
  fingerprint=$(remote "set -euo pipefail; fingerprint=\$(mktemp /run/howlong-fingerprint.XXXXXXXX); trap 'unlink \"\$fingerprint\"' EXIT; printf %s '$encoded' | base64 -d > \"\$fingerprint\"; chmod 0444 \"\$fingerprint\"; docker run --rm --no-healthcheck --read-only --network none --cap-drop ALL --security-opt no-new-privileges:true -v /var/lib/howlong/counter:/state:ro -v \"\$fingerprint:/fingerprint.mjs:ro\" '$image' --no-warnings /fingerprint.mjs /state/counter.sqlite")
  [[ $fingerprint =~ ^[a-f0-9]{64}$ ]]
  frozen=true
  systemctl --user stop howlong-production.service
  if [[ $(node --no-warnings scripts/howlong-migration.mjs "$database") != "$fingerprint" ]]; then
    echo 'The production database changed during staging. Reconcile the staged copy before publishing DNS.' >&2
    exit 1
  fi
  bash scripts/provision-howlong-cloud.sh production "$approval" publish >/dev/null
fi
[[ $(public_addresses) == "$expected" ]]

# Pi-hole stores the former private route alongside unrelated custom hosts.
local_dns=$(remaining_local_hosts)
if jq -e .changed <<<"$local_dns" >/dev/null; then
  docker exec pihole pihole-FTL --config dns.hosts "$(jq -c .hosts <<<"$local_dns")" >/dev/null
  docker exec pihole pihole reloaddns >/dev/null
fi

for attempt in {1..12}; do
  if [[ $(dig +short +time=3 +tries=1 @127.0.0.1 "$host" A) == "$ip" ]] && probe; then break; fi
  if [[ $attempt == 12 ]]; then echo 'Public and tailnet DNS have not converged on the verified AWS host.' >&2; exit 1; fi
  sleep 5
done
frozen=false
if [[ -f $legacy/ingress.json ]]; then
  mv -T --no-clobber "$legacy/ingress.json" "$legacy/ingress-optiplex-retired.json"
  [[ ! -e $legacy/ingress.json ]]
fi
systemctl --user disable --now howlong-production.service howlong-edge.service howlong-edge-renew.timer
jq -n --arg tag "$tag" --arg commit "$commit" --arg digest "$digest" --arg operator "$operator_commit" \
  --arg instance "$instance" --arg url "https://$host" --arg date "$(date -u +%FT%TZ)" \
  '{event:"howlong_cloud_production_verified",releaseTag:$tag,commit:$commit,digest:$digest,operatorCommit:$operator,instance:$instance,url:$url,verifiedAt:$date}' > "$work/production.json"
mv -f "$work/production.json" "$state/production.json"
cat "$state/production.json"
