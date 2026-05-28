#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/apply_external_media_map.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/content"
cat > "$TMP_DIR/content/example.md" <<'MD'
thumbnailUrl: "https://cdn.example.com/photo.jpg"
<img src="https://cdn.example.com/photo.jpg" alt="example">
MD

cat > "$TMP_DIR/map.tsv" <<'TSV'
original_url	new_url	local_path
https://cdn.example.com/photo.jpg	https://media.example.com/photos/migrated/cdn.example.com/hash-photo.jpg	/tmp/hash-photo.jpg
TSV

"$SCRIPT" --content-dir "$TMP_DIR/content" --map-file "$TMP_DIR/map.tsv" > "$TMP_DIR/output.txt"

grep -Fq 'https://media.example.com/photos/migrated/cdn.example.com/hash-photo.jpg' "$TMP_DIR/content/example.md"
! grep -Fq 'https://cdn.example.com/photo.jpg' "$TMP_DIR/content/example.md"
grep -Fq 'Replaced 2 URL occurrence(s)' "$TMP_DIR/output.txt"
