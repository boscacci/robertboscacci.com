#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/install_site_media_watcher.sh"
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

"$SCRIPT" --plist-dir "$TMP_DIR" --interval 123 --no-load > "$TMP_DIR/output.txt"

PLIST="$TMP_DIR/com.robertboscacci.site-media-sync.plist"
[[ -f "$PLIST" ]] || {
  printf 'Expected plist at %s\n' "$PLIST" >&2
  exit 1
}

assert_contains "$ROOT_DIR/scripts/sync_site_media.sh" "$PLIST"
assert_contains "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" "$PLIST"
assert_contains "<integer>123</integer>" "$PLIST"
assert_contains "Wrote $PLIST" "$TMP_DIR/output.txt"
