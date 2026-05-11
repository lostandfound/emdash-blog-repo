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
#   ./scripts/emdash-remote.sh whoami   # actually runs `content list posts --limit 1` (see below)
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

# `emdash whoami` calls /auth/me with a fetch that ignores --header and EMDASH_HEADERS
# when EMDASH_TOKEN is set, so Cloudflare Access returns HTML ("Unexpected token '<'").
# Map whoami to a command that uses createClientFromArgs (service token headers apply).
args=("$@")
if [[ "${args[0]:-}" == "whoami" ]]; then
	args=(content list posts --limit 1 "${args[@]:1}")
fi

# Subcommand must come immediately after `emdash` (citty); global flags after the subcommand.
cmd=(npx emdash)
cmd+=("${args[@]}")
if [[ -n "${CF_ACCESS_CLIENT_ID:-}" && -n "${CF_ACCESS_CLIENT_SECRET:-}" ]]; then
	cmd+=(--header "CF-Access-Client-Id: ${CF_ACCESS_CLIENT_ID}")
	cmd+=(--header "CF-Access-Client-Secret: ${CF_ACCESS_CLIENT_SECRET}")
fi
cmd+=(--url "$ORIGIN")
exec "${cmd[@]}"
