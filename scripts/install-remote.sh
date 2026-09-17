#!/usr/bin/env bash
# Copy projectd plus a launchd/systemd unit onto a remote host (M2).
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/install-remote.sh <ssh-host>

Scaffold only. M2 implements:
  1. scp the projectd binary
  2. install a launchd or systemd unit for --role agent
  3. stream machine.install.progress events back to control

Until then this script refuses to run so a half-installed host is not left behind.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -eq 0 ]]; then
  usage
  exit 0
fi

echo "scripts/install-remote.sh: not implemented until M2 (see SPEC.md)." >&2
echo "refusing to copy a scaffold binary to ${1}" >&2
exit 1
