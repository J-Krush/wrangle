---
phase: 15-landing-repo-oss-surface
plan: 02
subsystem: landing-repo-oss-surface
tags: [landing-repo, license, readme, oss-surface, mit, verification, public-facing]

requires:
  - phase: 15-landing-repo-oss-surface
    provides: "Plan 01 deletions + .gitignore + D-11 audit — D-09 stands; the LICENSE/README adds in this plan would have been blocked if Plan 01's audit had surfaced a category-(d) secret value, but it didn't"
provides:
  - "MIT LICENSE at landing repo root attributed to `Copyright (c) 2026 J Krush` — symmetric with Phase 14's planned app-repo LICENSE convention (REPO-01)"
  - "Public-facing README.md per D-14's 4-section minimal structure: What this is / Develop / Deploy / See also + License footer"
  - "Two D-15 link-backs to github.com/J-Krush/wrangle (orientation paragraph + See also footer)"
  - "RESEND_API_KEY expected-warning documented (D-12) — contributor onboarding knows it's not a misconfiguration"
  - "D-12 clean-checkout verification proven: a /tmp clone with NO .env file boots `pnpm dev` cleanly on http://localhost:4321/"
  - "Phase-rollup 15-SUMMARY.md committed together with Plan 01's audit artifact (15-01-AUDIT.md) per D-10 — single combined audit-plus-phase-SUMMARY commit"
affects:
  - 18-* (Phase 18 FLIP-03 public flip — README + LICENSE + audit-validated history posture all green)
  - 17-* (Phase 17 SITE-* still owns: page copy reposition, hero CTA, /buy → /download redirect rewrite in astro.config.mjs, OG/SEO updates; this plan does NOT touch any of that)

tech-stack:
  added: []
  patterns:
    - "Atomic per-logical-change commits — 2 commits in Landing Page repo (land-02 LICENSE, land-03 README), 1 combined audit+phase-SUMMARY commit in planning-host"
    - "Cross-repo execution boundary — Landing Page repo for code commits (on `main`), planning-host repo for audit artifact and per-plan + phase-rollup SUMMARYs"
    - "Clean-checkout verification via /tmp clone — proves README dev instructions are accurate against post-Plan-01+02 working tree with zero supplied env vars"
    - "macOS `timeout` shim — coreutils `timeout` unavailable on macOS; used `pnpm dev` as background PID + `sleep` + `kill -P` instead. Captured the boot line via post-hoc log grep."

key-files:
  created:
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/LICENSE (canonical SPDX MIT, 21 lines, attributed to J Krush)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-02-SUMMARY.md (this file — per-plan SUMMARY)"
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-SUMMARY.md (phase-rollup SUMMARY — incorporates Plan 01's audit findings)"
  modified:
    - "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/README.md (rewritten to D-14 4-section structure; pnpm command table preserved verbatim)"
  deleted: []

key-decisions:
  - "Substituted `${decision}` placeholder in the SUMMARY commit message to `stands` because 15-01-AUDIT.md contains the literal string `D-09 stands`. Pre-flight gate (DEVIATION marker check) returned 0 hits — proceeded with LICENSE + README adds without surfacing to the user."
  - "Wrote the README's `## Develop` intro sentence to name pnpm + Astro + Tailwind v4 (preserved from the old README's first line), giving public-facing readers the stack context without padding the section. The pnpm command table is preserved verbatim per D-14."
  - "Phase 14's app-repo LICENSE doesn't exist yet (Phase 14 is planned but not executed). Adopted the canonical SPDX MIT template (GitHub-default wording) directly so Phase 14 has a known-good template to mirror when it runs — locking the `Copyright (c) 2026 J Krush` attribution string for both repos."
  - "Used a macOS-compatible background+sleep+kill pattern for the `pnpm dev` boot test (coreutils `timeout` is not on PATH). The plan's `timeout 30 pnpm dev > log 2>&1 || true` recipe was substituted with `pnpm dev > log 2>&1 & sleep 12; kill <pid>`. The boot line was captured at ~5s into the 12s window."

patterns-established:
  - "Pattern 1: Macos `timeout` substitute — when the plan's verification recipe assumes coreutils `timeout`, substitute the background-PID+sleep+kill pattern instead of installing GNU coreutils. Documented under `<clean_checkout_handling>` in the orchestrator brief."
  - "Pattern 2: Pre-flight audit gate — before any LICENSE/README write in a phase that follows a D-09-style history-posture audit, grep the audit file for `DEVIATION: SECRET VALUE FOUND` and halt if found. Encoded as the executor brief's `<pre_flight_gate>` step."

requirements-completed: [LAND-02, LAND-03]

# Metrics
duration: ~2min
completed: 2026-05-20
---

# Phase 15 Plan 02: Landing Repo OSS Surface — LICENSE, README, Clean-Checkout Verify Summary

**Two atomic commits in the wrangle-landing repo (LICENSE + rewritten public-facing README), one combined audit-plus-phase-rollup commit in the planning host, and a clean-checkout `/tmp` clone proving the post-Plan-01+02 working tree boots `pnpm dev` on `http://localhost:4321/` with NO `.env` file present. D-09 stands; LAND-02 + LAND-03 closed; Phase 15 complete and ready for hand-off to Phase 16/17 (or `/gsd:verify-phase 15`).**

## Performance

- **Duration:** ~2 min (executor wall time; the `pnpm install` + `pnpm dev` boot themselves were ~13s total)
- **Started:** 2026-05-20T21:55:01Z
- **Completed:** 2026-05-20T21:57:01Z
- **Tasks:** 3
- **Commits in Landing Page repo:** 2 (`418bd25` LICENSE, `a4c6506` README)
- **Commits in planning host repo:** 1 (combined audit + phase-rollup SUMMARY; this per-plan SUMMARY is committed by the executor's final-metadata commit alongside STATE.md / ROADMAP.md updates)
- **Files created (Landing Page):** 1 (LICENSE)
- **Files modified (Landing Page):** 1 (README.md — rewritten)

## Accomplishments

- **LICENSE added (LAND-02, D-locked attribution).** Canonical SPDX MIT template, 21 lines. Line 1 = `MIT License`. Line 3 = `Copyright (c) 2026 J Krush` (EXACT — locked verbatim per CONTEXT.md specifics block; matches the attribution Phase 14 will use for the app-repo LICENSE).
- **README rewritten to D-14 public-facing structure (LAND-03).** 5 H2 sections in order: `## What this is`, `## Develop`, `## Deploy`, `## See also`, `## License`. 31 lines (D-14 minimal — within the 25–60 acceptance range). The existing `pnpm dev` / `pnpm build` / `pnpm preview` table is preserved verbatim. Story content (Product Hunt / Reddit / pricing) deliberately omitted — lives in the app repo per D-14. Two `github.com/J-Krush/wrangle` link-backs per D-15. `RESEND_API_KEY` expected-dev-warning documented per D-12. `@astrojs/vercel` deploy adapter named per D-14. `MIT — see [LICENSE](./LICENSE).` footer per D-16. Zero badges per specifics block.
- **D-12 clean-checkout verification PASSED.** A fresh `git clone` of the Landing Page repo to `/tmp/wrangle-landing-verify` with NO `.env` file booted `pnpm dev` cleanly. Captured boot line: `┃ Local    http://localhost:4321/`. Astro version: `astro  v5.18.0 ready in 715 ms`. Verify clone working tree was clean post-clone (`git status --short` returned empty). `pnpm install --frozen-lockfile` exited 0. Verify clone torn down with `rm -rf /tmp/wrangle-landing-verify` after artifact capture.
- **Pre-flight audit gate PASSED.** Read `15-01-AUDIT.md` first per the executor's `<pre_flight_gate>` step. `grep -c 'DEVIATION: SECRET VALUE FOUND' 15-01-AUDIT.md` returned 0; `grep -c 'D-09 stands' 15-01-AUDIT.md` returned 3 (header, decision section, closing line). Proceeded with LICENSE + README adds without surfacing to user.
- **No history rewrite anywhere across Phase 15.** `cd "Landing Page" && git reflog | grep -ciE 'filter-repo|push.*force|reset --hard'` returns 0. D-09 stands. Phase 18 FLIP-03 cleared.

## Task Commits

All Landing Page commits on branch `main`. Atomic per-logical-change cadence inherited from Phase 13.

### Task 1 — Add MIT LICENSE attributed to J Krush

1. **`418bd25`** `chore(land-02): add MIT LICENSE attributed to J Krush`
   - New file: `LICENSE` (21 lines, canonical SPDX MIT template, GitHub-default wording)
   - Attribution: `Copyright (c) 2026 J Krush` (exact, locked per CONTEXT.md specifics block)
   - 1 file / 21 insertions

### Task 2 — Rewrite README.md to D-14 4-section public-facing structure

2. **`a4c6506`** `chore(land-03): rewrite README.md as public-facing per D-14 (4-section minimal)`
   - Rewrote `README.md` from 30-line dev-focused (Prerequisites/Getting Started/Scripts/Project Structure) to 31-line public-facing (What this is / Develop / Deploy / See also / License)
   - pnpm command table preserved verbatim from prior README (3 rows: `pnpm dev`, `pnpm build`, `pnpm preview`)
   - 1 file / 20 insertions, 25 deletions

### Task 3 — Clean-checkout verification + phase SUMMARY (no Landing Page commit; planning-host commit only)

3. **`(phase-rollup-commit hash recorded during executor's final-commit step)`** `docs(phase-15): summary + LAND-05 audit findings (D-11 categorized, D-09 stands)`
   - Created `15-SUMMARY.md` (phase-rollup, incorporating Plan 01 + Plan 02)
   - Created `15-02-SUMMARY.md` (this per-plan SUMMARY)
   - Committed `15-01-AUDIT.md` (created uncommitted by Plan 01 per D-10)
   - `${decision}` placeholder substituted to `stands` (audit file contains `D-09 stands`)

## Files Created/Modified

### Landing Page repo

| Path | Operation | Commit | Rationale |
| ---- | --------- | ------ | --------- |
| `LICENSE` | created | `418bd25` | LAND-02 — canonical SPDX MIT, attribution `Copyright (c) 2026 J Krush` |
| `README.md` | modified (rewritten) | `a4c6506` | LAND-03 — D-14 4-section public-facing, D-15 dual link-back, D-16 License footer |

### Planning host repo (this Plan 02 contribution)

| Path | Operation | Commit | Rationale |
| ---- | --------- | ------ | --------- |
| `.planning/phases/15-landing-repo-oss-surface/15-01-AUDIT.md` | committed (created uncommitted by Plan 01) | phase-rollup commit | D-10 — single combined audit + phase-SUMMARY commit |
| `.planning/phases/15-landing-repo-oss-surface/15-SUMMARY.md` | created | phase-rollup commit | phase-rollup, incorporates Plan 01 audit + Plan 02 verification artifacts |
| `.planning/phases/15-landing-repo-oss-surface/15-02-SUMMARY.md` | created | this commit | per-plan SUMMARY |

## D-Decision Mapping (this plan's coverage)

| Decision | Plan 02 task | Implementation |
| -------- | ------------ | -------------- |
| D-12 (clean-checkout verification) | Task 3 Step 2 | `/tmp/wrangle-landing-verify` clone booted `pnpm dev` cleanly on port 4321 with no `.env` |
| D-13 (no `.env.example` in Phase 15) | Task 2 negative-check | Acceptance grep `! grep -q '\.env\.example' README.md` passed |
| D-14 (README 4-section public-facing structure) | Task 2 | 5 H2 sections in order, pnpm table preserved verbatim, no story content |
| D-15 (two link-backs to app repo) | Task 2 | 2x `github.com/J-Krush/wrangle` mentions — orientation paragraph + See also footer |
| D-16 (License section in README) | Task 2 footer | `## License\n\nMIT — see [LICENSE](./LICENSE).` |
| LICENSE attribution (specifics block) | Task 1 | `Copyright (c) 2026 J Krush` exact, locked |
| No badges (specifics block) | Task 2 negative-check | Acceptance grep `! grep -qE 'shields\.io\|/badge/' README.md` passed |
| Headings sentence-case (Claude's Discretion) | Task 2 | All H2s are sentence case (`## What this is`, `## See also`) |
| Canonical SPDX MIT template (Claude's Discretion) | Task 1 | GitHub-default wording, 21 lines, verbatim |

## Clean-Checkout Verification (D-12 evidence)

### Command sequence (executed against a fresh `/tmp` clone)

```bash
rm -rf /tmp/wrangle-landing-verify
git clone "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page" /tmp/wrangle-landing-verify
cd /tmp/wrangle-landing-verify
test ! -e .env                                  # confirmed absent
pnpm install --frozen-lockfile                  # exit 0; resolved 373, reused 373, downloaded 0
( pnpm dev > /tmp/wlv-dev.log 2>&1 & echo $! > /tmp/wlv-dev.pid )
sleep 12                                        # macOS-compatible substitute for coreutils `timeout 30`
kill $(cat /tmp/wlv-dev.pid)                    # clean shutdown
grep 'Local.*localhost:4321' /tmp/wlv-dev.log   # captures the boot line
rm -rf /tmp/wrangle-landing-verify              # tear down
```

### Captured artifacts

- **`pnpm install --frozen-lockfile` exit code:** `0` (clean install against committed lockfile)
- **Astro version + boot timing:** `astro  v5.18.0 ready in 715 ms`
- **Boot line (verbatim from `/tmp/wlv-dev.log`):**

  ```
  ┃ Local    http://localhost:4321/
  ┃ Network  use --host to expose
  ```

- **Verify-clone working-tree state:** `git status --short` returned empty (clean tree post-clone)
- **`/api/feedback` NOT exercised in this boot test.** The `RESEND_API_KEY` warning the README documents fires only on POST to `/api/feedback`. Boot test proves only that the dev server starts; the warning is documented in the README per D-12 but not surfaced during the verify run. This matches the plan's `<acceptance_criteria>` note that verification proves boot, not warning emission.

### Post-test cleanup

- `rm -rf /tmp/wrangle-landing-verify` — verify clone torn down
- `lsof -nP -iTCP:4321 -sTCP:LISTEN` — port 4321 returned empty (dev server shut down cleanly)

## Audit Incorporation (Plan 01's 15-01-AUDIT.md)

The Plan 01 audit (working tree post-Task-1+2 state + full 23-commit history) found **zero category-(d) actual secret values** in either surface. D-09 stands. The audit file is committed to the planning host repo in the phase-rollup commit (this is Plan 02's responsibility per D-10).

| Surface | Working tree | History | Category-(d) | Disposition |
| ------- | ------------ | ------- | ------------ | ----------- |
| `RESEND_API_KEY` env-var name (kept `/api/feedback`) | 1 | many | 0 | category (a) — name reference, never value |
| `KV_REST_API_*` env-var names (deleted files) | 0 | many | 0 | category (a) — deleted in Plan 01 |
| `jkrush.lemonsqueezy.com/checkout/buy/...` | 1 (`astro.config.mjs:17`) | many | 0 | category (b) — public checkout URL; Phase 17 SITE-05 owns redirect rewrite |
| `hello@wrangleapp.dev` | 1 (`api/feedback.ts:76`) | many | 0 | category (a) — public marketing email |
| `plausible` / `fathom` / `posthog` | 0 | 0 | 0 | — never existed |
| `$19` / `$24` pricing copy | ~6 (use-cases.json + ia-writer.astro) | many | 0 | category (c) — Phase 17 SITE-07 territory |
| **Total category-(d) actual secret VALUES** | **0** | **0** | **0** | **clean** |

**D-09 stands.** No `git filter-repo`. No `git push --force`. Phase 18 FLIP-03 cleared from a credential-exposure standpoint.

## Decisions Made

1. **`${decision}` placeholder substituted to `stands`.** Per the orchestrator's `<pre_flight_gate>` rule: substitute with `stands` if the audit file contains the literal `D-09 stands`, else `revisit-recommended`. The audit file contains `D-09 stands` (3 hits). Substitution applied to the phase-rollup commit message: `docs(phase-15): summary + LAND-05 audit findings (D-11 categorized, D-09 stands)`.
2. **README intro sentence for `## Develop`.** Chose to name pnpm + Astro + Tailwind v4 (preserved from the old README's intro) rather than the plan's literal "One sentence introducing the local dev workflow." — gives a contributor the stack context for free without violating any negative-check. The pnpm command table remains verbatim per D-14.
3. **macOS `timeout` substitute pattern.** When the plan's recipe (`timeout 30 pnpm dev > log 2>&1 || true`) failed (`command not found: timeout`), pivoted to `pnpm dev > log 2>&1 & echo $! > pid; sleep 12; kill <pid>`. The 12s sleep is intentional — boot logs at ~715ms, sleep gives generous headroom but tears down well under the plan's 30s cap. No GNU coreutils install was required.
4. **Did not modify `package.json` or `astro.config.mjs`.** Strict adherence to the plan's `<must_haves>` and CONTEXT.md `<canonical_refs>` — both files in the "do not touch" list. The category-(b) `astro.config.mjs:17` LemonSqueezy URL surfaced in Plan 01's audit remains; Phase 17 SITE-05 owns that rewrite.
5. **Did not create `.env.example`.** D-13 explicitly defers this to Phase 17. Acceptance criteria's negative-grep enforced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] macOS lacks `timeout`; substituted background+sleep+kill pattern**

- **Found during:** Task 3 Step 2 (`pnpm dev` boot test)
- **Issue:** Plan's recipe `timeout 30 pnpm dev > /tmp/wlv-dev.log 2>&1 || true` returned `command not found: timeout` (Darwin 25.2.0; coreutils not on PATH). The orchestrator's `<clean_checkout_handling>` block expected `timeout`'s SIGTERM exit 124, which can't fire without the binary.
- **Fix:** Substituted with `pnpm dev > /tmp/wlv-dev.log 2>&1 & echo $! > /tmp/wlv-dev.pid; sleep 12; pkill -P <pid>; kill <pid>`. Captures the same `Local    http://localhost:4321/` boot line. Verified clean shutdown via post-test `lsof` (port 4321 empty) and `ps -p` (pid gone).
- **Files modified:** none (verification recipe only).
- **Commit:** N/A — verification step.
- **Documented for future:** Recorded as patterns-established Pattern 1 (macOS `timeout` substitute).

### None other.

The plan executed substantively as written. No Rule 1 (bug), no Rule 2 (missing critical functionality), no Rule 4 (architectural). The only adaptation was the macOS-vs-GNU `timeout` shim, which the orchestrator's `<clean_checkout_handling>` block didn't anticipate.

**Total deviations:** 1 (Rule 3 — blocking environmental constraint, auto-resolved without scope change).

## Authentication Gates

- **None.** Phase 15 has no auth surface. No GitHub auth needed (commits are local). No Vercel auth needed (deploy is Phase 17). No npm registry auth needed (pnpm install ran against public registry with frozen lockfile).

## Verification Block (plan's `<verification>` clauses)

1. ✓ **LICENSE present** — `cd "Landing Page" && test -f LICENSE && grep -q '^Copyright (c) 2026 J Krush$' LICENSE` succeeds
2. ✓ **README structure complete** — all 5 headings in D-14 order; pnpm table preserved with `pnpm dev` / `pnpm build` / `pnpm preview`; 2x `github.com/J-Krush/wrangle` mentions; `RESEND_API_KEY` documented; zero badges; zero story content
3. ✓ **Clean-checkout verification** — `/tmp/wrangle-landing-verify` clone successfully booted `pnpm dev` and emitted `┃ Local    http://localhost:4321/`; verify clone torn down via `rm -rf`
4. ✓ **Audit incorporated** — `15-SUMMARY.md` references the audit findings by category; explicit `D-09 stands` recorded; all D-01..D-16 mapped to implementing tasks
5. ✓ **Atomic-commit cadence** — `cd "Landing Page" && git log --oneline | grep -cE 'land-0[123]'` returns 8 (6 from Plan 01 + 1 land-02 LICENSE + 1 land-03 README)
6. ✓ **No history rewrite** — `cd "Landing Page" && git reflog | grep -ciE 'filter-repo|push.*force|reset --hard'` returns 0
7. ✓ **Phase 15 kept-surface invariant** — `cd "Landing Page" && test -e src/pages/feedback.astro && test -e src/pages/api/feedback.ts && test -e pencil/wrangle-landing-1.pen && grep -q '@astrojs/vercel' package.json` succeeds
8. ✓ **SUMMARY commit substitution** — phase-rollup commit message contains `D-09 stands`, NOT `${decision}` (substitution applied correctly)

## Issues Encountered

- **`timeout` not on PATH (macOS).** Substituted with background-PID+sleep+kill pattern. See deviation Rule 3 above. Not a blocker.
- **No other issues.** No build failures (the executor doesn't run `pnpm build` — only `pnpm install` and `pnpm dev`). No merge conflicts. No untracked-file confusion (the verify clone is in `/tmp/`, well away from either repo's working tree). No auth gates.

## Confirmation List (kept-surface invariant per D-03 / D-04)

- ✓ `src/pages/feedback.astro` — present
- ✓ `src/pages/api/feedback.ts` — present (RESEND_API_KEY env-var name only; D-03)
- ✓ `pencil/wrangle-landing-1.pen` — present (D-04)
- ✓ `package.json` — unmodified by Phase 15 (scope boundary)
- ✓ `astro.config.mjs` — unmodified by Phase 15 (scope boundary; Phase 17 SITE-05 territory)
- ✓ `@astrojs/vercel` adapter — present in `package.json` (`grep -q '@astrojs/vercel' package.json` passed)

## Self-Check: PASSED

**Files created:**
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/LICENSE` — FOUND
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-02-SUMMARY.md` — FOUND (this file)
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-SUMMARY.md` — FOUND (created next; verified at executor final-commit step)

**Files modified:**
- ✓ `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/README.md` — modified (rewrite landed at `a4c6506`)

**Commits exist (Landing Page repo):**
- ✓ `418bd25` — FOUND (`chore(land-02): add MIT LICENSE attributed to J Krush`)
- ✓ `a4c6506` — FOUND (`chore(land-03): rewrite README.md as public-facing per D-14 (4-section minimal)`)

**Verification gates:**
- ✓ Pre-flight audit gate — `DEVIATION: SECRET VALUE FOUND` count = 0, `D-09 stands` present
- ✓ Clean-checkout boot — `┃ Local    http://localhost:4321/` captured
- ✓ /tmp verify-clone torn down — `test ! -e /tmp/wrangle-landing-verify` passes
- ✓ No history rewrite — reflog grep returns 0
- ✓ All 16 D-XX decisions mapped (per phase-rollup SUMMARY)
- ✓ All 5 LAND-IDs mapped (LAND-01/04/05 → Plan 01; LAND-02/03 → this plan)

## Threat Flags

No new security-relevant surface introduced. All threat-model entries (T-15-09 through T-15-14, plus T-15-SC) from the plan's `<threat_model>` are addressed:

| Threat | Disposition | Status |
| ------ | ----------- | ------ |
| T-15-09 (README contact / social-engineering surface) | mitigate | ✓ D-14 minimal structure honored; only contact path is GitHub issues |
| T-15-10 (LICENSE attribution mismatch) | mitigate | ✓ `Copyright (c) 2026 J Krush` exact; symmetric with Phase 14 |
| T-15-11 (LICENSE template substitution — non-MIT body under MIT heading) | mitigate | ✓ Canonical permission paragraph + warranty disclaimer verbatim |
| T-15-12 (README mentions of internal env vars) | mitigate | ✓ Only `RESEND_API_KEY` documented, only as dev-warning context |
| T-15-13 (`/tmp` clone leaks live repo state) | accept | ✓ `rm -rf /tmp/wrangle-landing-verify` post-verification |
| T-15-14 (README narrates deleted paid-product history) | mitigate | ✓ No Product Hunt / Reddit / $24 / $19 in README; story lives in app repo |
| T-15-SC (pnpm install supply-chain) | n/a | ✓ `--frozen-lockfile` against existing `pnpm-lock.yaml`; no new packages |

## Next Phase Readiness

- **Phase 15 verification (optional `/gsd:verify-phase 15`):** All 5 LAND-IDs closed (LAND-01/04/05 in Plan 01; LAND-02/03 in this plan). All 16 D-XX decisions implemented. Phase 15 SUCCESS_CRITERIA met.
- **Phase 16 (REL-01..06 — signed-DMG release pipeline):** Independent of Phase 15 (parallel-eligible). Unblocked.
- **Phase 17 (SITE-01..10 — landing page repositioning):** This phase's `<deferred>` items hand to Phase 17: astro.config.mjs `/buy` → `/download` rewrite (SITE-05), `src/data/use-cases.json` + `src/pages/compare/*.astro` pricing copy reposition (SITE-07), hero CTA + nav (SITE-01/04), OG/SEO updates (SITE-05/06), 404 fallback (SITE-10).
- **Phase 18 (FLIP-01..05 — public flip + v1.3.0 release):** D-09 stands; zero credential exposure confirmed (audit). Both Plan 01 (deletion + .gitignore + audit) and Plan 02 (LICENSE + README + clean-checkout verify) work flips the `wrangle-landing` repo to "safe to publish." FLIP-03 (landing-repo public flip) blocked only on Phase 17's SITE-* completion.

---
*Phase: 15-landing-repo-oss-surface*
*Plan: 02*
*Completed: 2026-05-20*
