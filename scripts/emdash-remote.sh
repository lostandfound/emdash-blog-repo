#!/usr/bin/env bash
#
# Run EmDash CLI against the deployed Workers instance.
# Loads .env from the repo root (EMDASH_TOKEN, optional EMDASH_REMOTE_ORIGIN).
#
# Cloudflare Access (Zero Trust): if the site returns HTML login pages to the
# API, set CF_ACCESS_CLIENT_ID and CF_ACCESS_CLIENT_SECRET in .env (service token).
# Alternatively use EMDASH_HEADERS with real newlines between "Name: Value" lines
# (a single line with \n will not work — bash does not expand \n in .env).
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

# Subcommand must come immediately after `emdash` (citty); --header before whoami is parsed as the command name.
cmd=(npx emdash)
cmd+=("$@")
if [[ -n "${CF_ACCESS_CLIENT_ID:-}" && -n "${CF_ACCESS_CLIENT_SECRET:-}" ]]; then
	cmd+=(--header "CF-Access-Client-Id: ${CF_ACCESS_CLIENT_ID}")
	cmd+=(--header "CF-Access-Client-Secret: ${CF_ACCESS_CLIENT_SECRET}")
fi
cmd+=(--url "$ORIGIN")
exec "${cmd[@]}"
