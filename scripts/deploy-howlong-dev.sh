#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

test -z "$(git status --porcelain)" || { echo 'Deploy from a clean, reviewed commit.' >&2; exit 1; }
[[ $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
[[ $(hostname -s) == optiplex ]]
[[ $(id -u) != 0 ]]
[[ ${HOWLONG_INITIAL_DATE:-} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]

state="${XDG_DATA_HOME:-$HOME/.local/share}/howlong/dev"
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
runtime="${XDG_RUNTIME_DIR:?Missing user runtime directory}/howlong-dev"
unit="$units/howlong-dev.service"
port=18446
socket="unix:$runtime/server.sock"
mkdir -p "$state/releases" "$units"
exec 9>"$state/deploy.lock"
flock -n 9

node_bin=$(readlink -f "$(command -v node)")
[[ $node_bin =~ ^/[[:alnum:]._/-]+$ && $state =~ ^/[[:alnum:]._/-]+$ ]]
commit=$(git rev-parse HEAD)
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
release="$state/releases/$commit"
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
        systemctl --user daemon-reload && systemctl --user restart howlong-dev.service || true
      else
        systemctl --user disable --now howlong-dev.service >/dev/null 2>&1 || true
        rm -f "$unit"
        systemctl --user daemon-reload || true
      fi
    fi
    if $added_release; then rm -rf -- "$release"; fi
    printf '%s\n' '{"event":"howlong_dev_failed","action":"Inspect the deployment output and journalctl --user -u howlong-dev.service"}' >&2
  fi
  rm -rf -- "$work"
}
trap cleanup EXIT

npm run test:howlong
git archive "$commit" services/howlong | gzip -n > "$work/howlong.tar.gz"
sha=$(sha256sum "$work/howlong.tar.gz" | cut -d' ' -f1)
if [[ -d $release ]]; then
  cmp "$work/howlong.tar.gz" "$release/howlong.tar.gz"
  mkdir "$work/verified"
  tar -xzf "$work/howlong.tar.gz" -C "$work/verified"
  diff -r "$work/verified/services/howlong" "$release/services/howlong"
else
  mkdir "$work/release"
  tar -xzf "$work/howlong.tar.gz" -C "$work/release"
  mv "$work/howlong.tar.gz" "$work/release/"
  mv "$work/release" "$release"
  added_release=true
fi

cat > "$work/howlong-dev.service" <<EOF
[Unit]
Description=How Long private development counter
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Type=exec
ExecStart=$node_bin $release/services/howlong/run.mjs
Environment="HOWLONG_ORIGIN=$origin" "HOWLONG_OWNER=$owner"
Environment="HOWLONG_STATE=$state/counter.sqlite" "HOWLONG_SOCKET=%t/howlong-dev/server.sock"
Environment="HOWLONG_INITIAL_DATE=$HOWLONG_INITIAL_DATE"
RuntimeDirectory=howlong-dev
RuntimeDirectoryMode=0700
UMask=0077
NoNewPrivileges=true
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
EOF
if [[ -e $unit ]]; then cp -p "$unit" "$work/previous.service"; fi
mv -f "$work/howlong-dev.service" "$unit"
changed_unit=true
systemctl --user daemon-reload
systemctl --user enable howlong-dev.service >/dev/null
systemctl --user restart howlong-dev.service
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
jq -n --arg commit "$commit" --arg sha "$sha" --arg origin "$origin" --arg time "$(date -u +%FT%TZ)" \
  '{event:"howlong_dev_verified", commit:$commit, sha256:$sha, url:$origin, verifiedAt:$time}' > "$work/dev.json"
mv -f "$work/dev.json" "$state/dev.json"
verified=true
cat "$state/dev.json"
