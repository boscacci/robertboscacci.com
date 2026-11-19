#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

test -z "$(git status --porcelain)" || { echo 'Deploy from a clean, reviewed commit.' >&2; exit 1; }
[[ $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
[[ $(hostname -s) == optiplex ]]
[[ $(id -u) != 0 ]]
[[ ${HOWLONG_INITIAL_DATE:-} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
environment=${1:-dev}
base="${XDG_DATA_HOME:-$HOME/.local/share}/howlong"
commit=$(git rev-parse HEAD)
view_origin=''
case "$environment" in
  dev) port=18446 ;;
  production)
    port=18447
    view_origin=https://howlong.robertboscacci.com
    approval=${2:?Pass the recorded release approval}
    tag=$(jq -er '.releaseTag | select(test("^howlong/v[0-9]+\\.[0-9]+\\.[0-9]+$"))' "$approval")
    [[ $(git cat-file -t "refs/tags/$tag") == tag && $(git rev-parse "refs/tags/$tag^{commit}") == "$commit" ]]
    git merge-base --is-ancestor "$commit" refs/remotes/origin/main
    release="$base/dev/releases/$commit"
    sha=$(sha256sum "$release/howlong.tar.gz" | cut -d' ' -f1)
    jq -e --arg commit "$commit" --arg sha "$sha" '.commit == $commit and .sha256 == $sha' "$base/dev/dev.json" >/dev/null
    jq -e --arg target "${view_origin#https://}" --arg sha "$sha" '
      .target == $target and .artifact == $sha and (.instruction | length > 0) and (.recordedAt | fromdateiso8601 > 0)
    ' "$approval" >/dev/null
    ;;
  *) echo 'Usage: deploy-howlong.sh dev | production approval.json' >&2; exit 2 ;;
esac

state="$base/$environment"
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
service="howlong-$environment"
runtime="${XDG_RUNTIME_DIR:?Missing user runtime directory}/$service"
unit="$units/$service.service"
socket="unix:$runtime/server.sock"
mkdir -p "$state" "$units"
exec 9>"$state/deploy.lock"
flock -n 9

node_bin=$(readlink -f "$(command -v node)")
[[ $node_bin =~ ^/[[:alnum:]._/-]+$ && $state =~ ^/[[:alnum:]._/-]+$ ]]
tailscale_state=$(tailscale status --json)
hostname=$(jq -er '.Self.DNSName | rtrimstr(".") | select(test("^[a-z0-9.-]+\\.ts\\.net$"))' <<<"$tailscale_state")
owner=$(tailscale whois --json "$(tailscale ip -4)" | jq -er '.UserProfile.LoginName | select(test("^[A-Za-z0-9._+@-]+$"))')
origin="https://$hostname:$port"
serve_before=$(tailscale serve status --json)
jq -e --arg port "$port" --arg key "$hostname:$port" --arg proxy "$socket" '
  (.AllowFunnel[$key] != true) and
  (.TCP[$port] == null or (.TCP[$port] == {"HTTPS":true} and .Web[$key].Handlers == {"/":{"Proxy":$proxy}}))
' <<<"$serve_before" >/dev/null

work=$(mktemp -d "$state/.deploy.XXXXXXXX")
added_release=false
changed_serve=false
changed_unit=false
verified=false
cleanup() {
  if ! $verified; then
    if $changed_serve; then tailscale serve --bg --yes --https="$port" off >/dev/null || true; fi
    if $changed_unit; then
      if [[ -f $work/previous.service ]]; then
        mv -f "$work/previous.service" "$unit"
        systemctl --user daemon-reload && systemctl --user restart "$service.service" || true
      else
        systemctl --user disable --now "$service.service" >/dev/null 2>&1 || true
        rm -f "$unit"
        systemctl --user daemon-reload || true
      fi
    fi
    if $added_release; then rm -rf -- "$release"; fi
    jq -cn --arg service "$service" '{event:"howlong_deployment_failed", service:$service, action:"Check the deployment output and user service journal"}' >&2
  fi
  rm -rf -- "$work"
}
trap cleanup EXIT

if [[ $environment == dev ]]; then
  npm run test:howlong
  mkdir -p "$state/releases"
  release="$state/releases/$commit"
  git archive "$commit" services/howlong | gzip -n > "$work/howlong.tar.gz"
  sha=$(sha256sum "$work/howlong.tar.gz" | cut -d' ' -f1)
  if [[ -d $release ]]; then cmp "$work/howlong.tar.gz" "$release/howlong.tar.gz"; fi
fi
mkdir "$work/verified"
archive="$release/howlong.tar.gz"
if [[ -f $work/howlong.tar.gz ]]; then archive="$work/howlong.tar.gz"; fi
tar -xzf "$archive" -C "$work/verified"
if [[ -d $release ]]; then
  diff -r "$work/verified/services/howlong" "$release/services/howlong"
else
  mv "$archive" "$work/verified/howlong.tar.gz"
  mv "$work/verified" "$release"
  added_release=true
fi

cat > "$work/counter.service" <<EOF
[Unit]
Description=How Long private $environment counter
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Type=exec
ExecStart=$node_bin $release/services/howlong/run.mjs
Environment="HOWLONG_ORIGIN=$origin" "HOWLONG_OWNER=$owner"
Environment="HOWLONG_STATE=$state/counter.sqlite" "HOWLONG_SOCKET=%t/$service/server.sock"
Environment="HOWLONG_INITIAL_DATE=$HOWLONG_INITIAL_DATE" "HOWLONG_VIEW_ORIGIN=$view_origin"
RuntimeDirectory=$service
RuntimeDirectoryMode=0700
UMask=0077
NoNewPrivileges=true
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
EOF
if [[ -e $unit ]]; then cp -p "$unit" "$work/previous.service"; fi
mv -f "$work/counter.service" "$unit"
changed_unit=true
systemctl --user daemon-reload
systemctl --user enable "$service.service" >/dev/null
systemctl --user restart "$service.service"
for attempt in {1..20}; do
  if curl -fsS --max-time 2 --unix-socket "$runtime/server.sock" -H "Host: $hostname:$port" http://localhost/healthz 2>/dev/null | grep -qx 'howlong-ok'; then break; fi
  if [[ $attempt == 20 ]]; then exit 1; fi
  sleep 1
done

if jq -e --arg port "$port" '.TCP[$port] == null' <<<"$serve_before" >/dev/null; then
  tailscale serve --bg --yes --https="$port" "$socket" >/dev/null
  changed_serve=true
fi
serve_after=$(tailscale serve status --json)
strip_dev='del(.TCP[$port], .Web[$key], .AllowFunnel[$key])'
[[ $(jq -cS --arg port "$port" --arg key "$hostname:$port" "$strip_dev" <<<"$serve_before") == $(jq -cS --arg port "$port" --arg key "$hostname:$port" "$strip_dev" <<<"$serve_after") ]]
jq -e --arg key "$hostname:$port" --arg proxy "$socket" '.AllowFunnel[$key] != true and .Web[$key].Handlers["/"].Proxy == $proxy' <<<"$serve_after" >/dev/null
curl -fsS --retry 3 --max-time 10 "$origin/healthz" | grep -qx 'howlong-ok'
# Serve must replace a browser-supplied identity with the authenticated owner.
curl -fsS --max-time 10 -H 'Tailscale-User-Login: forged@example.invalid' -H 'X-Forwarded-Host: forged.example.invalid' "$origin/api/counter" \
  | jq -e '.canReset and (.start | test("^[0-9-]{10}$"))' >/dev/null
jq -n --arg commit "$commit" --arg sha "$sha" --arg origin "$origin" --arg time "$(date -u +%FT%TZ)" --arg environment "$environment" \
  '{event:"howlong_api_verified", environment:$environment, commit:$commit, sha256:$sha, url:$origin, verifiedAt:$time}' > "$work/deployment.json"
if [[ $environment == production ]]; then install -m 0600 "$approval" "$state/approval.json"; fi
mv -f "$work/deployment.json" "$state/$environment.json"
verified=true
cat "$state/$environment.json"
