#!/usr/bin/env bash
set -euo pipefail

branch="${1:-}"
branch="${branch#refs/heads/}"

if [[ -z "$branch" ]]; then
  echo "usage: $0 <branch-name>" >&2
  exit 2
fi

if [[ "$branch" == "develop" || "$branch" == "main" ]]; then
  exit 0
fi

if [[ "$branch" =~ ^dependabot/ ]]; then
  exit 0
fi

# CI publishes screenshots on an orphan branch per pull request.
if [[ "$branch" =~ ^ci/pr-[0-9]+-screenshots$ ]]; then
  exit 0
fi

# Cursor cloud workers wrap the real name and append a short id.
if [[ "$branch" =~ ^cursor/[a-z]+-[0-9]+-[a-z0-9-]+-[a-z0-9]{4}$ ]]; then
  exit 0
fi

# type/<issue-number>-<short-name>
if [[ "$branch" =~ ^[a-z]+/[0-9]+-[a-z0-9][a-z0-9-]*$ ]]; then
  exit 0
fi

# Optional GH- / GITHUB- prefix some tools insert before the issue number.
if [[ "$branch" =~ ^[a-z]+/(GH|GITHUB)-[0-9]+-[a-z0-9][a-z0-9-]*$ ]]; then
  exit 0
fi

cat >&2 <<EOF
Invalid branch name: ${branch}

Required format:
  <type>/<issue-number>-<short-name>

Examples:
  feature/12-json-rpc-server
  bug/34-socket-hang
  hotfix/56-ci-signing
  chore/78-gitignore
  docs/90-readme

Also allowed: main, develop, dependabot/*, ci/pr-<n>-screenshots,
cursor/<type>-<issue>-<slug>-<id>
EOF
exit 1
