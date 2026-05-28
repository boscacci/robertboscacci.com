#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURL_BIN="${CURL_BIN:-curl}"
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

CONTENT_DIR="$ROOT_DIR/content"
OUTPUT_DIR="${SITE_MEDIA_MIGRATION_OUTPUT_DIR:-$ROOT_DIR/data/site-media/migrated}"
MAP_FILE="${SITE_MEDIA_MIGRATION_MAP_FILE:-$ROOT_DIR/outputs/external-media-map.tsv}"
BASE_URL="${SITE_MEDIA_BASE_URL:-}"
PREFIX="${SITE_MEDIA_PREFIX:-photos}"

usage() {
  cat <<'EOF'
Usage: scripts/download_external_media.sh [options]

Download externally hosted image files referenced by site content into the local
site media drop folder. The script writes a TSV map from original URL to the new
media URL so content can be migrated deliberately.

Options:
  --content-dir DIR   Content directory to scan. Default: content
  --output-dir DIR    Local destination. Default: data/site-media/migrated
  --map-file FILE     Replacement map path. Default: outputs/external-media-map.tsv
  --base-url URL      Public media base URL. Default: SITE_MEDIA_BASE_URL
  --prefix PREFIX     Public media prefix. Default: photos
  -h, --help          Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --content-dir)
      CONTENT_DIR="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --map-file)
      MAP_FILE="$2"
      shift 2
      ;;
    --base-url)
      BASE_URL="$2"
      shift 2
      ;;
    --prefix)
      PREFIX="$2"
      shift 2
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

if [[ -z "$BASE_URL" ]]; then
  printf 'SITE_MEDIA_BASE_URL is required for migration maps. Set it in config/site-media.env or pass --base-url.\n' >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR" "$(dirname "$MAP_FILE")"
printf 'original_url\tnew_url\tlocal_path\n' > "$MAP_FILE"

url_file="$(mktemp)"
trap 'rm -f "$url_file"' EXIT

rg --no-filename -o -N "https?://[^\"' )]+\\.(jpg|jpeg|png|webp|gif)(\\?[^\"' )]*)?" "$CONTENT_DIR" \
  | sort -u > "$url_file" || true

download_count=0
collection="$(basename "$OUTPUT_DIR")"
total_count="$(grep -c . "$url_file" | tr -d ' ')"
current_count=0

while IFS= read -r url; do
  [[ -n "$url" ]] || continue
  if [[ "$url" == "${BASE_URL%/}/"* ]]; then
    continue
  fi
  current_count=$((current_count + 1))

  url_without_scheme="${url#*://}"
  host="${url_without_scheme%%/*}"
  clean_url="${url%%\?*}"
  filename="${clean_url##*/}"
  filename="${filename//[^A-Za-z0-9._-]/-}"
  hash="$(printf '%s' "$url" | shasum -a 1 | awk '{print substr($1, 1, 12)}')"

  target_dir="$OUTPUT_DIR/$host"
  target="$target_dir/$hash-$filename"
  mkdir -p "$target_dir"

  if [[ ! -f "$target" ]]; then
    printf '[%s/%s] Downloading %s\n' "$current_count" "$total_count" "$url" >&2
    "$CURL_BIN" -fsSL --retry 3 -o "$target" "$url"
    download_count=$((download_count + 1))
  else
    printf '[%s/%s] Already downloaded %s\n' "$current_count" "$total_count" "$url" >&2
  fi

  relative="$collection/$host/$hash-$filename"
  if [[ -n "$PREFIX" ]]; then
    new_url="${BASE_URL%/}/$PREFIX/$relative"
  else
    new_url="${BASE_URL%/}/$relative"
  fi

  printf '%s\t%s\t%s\n' "$url" "$new_url" "$target" >> "$MAP_FILE"
done < "$url_file"

printf 'Downloaded %s external media files\n' "$download_count"
printf 'Map written to %s\n' "$MAP_FILE"
