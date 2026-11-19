#!/usr/bin/env bash
set -euo pipefail
umask 077

directory=${1:?Pass the certificate runtime directory}
mkdir -p -m 0700 "$directory"
work=$(mktemp -d "$directory/.refresh.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
exec 9>"$directory/refresh.lock"
flock 9
set +x
if ! aws sts assume-role --role-arn arn:aws:iam::062008221187:role/robertboscacci-howlong-certificates \
  --role-session-name howlong-dns --duration-seconds 3600 --output json --cli-connect-timeout 5 --cli-read-timeout 10 \
  | jq -e '.Credentials + {Version:1} | select(.AccessKeyId and .SecretAccessKey and .SessionToken and .Expiration)' > "$work/credentials.json"; then
  printf '%s\n' '{"event":"howlong_certificate_credentials_failed","action":"Check the scoped AWS role and OptiPlex AWS login"}' >&2
  exit 1
fi
printf '%s\n' '[profile howlong-dns]' 'credential_process = /bin/cat /run/aws/credentials.json' > "$work/config"
mv -f "$work/config" "$directory/config"
mv -f "$work/credentials.json" "$directory/credentials.json"
printf '%s\n' '{"event":"howlong_certificate_credentials_refreshed"}'
