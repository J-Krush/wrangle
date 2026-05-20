# Phase 15: Landing Repo OSS Surface - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 15-landing-repo-oss-surface
**Areas discussed:** Private content disposition, Dead trial-server endpoints, History rewrite posture, Landing README depth

---

## Private content disposition

### Q1 — `.agents/` + `scripts/send-survey.mjs` working-tree disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Delete both outright | `git rm -r .agents/` + `git rm scripts/send-survey.mjs`. Internal strategy + LemonSqueezy-era tooling, no public value. | ✓ |
| Delete `.agents/` only; keep survey script | Survey script as historical artifact; references gone `wrangleapp.dev/feedback` + LemonSqueezy CSV. | |
| Move outside the repo, keep both | Copy to `_private-notes/` then `git rm`. Same end-state for public, strategy survives on disk. | |

**User's choice:** Delete both outright.
**Notes:** Cleanest signal — no half-measures. History preserved (see D-09).

### Q2 — `src/pages/feedback.astro` + `src/pages/api/feedback.ts` (Resend-backed contact form)

| Option | Description | Selected |
|--------|-------------|----------|
| Delete in Phase 15 | Paid-product survey lineage. One less surface to audit. | |
| Keep — useful contact form | Resend API key env-var only, no leak. Normal landing-page feature. | ✓ |
| Defer to Phase 17 | Let the reposition phase decide. | |

**User's choice:** Keep.
**Notes:** Phase 17 reskins copy; Phase 15 leaves the route alone.

### Q3 — `pencil/wrangle-landing-1.pen` (encrypted design file)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep — design source artifact | Encrypted at rest, viewable only via Pencil app. No leak risk. | ✓ |
| Delete — not a build artifact | Public visitors don't need design source to ship the site. | |
| Move outside the repo | Same end-state for public viewers, history preserved on disk. | |

**User's choice:** Keep.

### Q4 — `.astro/` build cache (6 tracked files) disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Untrack + `.gitignore` | `git rm -r --cached .astro/` then add `.astro/` to `.gitignore`. Standard hygiene. | ✓ |
| Leave tracked | Some Astro setups commit `.astro/types.d.ts`. Risk: noisy diffs every build. | |
| Untrack but no `.gitignore` add | Half-measure; Astro will re-track on next build. | |

**User's choice:** Untrack + `.gitignore`.

---

## Dead trial-server endpoints

### Q1 — `src/pages/api/trial/{activate,validate}.ts` disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Delete in Phase 15 | No client, no purpose. Reduces public-repo surface. | ✓ |
| Defer to Phase 17 | Let the reposition phase clean up. | |
| Keep but stub to 410 Gone | Useful only if deployed v1.2 binaries still ping (Phase 13 ripped that out). | |

**User's choice:** Delete in Phase 15.

### Q2 — `src/pages/api/version.json.ts` (Phase 13 repointed UpdateChecker away from it)

| Option | Description | Selected |
|--------|-------------|----------|
| Delete in Phase 15 | Zero remaining clients per Phase 13 D-09. | ✓ |
| Defer to Phase 17 | Let the reposition phase clean up. | |
| Keep as a 'last known release' shim | UpdateChecker hits GitHub directly per D-09, no consumer. | |

**User's choice:** Delete in Phase 15.

### Q3 — `@astrojs/vercel` adapter disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Vercel adapter as-is | Feedback form needs server execution. Don't refactor deploy in Phase 15. | ✓ |
| Remove `@astrojs/vercel`, go fully static | Conflicts with kept feedback form. | |
| Defer adapter decision to Phase 17 | Phase 17 owns deploy reconfiguration if it wants one. | |

**User's choice:** Keep.

### Q4 — `src/pages/refund.astro` + `src/pages/terms.astro` (paid-product page-copy artifacts)

| Option | Description | Selected |
|--------|-------------|----------|
| Defer to Phase 17 | Phase 17 owns Buy→Free reposition, natural scope-mate. | |
| Delete in Phase 15 | Repo flipping public still mentioning $19 refund flow is confusing. | ✓ |
| Delete refund only; defer terms | Split decision — terms might be reusable boilerplate. | |

**User's choice:** Delete both in Phase 15.
**Notes:** Scope expansion vs. the LAND-01..05 letter. User explicit: zero paid-product surface in the working tree before the public flip.

---

## History rewrite posture

### Q1 — `git filter-repo` vs preserve-as-is

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve history as-is | No secret VALUES leaked; LemonSqueezy URL is public; $24/$19 was on PH launch day; honest lineage. | ✓ |
| Filter-repo to a clean slate | Rewrite history to remove `.agents/`, scripts, trial routes, LemonSqueezy strings. Force-push (private remote = safe). | |
| Squash everything into one commit pre-flip | Single 'Initial public release' commit. Heaviest history loss. | |

**User's choice:** Preserve as-is.
**Notes:** Portfolio thesis is "shipped paid, flipped OSS" — lineage is the story.

### Q2 — Audit deliverable shape

| Option | Description | Selected |
|--------|-------------|----------|
| Commit-as-summary in CONTEXT.md | Capture findings here + in execution SUMMARY.md. Matches Phase 13's APP-13 audit pattern. | ✓ |
| Standalone `SECRETS-AUDIT.md` in repo | Public-visible due-diligence doc. | |
| Audit logged in phase SUMMARY only | Same as option 1 — SUMMARY is local-only. | |

**User's choice:** Commit-as-summary in CONTEXT.md.

### Q3 — Forbidden-string list expansion

| Option | Description | Selected |
|--------|-------------|----------|
| LAND-05 base + repo-specific | Base + `lemonsqueezy|RESEND_API|KV_REST_API|hello@wrangleapp.dev|jkrush.lemonsqueezy.com`. | ✓ |
| LAND-05 base only | Spec-compliant; misses known repo surface. | |
| Run both audits separately and compare | Extra time, same hits. Overkill. | |

**User's choice:** Expanded list.

### Q4 — Verify method for Success Criteria #4 (`pnpm install && pnpm dev` clean checkout)

| Option | Description | Selected |
|--------|-------------|----------|
| `/tmp` clone, no `.env`, document expected warnings | Real test; document expected `RESEND_API_KEY` warning in README. | ✓ |
| `.env.example` with placeholder vars + README reference | Stronger onboarding; small surface. | |
| Hard-skip the feedback API when env missing | Most contributor-friendly, but code change to non-Phase-15 file. | |

**User's choice:** `/tmp` clone with documented warnings.

---

## Landing README depth

### Q1 — README richness

| Option | Description | Selected |
|--------|-------------|----------|
| Strict LAND-03 minimal | 4 sections, ~50 lines: what/dev/deploy/link + LICENSE. No story duplication. | ✓ |
| Minimal + 1-paragraph story snippet | Mild duplication; warmer entry. | |
| Full story replicated | Two READMEs to maintain. | |

**User's choice:** Strict LAND-03 minimal.

### Q2 — Deploy section specificity

| Option | Description | Selected |
|--------|-------------|----------|
| Generic 'deploys to Vercel; configured via `@astrojs/vercel`' | One paragraph, no project IDs or env-var details. | ✓ |
| Detailed Vercel setup (project ID + env vars + `vercel.json` link) | Useful for forkers; risk of leaking internal metadata. | |
| Skip deploy section entirely | Would violate LAND-03 spec. | |

**User's choice:** Generic mention.

### Q3 — Link-back to app repo placement

| Option | Description | Selected |
|--------|-------------|----------|
| Top + 'See also' footer | Top-line orientation + bottom mirror. Hard to miss. | ✓ |
| Single 'See also' at bottom only | Cleaner but easy to miss. | |
| Inline in 'What this is' section only | Tightest version. | |

**User's choice:** Top + footer.

### Q4 — README License section

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — small 'License' section at bottom | One line; mirrors app repo. Convention symmetric. | ✓ |
| No — GitHub auto-detects MIT in sidebar | Slightly tighter. | |
| Inline mention in 'See also' footer | Folds License + link into one block. | |

**User's choice:** Yes — small section at bottom.

---

## Claude's Discretion

- Exact `LICENSE` template wording (canonical SPDX MIT vs. GitHub default — both equivalent).
- README headings sentence case vs. title case (matched to Phase 14's symmetric tone).
- Order of git commits within the phase (deletions first, hygiene, LICENSE, README, audit).
- Whether to remove `scripts/` directory after the only file deletion (auto-handled by `git rm`).
- 1-plan vs 2-plan structure (ROADMAP expects 2; either acceptable given small scope).
- Dry-run `git filter-repo` once before locking D-09 in case audit surfaces something unexpected.
- Layout.astro default description neutralization wording (Phase 17 owns full rewrite).

## Deferred Ideas

- `/api/feedback` route reskin/removal → Phase 17.
- `.env.example` contributor onboarding → Phase 17.
- Hard-skip in `api/feedback.ts` when `RESEND_API_KEY` missing → Phase 17.
- `pencil/wrangle-landing-1.pen` removal → not anticipated; revisit only on confusion signal.
- `/refund` and `/terms` replacements → if Phase 17 wants a "Terms" boilerplate page.
- `src/pages/compare/*` (5 pages) + `src/data/use-cases.json` → Phase 17 (SITE-07).
- `src/pages/use-cases/[slug].astro` dynamic route → Phase 17.
- `public/videos/*.mp4` assets review → Phase 17.
- `scripts/og-image` (SITE-05) → Phase 17.
- Vercel adapter swap to static → Phase 17 if it drops the feedback form.
- GitHub Actions / CI → v1.4 (REQUIREMENTS Future).

### History posture revisit triggers (D-09)

Reconsider preserve-as-is ONLY if:
- Audit surfaces an actual secret VALUE in any historical commit.
- Old commits create portfolio-review embarrassment in a future context.

Neither is anticipated; D-09 stands.
