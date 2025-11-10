#!/usr/bin/env bash
set -euo pipefail

REMOTE_URL="${1:-https://github.com/MohanadSamara/clinic_app.git}"
BRANCH="${2:-work}"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  :
else
  echo "This script must be run inside a Git repository." >&2
  exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

echo "Pushing branch '$BRANCH' to $REMOTE_URL..."
git push -u origin "$BRANCH"
