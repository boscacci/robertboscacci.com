#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLIST_DIR="$HOME/Library/LaunchAgents"
LABEL="com.robertboscacci.site-media-sync"
INTERVAL_SECONDS="${SITE_MEDIA_WATCH_INTERVAL_SECONDS:-300}"
LOAD_AGENT=1

usage() {
  cat <<'EOF'
Usage: scripts/install_site_media_watcher.sh [options]

Install a macOS LaunchAgent that runs scripts/sync_site_media.sh on a fixed
interval. The sync script reads config/site-media.env.

Options:
  --plist-dir DIR  LaunchAgent directory. Default: ~/Library/LaunchAgents
  --interval SEC   Sync interval in seconds. Default: 300
  --no-load        Write the plist without loading it
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plist-dir)
      PLIST_DIR="$2"
      shift 2
      ;;
    --interval)
      INTERVAL_SECONDS="$2"
      shift 2
      ;;
    --no-load)
      LOAD_AGENT=0
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

case "$INTERVAL_SECONDS" in
  ''|*[!0-9]*)
    printf 'Interval must be a positive integer number of seconds.\n' >&2
    exit 2
    ;;
esac

mkdir -p "$PLIST_DIR" "$HOME/Library/Logs"

PLIST="$PLIST_DIR/$LABEL.plist"
SYNC_SCRIPT="$ROOT_DIR/scripts/sync_site_media.sh"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SYNC_SCRIPT</string>
    <string>--print-urls</string>
  </array>

  <key>WorkingDirectory</key>
  <string>$ROOT_DIR</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>

  <key>RunAtLoad</key>
  <true/>

  <key>StartInterval</key>
  <integer>$INTERVAL_SECONDS</integer>

  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/robertboscacci-site-media-sync.log</string>

  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/robertboscacci-site-media-sync.err.log</string>
</dict>
</plist>
EOF

printf 'Wrote %s\n' "$PLIST"

if [[ "$LOAD_AGENT" -eq 1 ]]; then
  launchctl unload "$PLIST" >/dev/null 2>&1 || true
  launchctl load -w "$PLIST"
  printf 'Loaded %s\n' "$LABEL"
fi
