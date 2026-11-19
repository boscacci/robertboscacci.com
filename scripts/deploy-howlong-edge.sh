#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

[[ -z $(git status --porcelain) && $(hostname -s) == optiplex && $(id -u) == 1000 ]]
[[ $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
commit=$(git rev-parse HEAD)
git merge-base --is-ancestor "$commit" refs/remotes/origin/main
base="${XDG_DATA_HOME:-$HOME/.local/share}/howlong"
state="$base/production"
release="$base/dev/releases/$commit"
code="$release/services/howlong"
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
runtime="${XDG_RUNTIME_DIR:?Missing user runtime directory}/howlong-edge-aws"
host=howlong.robertboscacci.com
image=062008221187.dkr.ecr.us-west-2.amazonaws.com/robertboscacci-trips-private@sha256:4b9c47378df43d63d81a9f6dc03eab75476dbc0864c5f2e01839f95b75ac299d
sha=$(sha256sum "$release/howlong.tar.gz" | cut -d' ' -f1)
origin=$(jq -er --arg commit "$commit" --arg sha "$sha" '
  select(.commit == $commit and .sha256 == $sha) | .url | select(test("^https://[a-z0-9.-]+\\.ts\\.net:18447$"))
' "$state/production.json")
jq -e --arg host "$host" --arg sha "$sha" '.target == $host and .artifact == $sha and (.instruction | length > 0)' "$state/approval.json" >/dev/null
[[ $base =~ ^/[[:alnum:]._/-]+$ && $runtime =~ ^/[[:alnum:]._/-]+$ ]]
exec 9>"$state/edge.lock"
flock -n 9
work=$(mktemp -d "$state/.edge.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
mkdir "$work/verified"
tar -xzf "$release/howlong.tar.gz" -C "$work/verified"
diff -r "$work/verified/services/howlong" "$code"
curl -fsS --max-time 10 -D "$work/headers" -H "Origin: https://$host" "$origin/api/counter" | jq -e '.canReset' >/dev/null
grep -Fqi "access-control-allow-origin: https://$host" "$work/headers"

# This stack can change only the dedicated certificate role. Public DNS gets
# the temporary ACME TXT challenge and no address record for the service.
TF_DATA_DIR="$work/tofu" tofu -chdir=infra/howlong init -input=false -lockfile=readonly
TF_DATA_DIR="$work/tofu" tofu -chdir=infra/howlong apply -input=false -auto-approve
if ! docker image inspect "$image" >/dev/null 2>&1; then
  mkdir "$work/docker"
  aws ecr get-login-password --region us-west-2 | docker --config "$work/docker" login --username AWS --password-stdin "${image%%/*}" >/dev/null
  docker --config "$work/docker" pull "$image"
  docker --config "$work/docker" logout "${image%%/*}" >/dev/null
fi
mkdir -p "$state/caddy-data" "$state/caddy-config" "$runtime" "$units"

cat > "$work/howlong-edge.service" <<EOF
[Unit]
Description=How Long tailnet-only HTTPS edge
After=howlong-production.service
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Environment="PATH=/usr/bin:/bin:/snap/bin"
ExecStartPre=/bin/bash $code/edge-credentials.sh $runtime
ExecStart=/usr/bin/docker run --name howlong-edge --rm --pull=never --network host --user 1000:1000 --read-only --cap-drop ALL --security-opt no-new-privileges --tmpfs /tmp:size=16m,mode=1777 --env HOWLONG_API_ORIGIN=$origin --env AWS_PROFILE=howlong-dns --env AWS_CONFIG_FILE=/run/aws/config --env AWS_SHARED_CREDENTIALS_FILE=/dev/null --mount type=bind,source=$runtime,destination=/run/aws,readonly --mount type=bind,source=$state/caddy-data,destination=/data --mount type=bind,source=$state/caddy-config,destination=/config --mount type=bind,source=$code/Caddyfile,destination=/etc/caddy/Caddyfile,readonly --mount type=bind,source=$code,destination=/srv/howlong,readonly $image
ExecStop=/usr/bin/docker stop -t 5 howlong-edge
Restart=on-failure
RestartSec=5
TimeoutStartSec=40

[Install]
WantedBy=default.target
EOF
cat > "$work/howlong-edge-renew.service" <<EOF
[Unit]
Description=Refresh How Long certificate credentials
[Service]
Type=oneshot
Environment="PATH=/usr/bin:/bin:/snap/bin"
ExecStart=/bin/bash $code/edge-credentials.sh $runtime
TimeoutStartSec=40
EOF
cat > "$work/howlong-edge-renew.timer" <<'EOF'
[Unit]
Description=Keep short-lived How Long certificate credentials valid
[Timer]
OnBootSec=15m
OnUnitActiveSec=15m
[Install]
WantedBy=timers.target
EOF
for file in howlong-edge.service howlong-edge-renew.service howlong-edge-renew.timer; do
  install -m 0600 "$work/$file" "$units/$file"
done
systemctl --user daemon-reload
systemctl --user enable --now howlong-edge-renew.timer >/dev/null
systemctl --user enable howlong-edge.service >/dev/null
systemctl --user restart howlong-edge.service
for attempt in {1..30}; do
  if [[ $(curl -fsS --max-time 2 --resolve "$host:9452:127.0.0.1" "https://$host:9452/healthz" 2>/dev/null) == howlong-edge-ok ]]; then
    printf '%s\n' '{"event":"howlong_edge_verified"}'
    exit 0
  fi
  sleep 2
done
printf '%s\n' '{"event":"howlong_edge_not_ready","action":"Check the user service journal for TLS, DNS or AWS credential errors before changing ingress"}' >&2
exit 1
