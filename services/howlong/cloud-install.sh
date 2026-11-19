#!/usr/bin/env bash
set -euo pipefail
umask 077

environment=${1:?environment}
image=${2:?release image}
[[ $environment == dev || $environment == production ]]
[[ $image =~ ^062008221187\.dkr\.ecr\.us-west-2\.amazonaws\.com/robertboscacci-howlong@sha256:[a-f0-9]{64}$ ]]
root=/var/lib/howlong
mountpoint -q "$root"
[[ $(aws sts get-caller-identity --query Account --output text) == 062008221187 ]]
tailstate=$(tailscale status --json)
jq -e '.BackendState == "Running" and .Self.Online' <<<"$tailstate" >/dev/null
host=$(jq -er '.Self.DNSName | rtrimstr(".") | select(test("^[a-z0-9.-]+\\.ts\\.net$"))' <<<"$tailstate")
tail_ip=$(tailscale ip -4)
[[ $tail_ip =~ ^100\.[0-9.]+$ ]]
owner=$(tailscale whois --json "$tail_ip" | jq -er '.UserProfile.LoginName | select(test("^[A-Za-z0-9._+@-]+$"))')
port=443
vanity=''
if [[ $environment == production ]]; then port=18447; vanity=https://howlong.robertboscacci.com; fi
origin="https://$host"
authority=$host
if [[ $port != 443 ]]; then authority="$host:$port"; origin="https://$authority"; fi

exec 9>/run/howlong-cloud-install.lock
flock -n 9
work=$(mktemp -d /run/howlong-install.XXXXXXXX)
container=''
cleanup() {
  if [[ -n $container ]]; then docker container rm "$container" >/dev/null || true; fi
  find "$work" -depth -delete
}
trap cleanup EXIT
database="$root/counter/counter.sqlite"
install -d -o 1000 -g 1000 -m 0700 "$root/counter"
if [[ ! -f $database ]]; then
  key=${3:?migration object}
  hash=${4:?migration checksum}
  [[ $key =~ ^migration/$environment-[a-f0-9]{40}-[a-f0-9]{12}\.sqlite$ && $hash =~ ^[a-f0-9]{64}$ ]]
  aws s3api get-object --region us-west-2 --bucket "robertboscacci-howlong-archive-$environment-062008221187" \
    --key "$key" --expected-bucket-owner 062008221187 "$work/counter.sqlite" >/dev/null
  printf '%s  %s\n' "$hash" "$work/counter.sqlite" | sha256sum --check --status
  install -o 1000 -g 1000 -m 0600 "$work/counter.sqlite" "$root/counter/counter.sqlite.next"
  mv -T "$root/counter/counter.sqlite.next" "$database"
fi

export DOCKER_CONFIG="$work/docker"
mkdir "$DOCKER_CONFIG"
registry=062008221187.dkr.ecr.us-west-2.amazonaws.com
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "$registry" >/dev/null
docker pull "$image" >/dev/null
docker image inspect "$image" --format '{{.Config.User}}' | grep -qx '1000:1000'

cat > "$work/cloud.env" <<EOF
HOWLONG_ORIGIN=$origin
HOWLONG_VIEW_ORIGIN=$vanity
HOWLONG_OWNER=$owner
HOWLONG_STATE=/state/counter.sqlite
HOWLONG_SOCKET=/run/howlong/server.sock
HOWLONG_INITIAL_DATE=2000-01-01
EOF
install -m 0600 "$work/cloud.env" "$root/cloud.env"
cat > /etc/systemd/system/howlong-cloud.service <<EOF
[Unit]
Description=Private How Long counter on AWS
After=docker.service
Requires=docker.service
RequiresMountsFor=/var/lib/howlong

[Service]
RuntimeDirectory=howlong
UMask=0077
ExecStartPre=/usr/bin/test -s $database
ExecStartPre=/usr/bin/install -d -o 1000 -g 1000 -m 0700 /run/howlong
ExecStart=/usr/bin/docker run --rm --name howlong-cloud --pull=never --network none --cap-drop ALL --security-opt no-new-privileges:true --read-only --env-file $root/cloud.env -v $root/counter:/state -v /run/howlong:/run/howlong $image
ExecStop=/usr/bin/docker stop -t 5 howlong-cloud
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

if [[ -n $vanity ]]; then
  dnf install -y dnsmasq bind-utils
  cat > "$root/dnsmasq.conf" <<EOF
bind-interfaces
listen-address=$tail_ip
no-resolv
no-hosts
cache-size=0
address=/howlong.robertboscacci.com/$tail_ip
EOF
  cat > /etc/systemd/system/howlong-cloud-dns.service <<EOF
[Unit]
Description=Tailnet-only DNS for the How Long vanity host
After=tailscaled.service
Requires=tailscaled.service
RequiresMountsFor=/var/lib/howlong

[Service]
ExecStart=/usr/sbin/dnsmasq --keep-in-foreground --conf-file=$root/dnsmasq.conf
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
  caddy="$registry/robertboscacci-trips-private@sha256:4b9c47378df43d63d81a9f6dc03eab75476dbc0864c5f2e01839f95b75ac299d"
  docker pull "$caddy" >/dev/null
  container=$(docker create "$image")
  site="$root/site-${image##*@sha256:}"
  install -d -m 0755 "$site"
  for file in index.html style.css app.mjs calendar.mjs Caddyfile; do docker cp "$container:/app/$file" "$site/$file"; done
  install -d -m 0700 -o 1000 -g 1000 "$root/caddy-data" "$root/caddy-config"
  cat > /etc/systemd/system/howlong-cloud-edge.service <<EOF
[Unit]
Description=Private How Long vanity TLS edge
After=docker.service tailscaled.service
Requires=docker.service tailscaled.service
RequiresMountsFor=/var/lib/howlong

[Service]
ExecStart=/usr/bin/docker run --rm --name howlong-cloud-edge --pull=never --network host --user 1000:1000 --cap-drop ALL --security-opt no-new-privileges:true --read-only --tmpfs /tmp:size=16m,mode=1777 -e HOWLONG_API_ORIGIN=$origin -v $root/caddy-data:/data -v $root/caddy-config:/config -v $site/Caddyfile:/etc/caddy/Caddyfile:ro -v $site:/srv/howlong:ro $caddy
ExecStop=/usr/bin/docker stop -t 5 howlong-cloud-edge
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
fi

cat > /etc/systemd/system/howlong-cloud-archive.service <<EOF
[Unit]
Description=Archive How Long timestamps to S3 and report cloud health
After=howlong-cloud.service tailscaled.service
RequiresMountsFor=/var/lib/howlong

[Service]
Type=oneshot
TimeoutStartSec=55
ExecStartPre=/usr/bin/curl -fsS --max-time 5 --resolve $host:$port:$tail_ip $origin/healthz
ExecStart=/usr/bin/docker run --rm --name howlong-cloud-archive --pull=never --network host --no-healthcheck --cap-drop ALL --security-opt no-new-privileges:true --read-only --tmpfs /tmp:uid=1000,gid=1000,mode=0700,size=8m -e HOWLONG_ARCHIVE_INSTANCE_ROLE=1 -v $root/counter:/state $image /app/archive.mjs $environment /state/counter.sqlite /tmp
EOF
if [[ -n $vanity ]]; then
  sed -i "/^ExecStart=/{i ExecStartPre=/usr/bin/curl -fsS --max-time 5 --resolve howlong.robertboscacci.com:443:$tail_ip $vanity/healthz
}" /etc/systemd/system/howlong-cloud-archive.service
fi
cat > /etc/systemd/system/howlong-cloud-archive.timer <<'EOF'
[Unit]
Description=Archive How Long resets each minute
[Timer]
OnCalendar=*-*-* *:*:00
AccuracySec=5s
Persistent=true
[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable howlong-cloud.service >/dev/null
systemctl restart howlong-cloud.service
tailscale serve --bg --yes --https="$port" unix:/run/howlong/server.sock >/dev/null
if [[ -n $vanity ]]; then
  systemctl enable howlong-cloud-edge.service >/dev/null
  systemctl restart howlong-cloud-edge.service
  tailscale serve --bg --yes --tcp=443 tcp://127.0.0.1:9452 >/dev/null
  systemctl enable howlong-cloud-dns.service >/dev/null
  systemctl restart howlong-cloud-dns.service
  [[ $(dig +short +time=3 +tries=1 "@$tail_ip" howlong.robertboscacci.com A) == "$tail_ip" ]]
fi
tailscale serve status --json | jq -e --arg port "$port" '
  ([.AllowFunnel // {} | to_entries[] | select(.value == true)] | length == 0) and .TCP[$port].HTTPS
' >/dev/null
for attempt in {1..30}; do
  if systemctl start howlong-cloud-archive.service; then break; fi
  if [[ $attempt == 30 ]]; then exit 1; fi
  sleep 3
done
systemctl enable --now howlong-cloud-archive.timer >/dev/null
jq -cn --arg url "$origin" --arg tail "$tail_ip" '{event:"howlong_cloud_ready",url:$url,tailnetAddress:$tail}'
