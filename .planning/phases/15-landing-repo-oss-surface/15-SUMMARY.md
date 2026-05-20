---
phase: 15-landing-repo-oss-surface
plan-coverage: [15-01, 15-02]
subsystem: landing-repo-oss-surface
tags: [phase-rollup, landing-repo, oss-surface, license, readme, audit, deletions, gitignore, lemonsqueezy, resend, vercel-kv]

requirements_addressed: [LAND-01, LAND-02, LAND-03, LAND-04, LAND-05]

requires:
  - phase: 13-app-de-commercialization
    provides: "app-side trial strip (APP-01..15) + UpdateChecker GitHub Releases repoint — leaves wrangle-landing's /api/trial/* and /api/version.json.ts with zero remaining clients, justifying their deletion in Plan 01 (D-07)"
provides:
  - "wrangle-landing repo working tree free of private agent notes, dead paid-product API endpoints, paid-product page artifacts, and the Astro build cache"
  - "Layout.astro default meta description neutralized — no `$19 one-time.` reference"
  - "MIT LICENSE at repo root attributed to `Copyright (c) 2026 J Krush` — symmetric with Phase 14's planned app-repo LICENSE"
  - "Public-facing README.md per D-14's 4-section minimal structure; two D-15 link-backs to github.com/J-Krush/wrangle; D-12 RESEND_API_KEY warning documented; D-16 License footer"
  - ".gitignore hardened: `.astro/` appended; 6 prior entries (node_modules, .env*, .DS_Store, dist/*, .vercel, *.pem) preserved verbatim"
  - "Full D-11 audit (working tree + 23-commit history) — zero category-(d) actual secret values; every surviving hit categorised; audit artifact (15-01-AUDIT.md) committed to planning host per D-10"
  - "D-09 history posture confirmed: no `git filter-repo`, no `git push --force`; lineage preserves the honest 'shipped paid, flipped OSS' portfolio story"
  - "D-12 clean-checkout verification proven: a fresh /tmp clone with NO `.env` file boots `pnpm dev` cleanly on http://localhost:4321/"

affects:
  - 16-* (Phase 16 REL-01..06 — signed-DMG release pipeline; parallel-eligible with Phase 15, no inter-dependencies)
  - 17-* (Phase 17 SITE-01..10 — landing page repositioning; will rewrite astro.config.mjs `/buy` redirect — Plan 01 audit catalogues it as category-(b); will also reposition `src/data/use-cases.json` + `src/pages/compare/*.astro` pricing copy — Plan 01 audit catalogues as category-(c))
  - 18-* (Phase 18 FLIP-03 — public flip of wrangle-landing; D-09 stands so this phase clears the credential-exposure gate; FLIP-03 blocked only on Phase 17 completion)

tech-stack:
  added: []
  patterns:
    - "Atomic per-logical-change commits — 8 atomic commits across the 2 plans (6 from Plan 01 + 2 from Plan 02 in Landing Page repo) + 2 commits in planning host (per-plan SUMMARY for Plan 01 + combined audit/phase-SUMMARY for Plan 02)"
    - "D-11 forbidden-string audit pattern — working tree (96 hits / 12 files) + full history grep (1971 raw / 236 unique tuples across 23 commits); every hit categorised into (a) env-var name / package-name substring, (b) public-URL artifact, (c) historical pricing copy, (d) actual secret value (must be zero)"
    - "Cross-repo execution boundary — Landing Page repo receives code commits, planning host repo holds audit artifact + per-plan SUMMARYs + phase-rollup SUMMARY"
    - "Pre-flight audit gate — Plan 02 reads Plan 01's audit artifact before any LICENSE/README write; halts if `DEVIATION: SECRET VALUE FOUND` present, proceeds if `D-09 stands` present"
    - "Clean-checkout verification — /tmp clone with no env vars proves the public-facing dev story; macOS `timeout`-substitute pattern (background-PID + sleep + kill) used because GNU coreutils not on PATH"
    - "Plan-internal-inconsistency handling — when a plan's `<acceptance_criteria>` contradicts its own `<must_haves>`, invoke the audit's catalogue-every-remaining-hit escape valve and document. (Surfaced once in Plan 01 for astro.config.mjs:17 LemonSqueezy URL.)"

key-files:
  created:
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/LICENSE (canonical SPDX MIT, 21 lines, attributed to J Krush — Plan 02 T1)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-01-AUDIT.md (D-11 audit working artifact — Plan 01 T3 created uncommitted, Plan 02 T3 commits)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-01-SUMMARY.md (per-plan SUMMARY — Plan 01)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-02-SUMMARY.md (per-plan SUMMARY — Plan 02)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-SUMMARY.md (this file — phase-rollup)"
  modified:
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/README.md (rewritten to D-14 4-section public-facing — Plan 02 T2)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/layouts/Layout.astro ($19 one-time. sentence dropped — Plan 01 T2 Edit A)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.gitignore (.astro/ appended; 6 prior entries preserved — Plan 01 T2 Edit C)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/index.astro (footer /refund + /terms link pair + guarantee-block refund-link removed — Plan 01 T1 Bundle C)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/use-cases/[slug].astro (footer + guarantee-block refund-link removed — Plan 01 T1 Bundle C)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/compare/cursor.astro (footer /refund + /terms link pair removed — Plan 01 T1 Bundle C)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/compare/ia-writer.astro (same)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/compare/obsidian.astro (same)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/compare/typora.astro (same)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/compare/vs-code.astro (same)"
  deleted:
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.agents/ad-copy-plan.md (D-01 — Plan 01 T1 Bundle A)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.agents/community-posts.md (D-01)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.agents/product-marketing-context.md (D-01)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/scripts/send-survey.mjs (D-02)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/api/trial/activate.ts (D-07 — Plan 01 T1 Bundle B)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/api/trial/validate.ts (D-07)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/api/version.json.ts (D-07)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/refund.astro (D-08 — Plan 01 T1 Bundle C)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/pages/terms.astro (D-08)"
  untracked:
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.astro/content-assets.mjs (D-05 — still on disk, regenerated by `pnpm dev` — Plan 01 T2 Edit B)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.astro/content-modules.mjs (D-05)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.astro/content.d.ts (D-05)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.astro/data-store.json (D-05 — closes the leaked LemonSqueezy /buy redirect target)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.astro/settings.json (D-05)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/.astro/types.d.ts (D-05)"

key-decisions:
  - "D-01 through D-16 (16 locked decisions from 15-CONTEXT.md) implemented across Plans 01+02 with zero deviation from the locked positions. Phase 15 made no decisions of its own — every D-XX was locked at planning."
  - "Plan 01 surfaced one plan-internal inconsistency (astro.config.mjs:17 LemonSqueezy URL vs. zero-count acceptance) and resolved via the audit's escape valve — catalogued as category-(b) public URL; Phase 17 SITE-05 territory."
  - "Plan 02 hit one Rule 3 (blocking) deviation: macOS `timeout` not on PATH; substituted background-PID + sleep + kill pattern. Verification recipe only — no code change."
  - "Combined `${decision}` placeholder substituted to `stands` (audit file contains `D-09 stands`). Phase-rollup commit message: `docs(phase-15): summary + LAND-05 audit findings (D-11 categorized, D-09 stands)`."

requirements-completed: [LAND-01, LAND-02, LAND-03, LAND-04, LAND-05]

# Metrics
duration: ~32min (Plan 01 ~30min + Plan 02 ~2min)
completed: 2026-05-20
---

# Phase 15: Landing Repo OSS Surface — Phase-Rollup Summary

**Phase 15 made the `J-Krush/wrangle-landing` repo safe to flip public. Two waves: Plan 01 stripped private/internal/dead-paid-product surfaces (3 atomic deletion bundles + Layout.astro neutralization + `.astro/` build-cache untrack + `.gitignore` append) and ran a full D-11 secrets-audit (working tree + 23-commit history → zero category-(d) actual secret values, D-09 stands); Plan 02 added the MIT LICENSE attributed to J Krush, rewrote the README to D-14's 4-section public-facing structure, and proved the clean-checkout boot story via a `/tmp` clone running `pnpm dev` with no `.env` file. 8 atomic Landing Page commits across the two plans, 0 history-rewriting commands, 5/5 LAND-IDs closed, 16/16 D-XX decisions implemented.**

## Performance

- **Duration:** ~32 min total (Plan 01: ~30 min, Plan 02: ~2 min — the second plan was tight because it was 2 writes + 1 verification run)
- **Started:** 2026-05-20T21:39:54Z (Plan 01 execution begin)
- **Completed:** 2026-05-20T21:57:01Z (Plan 02 execution end; phase-rollup SUMMARY committed at this commit)
- **Plans executed:** 2 (Plan 01 = wave 1, Plan 02 = wave 2; Plan 02 depended on Plan 01)
- **Tasks executed:** 6 (3 per plan)
- **Commits in Landing Page repo:** 8 atomic (6 from Plan 01 + 2 from Plan 02)
- **Commits in planning host repo:** 2 (Plan 01 per-plan SUMMARY commit + this phase-rollup commit which bundles the audit + per-plan-02 SUMMARY + phase-SUMMARY)
- **Net file ops in Landing Page repo:** 1 created (LICENSE) + 9 modified + 11 deleted + 6 untracked

## Plan Summaries

### Plan 01 — Deletions + .gitignore + D-11 Audit (LAND-01, LAND-04, LAND-05)

See `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-01-SUMMARY.md` for full detail.

**Headline outcomes:**

- 3 paid-product API endpoints deleted (`api/trial/{activate,validate}.ts`, `api/version.json.ts`) — D-07
- 2 paid-product Astro pages deleted (`refund.astro`, `terms.astro`) — D-08
- 16 internal nav/footer link references to `/refund` + `/terms` stripped across 7 files (5 compare/* + index.astro + use-cases/[slug].astro)
- 3 `.agents/` private content files deleted — D-01
- 1 `send-survey.mjs` (LemonSqueezy + Resend + Vercel KV trial-user survey tool) deleted — D-02
- 1 `Layout.astro` default description neutralized (`$19 one-time.` sentence dropped) — specifics block
- 6 `.astro/*` build cache files untracked via `git rm -r --cached` — D-05
- `.gitignore` appended with `.astro/`; all 6 prior entries (`/node_modules`, `.env*`, `.DS_Store`, `*.pem`, `dist/*`, `.vercel`) preserved verbatim — D-06
- Full D-11 audit ran: 96 working-tree hits in 12 files; 1971 history hits (236 unique tuples) across 23 commits; **0 category-(d) actual secret values in working tree OR history**

**Plan 01 commits (Landing Page repo):**

| # | Hash | Message |
|---|------|---------|
| 1 | `e002769` | chore(land-01): remove private agent notes and lemonsqueezy survey script |
| 2 | `1d059de` | chore(land-01): remove dead trial and version api endpoints (no remaining clients post-phase-13) |
| 3 | `fd66374` | chore(land-01): remove refund and terms pages and any internal links |
| 4 | `0456b7a` | chore(land-01): drop $19 one-time copy from Layout.astro default description |
| 5 | `5772302` | chore(land-04): untrack .astro/ build cache (D-05) |
| 6 | `f4a8402` | chore(land-04): add .astro/ to .gitignore (D-06) |

### Plan 02 — LICENSE + README + Clean-Checkout Verify (LAND-02, LAND-03)

See `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-02-SUMMARY.md` for full detail.

**Headline outcomes:**

- MIT `LICENSE` at landing repo root, canonical SPDX template (21 lines), attribution `Copyright (c) 2026 J Krush` (exact, locked) — LAND-02
- `README.md` rewritten to D-14 4-section public-facing structure (`## What this is` / `## Develop` / `## Deploy` / `## See also` / `## License`); 31 lines; pnpm command table preserved verbatim; 2x `github.com/J-Krush/wrangle` link-backs (D-15); `RESEND_API_KEY` dev-warning documented (D-12); `@astrojs/vercel` deploy adapter named — LAND-03
- Clean-checkout verification (D-12): `/tmp/wrangle-landing-verify` clone with NO `.env` file booted `pnpm dev` cleanly. Captured boot line: `┃ Local    http://localhost:4321/`. Astro `v5.18.0 ready in 715 ms`. `pnpm install --frozen-lockfile` exited 0. Verify clone torn down.
- Pre-flight audit gate passed: `DEVIATION: SECRET VALUE FOUND` count = 0 in `15-01-AUDIT.md`; `D-09 stands` confirmed; proceeded without surfacing to user.

**Plan 02 commits (Landing Page repo):**

| # | Hash | Message |
|---|------|---------|
| 7 | `418bd25` | chore(land-02): add MIT LICENSE attributed to J Krush |
| 8 | `a4c6506` | chore(land-03): rewrite README.md as public-facing per D-14 (4-section minimal) |

## Accomplishments

### Public-flip readiness

- **Working tree** of `wrangle-landing` is now publishable: no private agent notes, no LemonSqueezy survey script, no dead trial/version API endpoints, no paid-product Astro pages, no orphan `/refund` / `/terms` link references, no `$19 one-time.` in Layout default, no stray `.astro/` build cache in the index.
- **MIT LICENSE** present at root, attributed correctly.
- **README** orients a public visitor in 31 lines: what the repo is, how to develop locally, where it deploys, links back to the app repo, MIT footer.

### History posture (D-09)

- **0 category-(d) actual secret values** anywhere in the 23-commit history.
- `RESEND_API_KEY`, `KV_REST_API_URL`, `KV_REST_API_TOKEN`, `LemonSqueezy` are all only env-var NAME references or public-URL artifacts — never values.
- `hello@wrangleapp.dev` is the public outbound marketing email (sender on the feedback form) — not credentials.
- `plausible|fathom|posthog`: zero hits anywhere.
- **No `git filter-repo`, no `git push --force`, no `git reset --hard`** invoked across the entire phase. `cd "Landing Page" && git reflog | grep -ciE 'filter-repo|push.*force|reset --hard'` returns 0.

### Kept-surface invariant (D-03 / D-04)

- ✓ `src/pages/feedback.astro` — kept
- ✓ `src/pages/api/feedback.ts` — kept (RESEND_API_KEY env-var-name reference; D-03)
- ✓ `pencil/wrangle-landing-1.pen` — kept (encrypted at rest; D-04)
- ✓ `package.json` — unmodified by Phase 15 (scope boundary; Phase 17 SITE-05 may modify)
- ✓ `astro.config.mjs` — unmodified by Phase 15 (scope boundary; Phase 17 SITE-05 will rewrite `/buy` redirect)
- ✓ `@astrojs/vercel` adapter — present in `package.json`

### Clean-checkout boot story (D-12)

- ✓ Fresh `/tmp` clone with NO `.env` file booted `pnpm dev` to `http://localhost:4321/` cleanly
- ✓ `pnpm install --frozen-lockfile` exit code 0
- ✓ Astro v5.18.0 ready in 715 ms
- ✓ `/api/feedback` NOT exercised in the boot test (warning fires only on POST; documented in README per D-12)
- ✓ Verify clone torn down with `rm -rf /tmp/wrangle-landing-verify`

## D-Decision Mapping (all 16 D-XX → implementing task)

| Decision | Plan / Task | Implementation |
| -------- | ----------- | -------------- |
| D-01 (delete `.agents/`) | Plan 01 T1 Bundle A | `git rm -r .agents/` — 3 files removed in commit `e002769` |
| D-02 (delete `scripts/send-survey.mjs`) | Plan 01 T1 Bundle A | `git rm scripts/send-survey.mjs` — also in `e002769`; scripts/ disappeared naturally |
| D-03 (keep feedback.astro + api/feedback.ts) | Plan 01 T1 acceptance + Plan 02 verification | Acceptance grep + working-tree audit confirm both present |
| D-04 (keep pencil/wrangle-landing-1.pen) | Plan 01 T1 acceptance + Plan 02 verification | Acceptance grep confirms file present; encrypted-at-rest false-matches excluded from audit via `:!pencil/*` |
| D-05 (untrack `.astro/` build cache) | Plan 01 T2 Edit B | `git rm -r --cached .astro/` — 6 files untracked in commit `5772302`; remain on disk |
| D-06 (append `.astro/` to `.gitignore`) | Plan 01 T2 Edit C | New section `# Astro build cache\n.astro/` appended in commit `f4a8402`; 6 prior entries preserved verbatim |
| D-07 (delete trial + version API endpoints) | Plan 01 T1 Bundle B | 3 files (`api/trial/{activate,validate}.ts` + `api/version.json.ts`) removed in commit `1d059de` |
| D-08 (delete `refund.astro` + `terms.astro`) | Plan 01 T1 Bundle C | 2 files + 16 internal nav/footer link references stripped in commit `fd66374` |
| D-09 (preserve history; no filter-repo) | All tasks | reflog grep returns 0; history posture preserved |
| D-10 (audit doc in planning host, not landing repo) | Plan 01 T3 + Plan 02 T3 | `15-01-AUDIT.md` created uncommitted by Plan 01; committed to planning host (NOT to landing repo) by Plan 02 |
| D-11 (audit regex + categorization) | Plan 01 T3 | Working tree (96 hits) + history (1971 hits) both run with exact regex; every hit categorised |
| D-12 (clean-checkout verification + RESEND_API_KEY warning doc) | Plan 02 T2 (README) + Plan 02 T3 (verify) | README documents the expected warning; `/tmp` clone booted `pnpm dev` cleanly on port 4321 |
| D-13 (no `.env.example` in Phase 15) | Plan 02 T2 negative-check | `! grep -q '\.env\.example' README.md` acceptance passed |
| D-14 (README 4-section structure) | Plan 02 T2 | 5 H2 sections in order; pnpm table preserved verbatim; 31 lines |
| D-15 (two link-backs to app repo) | Plan 02 T2 | 2x `github.com/J-Krush/wrangle` (orientation paragraph + See also footer) |
| D-16 (License section in README) | Plan 02 T2 footer | `## License\n\nMIT — see [LICENSE](./LICENSE).` |

**Every D-XX decision (D-01 through D-16) implemented. Zero pivots from locked positions.**

## LAND-ID Coverage (all 5 closed)

| Requirement | Plan / Task | Status | Evidence |
| ----------- | ----------- | ------ | -------- |
| LAND-01 (audit + remove private content + dead surfaces) | Plan 01 T1+T2+T3 | ✓ Complete | Working tree free of `.agents/`, send-survey.mjs, api/trial/*, refund.astro, terms.astro, $19 sentence |
| LAND-02 (MIT LICENSE) | Plan 02 T1 | ✓ Complete | LICENSE present, 21 lines, canonical SPDX, attribution `Copyright (c) 2026 J Krush` |
| LAND-03 (public-facing README) | Plan 02 T2 | ✓ Complete | README rewritten to D-14 structure; pnpm + Vercel + app-repo link-back all named |
| LAND-04 (.gitignore correctness) | Plan 01 T2 | ✓ Complete | `.astro/` appended; node_modules / .env* / dist/* / .DS_Store / .vercel / *.pem preserved |
| LAND-05 (full audit, no committed secrets) | Plan 01 T3 + Plan 02 audit incorporation | ✓ Complete | Working tree (96 hits) + history (1971 hits) audited; **0 category-(d) actual secret values**; D-09 stands |

## Audit Summary (Plan 01 T3 → 15-01-AUDIT.md, incorporated)

### Working tree (post-Plan-01-deletions state)

| Category | Count | Surfaces |
| -------- | ----- | -------- |
| (a) env-var NAME / package-name / feature-copy substring | ~88 | pnpm-lock.yaml package names, "token counting" feature copy, RESEND_API_KEY env-var name in api/feedback.ts |
| (b) public URL artifact | 2 | `astro.config.mjs:16,17` — public LemonSqueezy `/buy` checkout URL (Phase 17 SITE-05 territory) |
| (c) historical pricing copy | ~6 | `src/data/use-cases.json` + `src/pages/compare/ia-writer.astro` `$19` mentions (Phase 17 SITE-07 territory) |
| **(d) ACTUAL SECRET VALUE** | **0** | **clean — zero credentials in working tree** |

### Full history (23 commits)

| Category | Approx count | Surfaces |
| -------- | ------------ | -------- |
| (a) env-var NAME / package-name / feature-copy substring | ~1900 | pnpm-lock.yaml package-name substrings dominate; RESEND_API_KEY / KV_REST_API_URL / KV_REST_API_TOKEN names in deleted send-survey.mjs and api/trial/* |
| (b) public URL artifact | ~50 | Multiple historical UUIDs of the `/buy` redirect in `astro.config.mjs` and `.astro/data-store.json` — all public LemonSqueezy checkout URLs |
| (c) historical pricing copy | ~30 | `$10` / `$19` / `$24` in `.agents/*`, `src/data/use-cases.json`, `src/pages/compare/*`, `src/pages/index.astro`, prior Layout.astro versions |
| **(d) ACTUAL SECRET VALUE** | **0** | **clean — zero credentials ever committed to this repo** |

### D-09 stands

- Category (d) count in working tree: **0**
- Category (d) count in history: **0**
- No `git filter-repo` invocation indicated.
- No force-push indicated.
- Phase 18 (FLIP-03) cleared from a credential-exposure standpoint.
- The public LemonSqueezy URL surfaces (working tree + history) are honest portfolio narrative — "shipped paid, flipped OSS" — exactly what D-09 anticipated.

## Decisions Made (cross-plan)

1. **astro.config.mjs left untouched despite a plan-internal acceptance conflict.** Plan 01 Task 3's `<acceptance_criteria>` predicted zero `jkrush.lemonsqueezy.com` hits in the working tree, but the same plan's `<must_haves>` and CONTEXT.md `<canonical_refs>` put `astro.config.mjs` in the do-not-touch list. The audit's escape valve was invoked: catalogue the surviving hit (category-(b) public URL) and proceed. Documented in `15-01-AUDIT.md` under "Plan-Internal Inconsistency Acknowledged." Phase 17 SITE-05 owns the redirect rewrite.
2. **Bundle C scope discipline (Plan 01).** When `/refund` and `/terms` link cleanup surfaced references inside `compare/*` and `use-cases/[slug].astro` (Phase-17-owned reposition surfaces), only the dead links (which would 404 after the page deletions) were removed. Surrounding "30-day money-back guarantee" copy and `$19` / `$24` CTAs explicitly left intact for Phase 17 SITE-05/07.
3. **Atomic-commit cadence honored.** Inherited Phase 13's atomic-per-logical-change pattern: 6 atomic commits in Plan 01 + 2 in Plan 02 = 8 total in Landing Page repo. Each commit is independently revertible. Bundle C (refund/terms delete + 16 link-strips) is a single commit because they're logically the same operation (purging `/refund` + `/terms` surface).
4. **Pre-flight audit gate added to Plan 02 executor brief.** Before any LICENSE/README write, Plan 02 read `15-01-AUDIT.md` and grepped for `DEVIATION: SECRET VALUE FOUND`. Count = 0; `D-09 stands` confirmed; proceeded. This gate is encoded as the orchestrator's `<pre_flight_gate>` step and is reusable for any future phase that follows a D-09-style audit.
5. **macOS `timeout`-substitute pattern (Plan 02).** Plan's recipe `timeout 30 pnpm dev > log 2>&1 || true` failed (coreutils not on PATH); substituted with background-PID + sleep + kill. Documented as a reusable Pattern 1 in `15-02-SUMMARY.md`.
6. **`${decision}` substitution applied to `stands`.** The audit file contains the literal `D-09 stands` (3 hits); per the orchestrator's substitution rule, the phase-rollup commit message reads `docs(phase-15): summary + LAND-05 audit findings (D-11 categorized, D-09 stands)`. No unsubstituted `${decision}` literal appears in any commit.

## Deviations from Plan (cross-plan total)

| Plan | Deviation | Rule | Resolution | Files Modified |
| ---- | --------- | ---- | ---------- | -------------- |
| Plan 01 | Plan-internal acceptance-criterion conflict (astro.config.mjs:17 LemonSqueezy URL) | n/a (plan-conflict, not executor deviation) | Audit escape valve invoked; catalogued as category-(b); Phase 17 territory | none (do-not-touch boundary honored) |
| Plan 02 | macOS lacks `timeout` binary | Rule 3 (blocking) | Background-PID + sleep + kill substitute pattern | none (verification recipe only) |

**Cross-plan deviation total:** 1 plan-internal-conflict (resolved by spec's own escape valve) + 1 Rule 3 (environmental, auto-resolved). **Zero scope creep. Zero Rule 1/2/4 deviations. Zero pivots from locked D-XX positions.**

## Verification (phase-level)

All clauses from both plans' `<verification>` blocks pass:

### Plan 01 verification (8 clauses)

1. ✓ Working-tree deletions confirmed
2. ✓ Kept files intact
3. ✓ Layout.astro neutralized (no `$19`; "token counting." present)
4. ✓ `.gitignore` hardened (`.astro/` + all 6 pre-existing entries)
5. ✓ `.astro/*` untracked
6. ✓ Audit recorded with both grep sections + branch decision
7. ✓ Commit cadence: 6 atomic `land-0[14]` commits
8. ✓ No history rewrite (reflog count = 0)

### Plan 02 verification (8 clauses)

1. ✓ LICENSE present at landing root
2. ✓ README structure complete (5 H2 in D-14 order; pnpm table verbatim; D-15 + D-16 honored; no badges; no story)
3. ✓ Clean-checkout boot — `┃ Local    http://localhost:4321/` captured; verify clone torn down
4. ✓ Audit incorporated into phase-rollup SUMMARY (this file) — every D-XX mapped, every LAND-ID closed
5. ✓ Atomic-commit cadence — 8 `land-0[123]` commits in Landing Page repo
6. ✓ No history rewrite (reflog count = 0)
7. ✓ Phase 15 kept-surface invariant
8. ✓ SUMMARY commit substitution — `${decision}` ABSENT; `D-09 stands` PRESENT in commit message

## Issues Encountered

- **macOS `timeout` binary missing.** Documented above (Plan 02 deviation Rule 3). Not a blocker.
- **No build failures, no merge conflicts, no auth gates, no untracked-file confusion.** Both plans ran cleanly.
- **astro.config.mjs LemonSqueezy URL surfaced in audit** — not an issue per se, but a plan-internal-acceptance contradiction that the audit's escape valve resolved cleanly. Future verifier should note that Phase 17 SITE-05 owns this rewrite.

## Threat Flags (cross-phase)

No new security-relevant surface introduced by either plan. All threat-model entries from both plans (T-15-01 through T-15-08 in Plan 01, T-15-09 through T-15-14 + T-15-SC in Plan 02) are addressed in the respective per-plan SUMMARYs. No `high`-rated residual threats. T-15-07 (secret VALUE in historical commit) was the highest-prior-uncertainty entry and is resolved by the audit's category-(d) count of **0**.

## Cleanup

- ✓ `/tmp/wrangle-landing-verify` clone torn down with `rm -rf` after Plan 02 T3 captured artifacts
- ✓ `/tmp/wlv-install.log` and `/tmp/wlv-dev.log` were transient artifacts; not committed anywhere
- ✓ No working-tree drift in either repo (both `git status --short` return clean immediately before phase-rollup commit)

## Self-Check: PASSED

**Files created:**
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/LICENSE` — FOUND
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-01-AUDIT.md` — FOUND (committed by this phase-rollup commit)
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-01-SUMMARY.md` — FOUND (committed by Plan 01)
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-02-SUMMARY.md` — FOUND
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-SUMMARY.md` — FOUND (this file)

**Files modified (Landing Page repo):**
- ✓ `README.md` — FOUND (rewritten in `a4c6506`)
- ✓ `src/layouts/Layout.astro` — FOUND ($19 dropped in `0456b7a`)
- ✓ `.gitignore` — FOUND (.astro/ appended in `f4a8402`)
- ✓ `src/pages/index.astro` — FOUND (refund/terms link strip in `fd66374`)
- ✓ `src/pages/use-cases/[slug].astro` — FOUND (same)
- ✓ 5x `src/pages/compare/*.astro` — FOUND (same)

**Commits exist (Landing Page repo):**
- ✓ `e002769` — FOUND (Plan 01 T1 Bundle A)
- ✓ `1d059de` — FOUND (Plan 01 T1 Bundle B)
- ✓ `fd66374` — FOUND (Plan 01 T1 Bundle C)
- ✓ `0456b7a` — FOUND (Plan 01 T2 Edit A)
- ✓ `5772302` — FOUND (Plan 01 T2 Edit B)
- ✓ `f4a8402` — FOUND (Plan 01 T2 Edit C)
- ✓ `418bd25` — FOUND (Plan 02 T1 LICENSE)
- ✓ `a4c6506` — FOUND (Plan 02 T2 README)

**Verification gates (phase-level):**
- ✓ Both plans' verification blocks pass (16 total clauses, all green)
- ✓ All 5 LAND-IDs closed
- ✓ All 16 D-XX decisions implemented
- ✓ No history rewrite anywhere across the phase
- ✓ Clean-checkout boot proven
- ✓ Kept-surface invariant honored
- ✓ `${decision}` substitution applied correctly

## Next Phase Readiness

- **Phase 15 verifier (`/gsd:verify-phase 15`):** All gates ready. Recommend running before Phase 17 starts so any verifier catches are surfaced early.
- **Phase 16 (REL-01..06 — signed-DMG release pipeline):** Independent of Phase 15. Unblocked. Critical path for Phase 18 (the DMG URL needs to exist before Phase 17's "Download for macOS" CTA can wire up).
- **Phase 17 (SITE-01..10 — landing page repositioning):** Now has a precise hit-list from Plan 01's audit:
  - **SITE-05:** rewrite `astro.config.mjs:17` `/buy` → `/download` (catalogued as category-(b) public URL)
  - **SITE-07:** reposition `src/data/use-cases.json` + `src/pages/compare/*.astro` pricing copy (catalogued as category-(c) — ~6 working-tree hits)
  - **SITE-01/04:** hero CTA + nav reframe (no Phase 15 surface; net-new copy work)
  - **SITE-05/06:** OG/SEO updates (Layout.astro default now neutralized; per-page descriptions still need setting)
  - **SITE-10:** 404 fallback for the deleted `/refund` + `/terms` URLs (NOT reserved by Phase 15 — Phase 17 decides)
- **Phase 18 (FLIP-01..05 — public flip + v1.3.0 release):** D-09 stands; zero credential exposure confirmed. Phase 15 fully clears the credential-exposure gate for `wrangle-landing`. FLIP-03 (landing-repo public flip) now blocked only on Phase 17's SITE-* completion.

---
*Phase: 15-landing-repo-oss-surface*
*Plans covered: 15-01, 15-02*
*Completed: 2026-05-20*
