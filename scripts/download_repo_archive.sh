#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${1:-https://github.com/MohanadSamara/clinic_app}"
BRANCH="${2:-main}"
OUTPUT="${3:-clinic_app-${BRANCH}.zip}"

BASE_URL="${REPO_URL%.git}"
ARCHIVE_URL="${BASE_URL}/archive/refs/heads/${BRANCH}.zip"

echo "Downloading ${ARCHIVE_URL} -> ${OUTPUT}" >&2
curl -fL "${ARCHIVE_URL}" -o "${OUTPUT}"

echo "Archive saved to ${OUTPUT}" >&2
