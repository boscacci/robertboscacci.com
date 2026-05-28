#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AWS_BIN="${AWS_BIN:-aws}"
ENV_FILE="${SITE_MEDIA_ENV_FILE:-$ROOT_DIR/config/site-media.env}"

if [[ -f "$ENV_FILE" ]]; then
  while IFS='=' read -r key value; do
    [[ -n "$key" && ! "$key" =~ ^[[:space:]]*# ]] || continue
    key="${key%%[[:space:]]*}"
    if [[ -z "${!key+x}" ]]; then
      export "$key=$value"
    fi
  done < "$ENV_FILE"
fi

SOURCE_DIR="${SITE_MEDIA_SOURCE:-$ROOT_DIR/data/site-media}"
BUCKET="${SITE_MEDIA_BUCKET:-}"
PREFIX="${SITE_MEDIA_PREFIX:-photos}"
BASE_URL="${SITE_MEDIA_BASE_URL:-}"
WATCH_INTERVAL_SECONDS="${SITE_MEDIA_WATCH_INTERVAL_SECONDS:-300}"
DRY_RUN=0
DELETE_REMOTE=0
PRINT_URLS=0
WATCH=0

usage() {
  cat <<'EOF'
Usage: scripts/sync_site_media.sh [options]

Sync local, gitignored site media files to the configured S3 media bucket.

Options:
  --source DIR       Local media drop folder. Default: data/site-media
  --bucket NAME      S3 bucket name. Default: SITE_MEDIA_BUCKET
  --prefix PREFIX    S3 key prefix. Default: photos
  --base-url URL     Public base URL for printed links. Default: SITE_MEDIA_BASE_URL
  --dry-run          Show the AWS CLI sync actions without uploading
  --delete           Delete remote objects missing locally
  --print-urls       Print public URLs for local files after sync
  --watch            Repeat the sync every SITE_MEDIA_WATCH_INTERVAL_SECONDS
  -h, --help         Show this help

Configuration can also live in config/site-media.env.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --bucket)
      BUCKET="$2"
      shift 2
      ;;
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    --base-url)
      BASE_URL="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --delete)
      DELETE_REMOTE=1
      shift
      ;;
    --print-urls)
      PRINT_URLS=1
      shift
      ;;
    --watch)
      WATCH=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

PREFIX="${PREFIX#/}"
PREFIX="${PREFIX%/}"

require_config() {
  if [[ -z "$BUCKET" ]]; then
    printf 'SITE_MEDIA_BUCKET is required. Set it in config/site-media.env or pass --bucket.\n' >&2
    exit 2
  fi
}

sync_once() {
  require_config
  mkdir -p "$SOURCE_DIR"

  local destination="s3://$BUCKET/"
  if [[ -n "$PREFIX" ]]; then
    destination="s3://$BUCKET/$PREFIX/"
  fi

  local args=(
    s3 sync
    "$SOURCE_DIR/"
    "$destination"
    --exclude ".DS_Store"
    --exclude "*/.DS_Store"
    --exclude "README.md"
    --exclude ".gitkeep"
  )

  if [[ "$DRY_RUN" -eq 1 ]]; then
    args+=(--dryrun)
  fi

  if [[ "$DELETE_REMOTE" -eq 1 ]]; then
    args+=(--delete)
  fi

  "$AWS_BIN" "${args[@]}"

  if [[ "$PRINT_URLS" -eq 1 ]]; then
    print_urls
  fi
}

public_base_url() {
  if [[ -n "$BASE_URL" ]]; then
    printf '%s' "${BASE_URL%/}"
    return
  fi

  local region
  region="$("$AWS_BIN" configure get region 2>/dev/null || true)"
  region="${region:-us-west-2}"
  printf 'https://%s.s3.%s.amazonaws.com' "$BUCKET" "$region"
}

print_urls() {
  local base
  base="$(public_base_url)"

  find "$SOURCE_DIR" -type f \
    ! -name '.DS_Store' \
    ! -name 'README.md' \
    ! -name '.gitkeep' \
    -print | sort | while IFS= read -r path; do
      local relative="${path#"$SOURCE_DIR"/}"
      if [[ -n "$PREFIX" ]]; then
        printf '%s/%s/%s\n' "$base" "$PREFIX" "$relative"
      else
        printf '%s/%s\n' "$base" "$relative"
      fi
    done
}

if [[ "$WATCH" -eq 1 ]]; then
  while true; do
    date '+[%Y-%m-%dT%H:%M:%S%z] syncing site media'
    sync_once
    sleep "$WATCH_INTERVAL_SECONDS"
  done
else
  sync_once
fi
