This is an EmDash site -- a CMS built on Astro with a full admin UI.

## Commands

```bash
npx emdash dev        # Start dev server (runs migrations, seeds, generates types)
npx emdash types      # Regenerate TypeScript types from schema
npx emdash seed seed/seed.json --validate  # Validate seed file
```

The admin UI is at `http://localhost:4321/_emdash/admin`.

## Remote CLI (production Workers)

Default site URL: `https://emdash-blog-repo.denshoch.workers.dev`  
Custom domain (when DNS is live): `https://emdash.denshochan.com` — set `EMDASH_REMOTE_ORIGIN` in `.env` for CLI against that host.  
Admin: `https://<host>/_emdash/admin`

### Auth for agents (Cursor)

- API token lives in repo-root `.env` as `EMDASH_TOKEN` (gitignored). Do **not** read `.env` into chat or paste the token into replies.
- When running CLI commands from the project, load env then call `emdash` with `--url` (or use the wrapper below).

### One-shot shell (copy-paste)

From the repo root:

```bash
cd /path/to/emdash-blog
set -a && source .env && set +a
npx emdash whoami --url https://emdash-blog-repo.denshoch.workers.dev
npx emdash content list posts --url https://emdash-blog-repo.denshoch.workers.dev
npx emdash types --url https://emdash-blog-repo.denshoch.workers.dev
```

`--token` overrides `EMDASH_TOKEN` if both are set. Resolution order is documented in the CLI (`--token`, then `EMDASH_TOKEN`, then stored `emdash login` credentials).

### Wrapper script (preferred)

```bash
./scripts/emdash-remote.sh whoami
./scripts/emdash-remote.sh content list posts
./scripts/emdash-remote.sh content get posts <ULID_OR_SLUG>
./scripts/emdash-remote.sh types --output .emdash/types-remote.ts
```

Optional `.env` entry `EMDASH_REMOTE_ORIGIN` changes the `--url` target (defaults to the Workers dev hostname above).

When the site is behind **Cloudflare Access**, the CLI may get HTML instead of JSON (`Unexpected token '<'`). Set **`CF_ACCESS_CLIENT_ID` and `CF_ACCESS_CLIENT_SECRET`** in `.env` (service token); `./scripts/emdash-remote.sh` passes them as `--header`. Do not use a single-line `EMDASH_HEADERS` with `\n` — bash will not turn that into a real newline.

Upstream quirk: `emdash whoami` does not merge those headers on the `/auth/me` request when `EMDASH_TOKEN` is set. **`./scripts/emdash-remote.sh whoami`** is rewritten to **`content list posts --limit 1`** so Access headers apply. For a true `whoami`, use `emdash login` once with `-H` to persist headers, or unset `EMDASH_TOKEN` and rely on stored credentials (narrower use case).

## Production debugging (agents)

When the deployed site returns 5xx, **confirm runtime evidence before changing theme code or content**.

1. **Scope:** `curl -o /dev/null -w '%{http_code}\n'` on `/`, `/posts`, `/404`, `/rss.xml` — separates “all routes broken” vs “one route”.
2. **Logs:** `npx wrangler tail emdash-blog-repo --format pretty` (or Cloudflare dashboard → Workers → Logs), reproduce with `curl`, read the stack trace and message.
3. **Known issues:** Search GitHub for `withastro/astro` + Cloudflare adapter / `Astro.cache`, and `emdash-cms/emdash` for CMS-specific errors — only then form a fix hypothesis.
4. **Local parity:** `npx wrangler dev --remote` can reproduce some production binding behaviour; still verify with tail on the real worker when unsure.

## Key Files

| File                     | Purpose                                                                            |
| ------------------------ | ---------------------------------------------------------------------------------- |
| `astro.config.mjs`       | Astro config with `emdash()` integration, database, and storage                    |
| `src/live.config.ts`     | EmDash loader registration (boilerplate -- don't modify)                           |
| `seed/seed.json`         | Schema definition + demo content (collections, fields, taxonomies, menus, widgets) |
| `emdash-env.d.ts`        | Generated types for collections (auto-regenerated on dev server start)             |
| `src/layouts/Base.astro` | Base layout with EmDash wiring (menus, search, page contributions)                 |
| `src/pages/`             | Astro pages -- all server-rendered                                                 |
| `scripts/emdash-remote.sh` | Loads `.env` and runs `npx emdash …` against production `--url`                  |

## Skills

Agent skills are in `.agents/skills/`. Load them when working on specific tasks:

- **building-emdash-site** -- Querying content, rendering Portable Text, schema design, seed files, site features (menus, widgets, search, SEO, comments, bylines). Start here.
- **creating-plugins** -- Building EmDash plugins with hooks, storage, admin UI, API routes, and Portable Text block types.
- **emdash-cli** -- CLI commands for content management, seeding, type generation, and visual editing flow.

## Rules

- All content pages must be server-rendered (`output: "server"`). No `getStaticPaths()` for CMS content.
- Image fields are objects (`{ src, alt }`), not strings. Use `<Image image={...} />` from `"emdash/ui"`.
- `entry.id` is the slug (for URLs). `entry.data.id` is the database ULID (for API calls like `getEntryTerms`).
- Call `applyEmDashCacheHint(Astro, cacheHint)` from `src/utils/emdash-cache-hint.ts` on pages that query content (wraps `Astro.cache.set`; on Cloudflare Workers `Astro.cache` may be undefined).
- Taxonomy names in queries must match the seed's `"name"` field exactly (e.g., `"category"` not `"categories"`).
