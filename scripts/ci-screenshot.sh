#!/usr/bin/env bash
# Build is done by the caller. Launch Projects.app and capture PNGs.
set -euo pipefail

APP="${1:-}"
OUT="${2:-screenshots}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "scripts/ci-screenshot.sh only runs on macOS." >&2
  exit 1
fi

if [[ -z "$APP" || ! -d "$APP" ]]; then
  echo "usage: $0 <Projects.app> [output-dir]" >&2
  exit 2
fi

mkdir -p "$OUT"
BIN="$APP/Contents/MacOS/Projects"
if [[ ! -x "$BIN" ]]; then
  echo "no executable at $BIN" >&2
  exit 1
fi

pkill -x Projects 2>/dev/null || true
pkill -x projectd 2>/dev/null || true
sleep 1

ready="$(mktemp)"
export PROJECTS_CI_SCREENSHOT=1
export PROJECTS_CI_READY_PATH="$ready"

"$BIN" &
pid=$!

deadline=$((SECONDS + 30))
while (( SECONDS < deadline )); do
  if [[ -f "$ready" ]] && [[ "$(cat "$ready" 2>/dev/null || true)" == "ready" ]]; then
    break
  fi
  sleep 0.25
done

sleep 1

# Full desktop always works on GitHub-hosted macOS runners.
screencapture -x "$OUT/desktop.png"

# Window capture is nicer when TCC allows it.
wid="$(osascript -e 'tell application "System Events" to id of window 1 of process "Projects"' 2>/dev/null || true)"
if [[ -n "${wid:-}" ]]; then
  screencapture -x -l "$wid" "$OUT/main-window.png" || true
fi

if [[ ! -f "$OUT/main-window.png" ]]; then
  cp "$OUT/desktop.png" "$OUT/main-window.png"
fi

sips -Z 1600 "$OUT/main-window.png" >/dev/null 2>&1 || true
sips -Z 1600 "$OUT/desktop.png" >/dev/null 2>&1 || true

kill "$pid" 2>/dev/null || true
sleep 1
pkill -x Projects 2>/dev/null || true
pkill -x projectd 2>/dev/null || true

ls -la "$OUT"
test -s "$OUT/main-window.png"
