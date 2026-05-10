#!/usr/bin/env bash
#
# Run EmDash CLI against the deployed Workers instance.
# Loads .env from the repo root (EMDASH_TOKEN, optional EMDASH_REMOTE_ORIGIN).
#
# Usage (from anywhere):
#   ./scripts/emdash-remote.sh content list posts
#   ./scripts/emdash-remote.sh whoami
#   ./scripts/emdash-remote.sh types --output .emdash/types-remote.ts
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if [[ ! -f .env ]]; then
	echo "emdash-remote.sh: missing .env in ${ROOT}" >&2
	exit 1
fi
set -a
# shellcheck disable=SC1091
source .env
set +a
ORIGIN="${EMDASH_REMOTE_ORIGIN:-https://emdash-blog-repo.denshoch.workers.dev}"
exec npx emdash "$@" --url "$ORIGIN"
