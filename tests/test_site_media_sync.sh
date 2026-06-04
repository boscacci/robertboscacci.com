#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/sync_site_media.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local needle="$1"
  local haystack_file="$2"
  grep -Fq -- "$needle" "$haystack_file" || {
    printf 'Expected to find:\n%s\n\nIn:\n' "$needle" >&2
    cat "$haystack_file" >&2
    exit 1
  }
}

mkdir -p "$TMP_DIR/source/elliott-bay-vhf" "$TMP_DIR/bin"
printf 'fake jpg\n' > "$TMP_DIR/source/elliott-bay-vhf/antenna.jpg"
printf 'ignore me\n' > "$TMP_DIR/source/.DS_Store"
printf 'ignore me\n' > "$TMP_DIR/source/._antenna.jpg"
printf 'ignore me\n' > "$TMP_DIR/source/elliott-bay-vhf/._antenna.jpg"
printf 'ignore me\n' > "$TMP_DIR/source/README.md"

cat > "$TMP_DIR/bin/aws" <<'AWS'
#!/usr/bin/env bash
printf '%s ' "$@" >> "$AWS_CALL_LOG"
printf '\n' >> "$AWS_CALL_LOG"
AWS
chmod +x "$TMP_DIR/bin/aws"

export AWS_BIN="$TMP_DIR/bin/aws"
export AWS_CALL_LOG="$TMP_DIR/aws.log"
export SITE_MEDIA_BUCKET="example-bucket"
export SITE_MEDIA_BASE_URL="https://media.example.com"

"$SCRIPT" --source "$TMP_DIR/source" --dry-run --print-urls > "$TMP_DIR/output.txt"

assert_contains "s3 sync $TMP_DIR/source/ s3://example-bucket/photos/" "$TMP_DIR/aws.log"
assert_contains "--dryrun" "$TMP_DIR/aws.log"
assert_contains "--exclude .DS_Store --exclude */.DS_Store --exclude ._* --exclude */._* --exclude README.md --exclude .gitkeep" "$TMP_DIR/aws.log"
assert_contains "https://media.example.com/photos/elliott-bay-vhf/antenna.jpg" "$TMP_DIR/output.txt"

if grep -Fq '._antenna.jpg' "$TMP_DIR/output.txt"; then
  fail "print-urls should skip macOS AppleDouble sidecar files"
fi

if SITE_MEDIA_BUCKET="" "$SCRIPT" --source "$TMP_DIR/source" > "$TMP_DIR/missing-bucket.txt" 2>&1; then
  fail "sync should require SITE_MEDIA_BUCKET or --bucket"
fi

assert_contains "SITE_MEDIA_BUCKET" "$TMP_DIR/missing-bucket.txt"
