#!/usr/bin/env bash
# Push this tree to the existing personal GitHub repo (requires `gh` as RyanStoffel).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REPO="RyanStoffel/cursor-projects-clone"
URL="https://github.com/${REPO}.git"

if ! command -v gh >/dev/null; then
  echo "install GitHub CLI: https://cli.github.com/" >&2
  exit 1
fi

login="$(gh api user --jq .login)"
if [[ "$login" != "RyanStoffel" ]]; then
  echo "refusing to push: authenticated as ${login}, expected RyanStoffel" >&2
  exit 1
fi

if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "missing ${REPO}. Create it on the personal account, not an organization." >&2
  exit 1
fi

git remote remove github 2>/dev/null || true
git remote add github "$URL"

branch="$(git rev-parse --abbrev-ref HEAD)"
git push -u github "${branch}:main"
git push github "${branch}:develop"

echo "pushed https://github.com/${REPO}"
echo "branches: main and develop"
echo "next: docs/maintainer-setup.md (branch protection, Actions write, signing)"
