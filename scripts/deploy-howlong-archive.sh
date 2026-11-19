#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

environment=${1:-dev}
[[ $environment == dev || $environment == production ]]
[[ -z $(git status --porcelain) && $(hostname -s) == optiplex && $(id -u) != 0 ]]
[[ $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
[[ $(aws sts get-caller-identity --query Account --output text) == 062008221187 ]]
commit=$(git rev-parse HEAD)
git merge-base --is-ancestor "$commit" refs/remotes/origin/main
base="${XDG_DATA_HOME:-$HOME/.local/share}/howlong"
state="$base/$environment"
release="$base/dev/releases/$commit"
code="$release/services/howlong"
unit="howlong-$environment-archive"
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
node_bin=$(readlink -f "$(command -v node)")
[[ $node_bin =~ ^/[[:alnum:]._/-]+$ && $state =~ ^/[[:alnum:]._/-]+$ && -f $state/counter.sqlite ]]
sha=$(sha256sum "$release/howlong.tar.gz" | cut -d' ' -f1)
jq -e --arg commit "$commit" --arg sha "$sha" '.commit == $commit and .sha256 == $sha' "$state/$environment.json" >/dev/null
if [[ $environment == production ]]; then
  approval="$state/approval.json"
  tag=$(jq -er '.releaseTag | select(test("^howlong/v[0-9]+\\.[0-9]+\\.[0-9]+$"))' "$approval")
  [[ $(git cat-file -t "refs/tags/$tag") == tag && $(git rev-parse "refs/tags/$tag^{commit}") == "$commit" ]]
  jq -e --arg sha "$sha" '.target == "howlong.robertboscacci.com" and .artifact == $sha and (.instruction | length > 0)' "$approval" >/dev/null
fi

exec 9>"$state/archive-deploy.lock"
flock -n 9
work=$(mktemp -d "$state/.archive.XXXXXXXX")
updated=false
verified=false
cleanup() {
  if ! $verified && $updated; then
    if [[ ! -f $work/previous/$unit.timer ]]; then systemctl --user disable --now "$unit.timer" >/dev/null 2>&1 || true; fi
    for file in "$unit.service" "$unit.timer"; do
      if [[ -f $work/previous/$file ]]; then mv -f "$work/previous/$file" "$units/$file"
      else rm -f "$units/$file"; fi
    done
    systemctl --user daemon-reload || true
  fi
  rm -rf -- "$work"
}
trap cleanup EXIT
mkdir -p "$work/verified" "$work/previous" "$units"
tar -xzf "$release/howlong.tar.gz" -C "$work/verified"
diff -r "$work/verified/services/howlong" "$code"

alarm="robertboscacci-howlong-archive-$environment-offline"
notify=$(aws cloudwatch describe-alarms --region us-east-1 --alarm-names "$alarm" --output json \
  | jq -r '.MetricAlarms[0].ActionsEnabled // false')
tofu_archive() { TF_DATA_DIR="$work/tofu" tofu -chdir=infra/howlong-archive "$@"; }
tofu_archive init -input=false -lockfile=readonly -no-color -backend-config="key=howlong/archive-$environment.tfstate"
tofu_archive apply -input=false -auto-approve -no-color -var="environment=$environment" -var="notifications_enabled=$notify"

cat > "$work/$unit.service" <<EOF
[Unit]
Description=Archive How Long $environment reset timestamps to private S3

[Service]
Type=oneshot
Environment="PATH=/usr/bin:/bin:/snap/bin"
ExecStart=$node_bin $code/archive.mjs $environment $state/counter.sqlite %t/$unit
RuntimeDirectory=$unit
RuntimeDirectoryMode=0700
TimeoutStartSec=55
UMask=0077
EOF
cat > "$work/$unit.timer" <<'EOF'
[Unit]
Description=Sync How Long reset timestamps every minute

[Timer]
OnCalendar=*-*-* *:*:00
AccuracySec=5s
Persistent=true

[Install]
WantedBy=timers.target
EOF
for file in "$unit.service" "$unit.timer"; do
  if [[ -f $units/$file ]]; then cp -p "$units/$file" "$work/previous/$file"; fi
done
updated=true
for file in "$unit.service" "$unit.timer"; do install -m 0600 "$work/$file" "$units/$file"; done
systemctl --user daemon-reload
for attempt in {1..6}; do
  if systemctl --user start "$unit.service"; then break; fi
  if [[ $attempt == 6 ]]; then exit 1; fi
  sleep 5
done
systemctl --user enable --now "$unit.timer" >/dev/null
if [[ $notify == false ]]; then
  tofu_archive apply -input=false -auto-approve -no-color -var="environment=$environment" -var='notifications_enabled=true'
fi
jq -n --arg environment "$environment" --arg commit "$commit" --arg sha "$sha" '
  {event:"howlong_archive_verified",environment:$environment,commit:$commit,artifact:$sha}
' > "$work/archive.json"
mv -f "$work/archive.json" "$state/archive.json"
verified=true
cat "$state/archive.json"
