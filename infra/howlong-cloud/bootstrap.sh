#!/usr/bin/env bash
set -euo pipefail
umask 077

dnf install -y docker jq
systemctl enable --now docker

target=/var/lib/howlong
serial=$(printf '%s' '${volume_id}' | tr -d '-')
device=''
for attempt in {1..60}; do
  device=$(lsblk -dn -o PATH,SERIAL | awk -v serial="$serial" '$2 == serial {print $1}')
  if [[ -b $device ]]; then break; fi
  sleep 3
done
[[ -b $device ]]
if [[ -z $(lsblk -dn -o FSTYPE "$device") ]]; then
  [[ $(lsblk -n -o PATH "$device") == "$device" ]]
  [[ -z $(wipefs --noheadings "$device") ]]
  mkfs.ext4 "$device"
fi
uuid=$(blkid -s UUID -o value "$device")
[[ -n $uuid ]]
install -d -m 0700 "$target"
if ! grep -Fq "UUID=$uuid $target " /etc/fstab; then
  printf 'UUID=%s %s ext4 defaults,nofail,nodev,nosuid 0 2\n' "$uuid" "$target" >> /etc/fstab
fi
mountpoint -q "$target" || mount "$target"
chmod 0700 "$target"
printf '%s\n' '{"event":"howlong_cloud_host_ready"}'
