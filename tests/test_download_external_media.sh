#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/download_external_media.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

assert_contains() {
  local needle="$1"
  local haystack_file="$2"
  grep -Fq -- "$needle" "$haystack_file" || {
    printf 'Expected to find:\n%s\n\nIn:\n' "$needle" >&2
    cat "$haystack_file" >&2
    exit 1
  }
}

mkdir -p "$TMP_DIR/content/projects/example" "$TMP_DIR/bin"
cat > "$TMP_DIR/content/projects/example/index.md" <<'MD'
![Example](https://cdn.example.com/photos/test-image.jpg)
<img src="https://cdn.example.com/photos/test-image.jpg" alt="duplicate">
<img src="https://other.example.org/assets/diagram.png" alt="diagram">
<img src="https://media.example.com/photos/already-migrated.jpg" alt="already migrated">
MD

cat > "$TMP_DIR/bin/curl" <<'CURL'
#!/usr/bin/env bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      output="$2"
      shift 2
      ;;
    http*)
      url="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done
printf '%s\n' "$url" > "$output"
CURL
chmod +x "$TMP_DIR/bin/curl"

export CURL_BIN="$TMP_DIR/bin/curl"
export SITE_MEDIA_BASE_URL="https://media.example.com"
export SITE_MEDIA_PREFIX="photos"

"$SCRIPT" \
  --content-dir "$TMP_DIR/content" \
  --output-dir "$TMP_DIR/media/migrated" \
  --map-file "$TMP_DIR/map.tsv" \
  > "$TMP_DIR/output.txt"

jpg_count="$(find "$TMP_DIR/media/migrated" -name '*test-image.jpg' | wc -l | tr -d ' ')"
png_count="$(find "$TMP_DIR/media/migrated" -name '*diagram.png' | wc -l | tr -d ' ')"

[[ "$jpg_count" = "1" ]] || {
  printf 'Expected one downloaded jpg, found %s\n' "$jpg_count" >&2
  exit 1
}

[[ "$png_count" = "1" ]] || {
  printf 'Expected one downloaded png, found %s\n' "$png_count" >&2
  exit 1
}

assert_contains "https://cdn.example.com/photos/test-image.jpg" "$TMP_DIR/map.tsv"
assert_contains "https://media.example.com/photos/migrated/cdn.example.com/" "$TMP_DIR/map.tsv"
! grep -Fq "already-migrated.jpg" "$TMP_DIR/map.tsv"
assert_contains "Downloaded 2 external media files" "$TMP_DIR/output.txt"
