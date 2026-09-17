#!/usr/bin/env bash
# Run on a machine where `gh` is logged in as RyanStoffel.
# Creates the public personal repo and pushes main + develop.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v gh >/dev/null; then
  echo "install GitHub CLI: https://cli.github.com/" >&2
  exit 1
fi

login="$(gh api user --jq .login)"
if [[ "$login" != "RyanStoffel" ]]; then
  echo "refusing to create: authenticated as ${login}, expected RyanStoffel" >&2
  exit 1
fi

if gh repo view RyanStoffel/projectd >/dev/null 2>&1; then
  echo "RyanStoffel/projectd already exists"
else
  gh repo create projectd \
    --public \
    --description "Native macOS SwiftUI client plus a Rust daemon for coordinator-and-subagent project workflows." \
    --disable-wiki \
    --disable-issues=false
fi

git remote remove github 2>/dev/null || true
git remote add github "https://github.com/RyanStoffel/projectd.git"

branch="$(git rev-parse --abbrev-ref HEAD)"
git push -u github "${branch}:main"
git push github "${branch}:develop"

echo "created https://github.com/RyanStoffel/projectd"
echo "default working branches: main and develop (both at this scaffold)"
echo "next: file spec issues, then Settings > Branches for protection (docs/maintainer-setup.md)"
