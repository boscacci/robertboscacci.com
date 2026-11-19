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
host=howlong.robertboscacci.com
if [[ $environment == dev ]]; then host=howlong-dev.robertboscacci.com; fi

exec 9>/run/howlong-cloud-install.lock
flock -n 9
work=$(mktemp -d /run/howlong-install.XXXXXXXX)
container=''
cleanup() {
  if [[ -n $container ]]; then docker container rm "$container" >/dev/null || true; fi
  find "$work" -depth -delete
}
trap cleanup EXIT

export DOCKER_CONFIG="$work/docker"
mkdir "$DOCKER_CONFIG"
registry=062008221187.dkr.ecr.us-west-2.amazonaws.com
caddy="$registry/robertboscacci-trips-private@sha256:4b9c47378df43d63d81a9f6dc03eab75476dbc0864c5f2e01839f95b75ac299d"
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "$registry" >/dev/null
docker pull "$image" >/dev/null
docker pull "$caddy" >/dev/null
docker image inspect "$image" --format '{{.Config.User}}' | grep -qx '1000:1000'
container=$(docker create "$caddy")
docker cp "$container:/usr/bin/caddy" "$work/caddy"
docker container rm "$container" >/dev/null
container=$(docker create "$image")
docker cp "$container:/app/CloudCaddyfile" "$work/Caddyfile"
install -m 0755 "$work/caddy" /usr/local/bin/howlong-caddy
install -m 0600 "$work/Caddyfile" "$root/CloudCaddyfile"
install -d -m 0700 -o 1000 -g 1000 "$root/caddy-data" "$root/caddy-config"
password_hash=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id "howlong/cloud/$environment/web-login" \
  --query SecretString --output text | /usr/local/bin/howlong-caddy hash-password --bcrypt-cost 10)
[[ $password_hash =~ ^\$2[aby]\$10\$[./A-Za-z0-9]{53}$ ]]
printf 'HOWLONG_HOST=%s\nHOWLONG_PASSWORD_HASH=%s\n' "$host" "$password_hash" > "$work/edge.env"
install -m 0600 "$work/edge.env" "$root/edge.env"

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

cat > "$work/cloud.env" <<EOF
HOWLONG_ORIGIN=https://$host
HOWLONG_AUTH=cloud-proxy
HOWLONG_OWNER=owner
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
cat > /etc/systemd/system/howlong-cloud-edge.service <<EOF
[Unit]
Description=Password-protected How Long HTTPS edge
After=network-online.target howlong-cloud.service
Requires=howlong-cloud.service
RequiresMountsFor=/var/lib/howlong
[Service]
User=1000
Group=1000
EnvironmentFile=$root/edge.env
Environment=XDG_DATA_HOME=$root/caddy-data XDG_CONFIG_HOME=$root/caddy-config
ExecStart=/usr/local/bin/howlong-caddy run --config $root/CloudCaddyfile --adapter caddyfile
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
UMask=0077
Restart=on-failure
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
# The edge user needs to traverse the mounted volume but cannot list it or read the root-only environment files.
chmod 0711 "$root"
chown 1000:1000 "$root/CloudCaddyfile"

cat > "$work/check.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
[[ \$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 --resolve $host:443:127.0.0.1 https://$host/) == 401 ]]
docker exec howlong-cloud node /app/cloud-health.mjs
EOF
install -m 0700 "$work/check.sh" /usr/local/bin/howlong-cloud-check
cat > /etc/systemd/system/howlong-cloud-archive.service <<EOF
[Unit]
Description=Archive How Long timestamps to S3 and report cloud health
After=howlong-cloud.service howlong-cloud-edge.service
RequiresMountsFor=/var/lib/howlong
[Service]
Type=oneshot
TimeoutStartSec=55
ExecStartPre=/usr/local/bin/howlong-cloud-check
ExecStart=/usr/bin/docker run --rm --name howlong-cloud-archive --pull=never --network host --no-healthcheck --cap-drop ALL --security-opt no-new-privileges:true --read-only --tmpfs /tmp:uid=1000,gid=1000,mode=0700,size=8m -e HOWLONG_ARCHIVE_INSTANCE_ROLE=1 -v $root/counter:/state $image /app/archive.mjs $environment /state/counter.sqlite /tmp
EOF
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

if systemctl cat tailscaled.service >/dev/null 2>&1; then systemctl disable --now tailscaled.service; fi
systemctl daemon-reload
systemctl enable howlong-cloud.service howlong-cloud-edge.service >/dev/null
systemctl restart howlong-cloud.service howlong-cloud-edge.service
for attempt in {1..30}; do
  if /usr/local/bin/howlong-cloud-check 2>/dev/null; then break; fi
  if [[ $attempt == 30 ]]; then exit 1; fi
  sleep 3
done
systemctl start howlong-cloud-archive.service
systemctl enable --now howlong-cloud-archive.timer >/dev/null
jq -cn --arg url "https://$host" '{event:"howlong_cloud_ready",url:$url}'
