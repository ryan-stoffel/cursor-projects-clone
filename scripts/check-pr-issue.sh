#!/usr/bin/env bash
# Fail unless the pull request links a GitHub issue by number.
set -euo pipefail

body="${PR_BODY:-}"
title="${PR_TITLE:-}"
branch="${PR_BRANCH:-}"

combined="${title}"$'\n'"${body}"$'\n'"${branch}"

if [[ "${combined}" =~ (Closes|closes|Fixes|fixes|Resolves|resolves)[[:space:]]+#([0-9]+) ]]; then
  echo "Linked issue #${BASH_REMATCH[2]} via keyword in title or body."
  exit 0
fi

if [[ "${combined}" =~ github\.com/[^/]+/[^/]+/issues/([0-9]+) ]]; then
  echo "Linked issue #${BASH_REMATCH[1]} via URL."
  exit 0
fi

if [[ "${combined}" =~ \#([0-9]+) ]]; then
  echo "Linked issue #${BASH_REMATCH[1]} via hash reference."
  exit 0
fi

if [[ "${branch}" =~ /([0-9]+)- ]]; then
  echo "error: branch contains issue ${BASH_REMATCH[1]} but the PR title/body does not link it." >&2
  echo "Add 'Closes #${BASH_REMATCH[1]}' to the PR body." >&2
  exit 1
fi

cat >&2 <<EOF
error: pull request does not link a GitHub issue.

The PR title or body must contain one of:
  Closes #N
  Fixes #N
  Resolves #N
  a github.com/<owner>/<repo>/issues/N URL
EOF
exit 1
