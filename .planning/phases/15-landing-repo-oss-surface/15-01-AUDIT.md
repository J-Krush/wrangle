# Phase 15 Plan 01 — D-11 Audit Working Artifact

**Audit date:** 2026-05-20
**Repo audited:** `wrangle-landing` at `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page`
**Tree state:** post-Task-1 (3 deletion bundles) + post-Task-2 (Layout.astro neutralization + .astro/ untrack + .gitignore append)
**History posture going in:** D-09 — preserve as-is, no `git filter-repo`, no force-push
**Total commits in history:** 23
**Audit file destination:** `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/15-landing-repo-oss-surface/15-01-AUDIT.md` (planning host repo — D-10 explicitly rejects a public-repo audit doc)

---

## Audit Regex (D-11, exact pattern — case-insensitive)

```
secret|api[-_]key|token|plausible|fathom|posthog|lemonsqueezy|RESEND_API|KV_REST_API|hello@wrangleapp\.dev|jkrush\.lemonsqueezy\.com
```

Exclusions applied to the working-tree grep (D-04 / D-05 rationale):

- `:!pencil/*` — `wrangle-landing-1.pen` is encrypted at rest (D-04); its bytes may false-match.
- `:!.astro/*` — the build cache was just untracked in Task 2 Edit B (D-05); files still on disk but no longer the repo's responsibility.

No exclusions on the history grep (full repo lineage).

---

## Working-tree Result (Working-tree result)

**Total raw line count (post-exclusions):** 96
**Files with hits:** 12

### Categorization

Every surviving working-tree hit is classified into one of four categories:

- **(a) env-var NAME reference** — token like `RESEND_API_KEY` referenced as an identifier in source, never as a value
- **(b) public URL artifact** — a URL that is publicly visible to anyone with the link (not credentials)
- **(c) historical pricing copy** — `$19` / `$24` strings still on disk (should be near-zero after Task 2 Edit A neutralization of `Layout.astro`; non-zero only in Phase-17-owned copy/data files)
- **(d) ACTUAL SECRET VALUE** — a credential string committed to disk (MUST be zero)

### Hit breakdown by file

| File | Hits | Category | Notes |
| ---- | ---- | -------- | ----- |
| `astro.config.mjs` | 2 | **(b) public URL artifact** | Lines 16, 17: the `/buy` redirect declaration. URL is `https://jkrush.lemonsqueezy.com/checkout/buy/8860d1f0-c122-4ab6-8528-ee727d3065e3` — the public buyer-facing LemonSqueezy checkout endpoint. CONTEXT.md `<canonical_refs>` explicitly puts `astro.config.mjs` in the "do not touch" list (Phase 15 scope boundary). Phase 17 SITE-05 rewrites this when repositioning from `/buy` → `/download`. **Plan-internal acceptance criterion conflict acknowledged**: the plan's `<acceptance_criteria>` predicted zero `jkrush.lemonsqueezy.com` hits in the working tree, but the file the acceptance was implicitly relying on (`.astro/data-store.json`) is now untracked via Task 2 Edit B — yet the source-of-truth declaration in `astro.config.mjs` survives by plan design. Hit catalogued per the acceptance's escape clause: *"If non-zero, the audit MUST catalogue every remaining hit before the verify clause is allowed to pass."* |
| `pnpm-lock.yaml` | 17 | **(a) env-var NAME reference** | All hits are npm package-name substrings: `comma-separated-tokens`, `space-separated-tokens`, `micromark-util-subtokenize`, `@azure/keyvault-secrets`. Coincidental regex matches on `token` / `secret` substrings inside legitimate package identifiers. Zero credentials, zero secret values. Lockfile is committed deliberately for reproducible installs. |
| `src/data/use-cases.json` | 31 | **(a) env-var NAME** + **(c) historical pricing copy** | Two patterns: (1) "token counting" / "token count" / "tokens" — feature-description copy that matches the regex's `token` substring (~28 hits — feature copy, not credentials); (2) `$19 one-time.` / `$19` substrings in `metaDescription` and `body` fields (3+ hits — paid-product copy carried over from the v1.2 site). Phase 15 does NOT modify this file (CONTEXT.md `<deferred>` explicitly carves it out: *"Phase 17 (SITE-07 'feature pages reviewed for Pro / Trial / Premium copy') owns the audit and reposition"*). |
| `src/layouts/Layout.astro` | 1 | **(a) env-var NAME** | Line 11 (Task 2 Edit A post-state): `"... token counting."` — feature-description substring match, NOT pricing. The `$19 one-time.` sentence WAS removed by Task 2 Edit A; the surviving hit is the legitimate `token counting` feature claim. |
| `src/pages/api/feedback.ts` | 2 | **(a) env-var NAME reference** | Line 18: `const apiKey = import.meta.env.RESEND_API_KEY;` (env-var NAME, not value). Line 76: `from: 'Wrangle Survey <hello@wrangleapp.dev>'` (public email address — the marketing site's outbound `from` address, intentional). File kept per D-03. |
| `src/pages/compare/cursor.astro` | 4 | **(a) env-var NAME** | Feature-copy substring matches on "token counting" / "token count". |
| `src/pages/compare/ia-writer.astro` | 6 | **(a) env-var NAME** + **(c) pricing** | "token counting" feature copy (5 hits) + line 226: `$19, one-time` (1 hit — pricing copy). Phase 17 (SITE-07) owns reposition. |
| `src/pages/compare/obsidian.astro` | 5 | **(a) env-var NAME** | Feature-copy substring matches on "token counting" / "token count". |
| `src/pages/compare/typora.astro` | 5 | **(a) env-var NAME** | Feature-copy substring matches on "token counting" / "token count". |
| `src/pages/compare/vs-code.astro` | 4 | **(a) env-var NAME** | Feature-copy substring matches on "token counting" / "token count". |
| `src/pages/index.astro` | 1 | **(a) env-var NAME** | Line 123: `<span>token counting</span>` — feature copy. |

**Category totals (working tree):**

| Category | Count | Notes |
| -------- | ----- | ----- |
| (a) env-var NAME reference / feature-copy substring | ~88 | Includes pnpm-lock.yaml package names, feature copy "token counting", env-var IDENTIFIER references (`RESEND_API_KEY`). All benign. |
| (b) public URL artifact | 2 | `astro.config.mjs` `/buy` redirect (lines 16, 17) — public LemonSqueezy checkout URL. Phase 17 reposition territory. |
| (c) historical pricing copy | ~6 | `$19` / `$24` mentions in `src/data/use-cases.json` and `src/pages/compare/ia-writer.astro`. Phase 17 SITE-07 reposition territory. Layout.astro pricing was neutralized in Task 2 Edit A. |
| **(d) ACTUAL SECRET VALUE** | **0** | **Zero credentials committed to the working tree.** |

---

## History Result (History result)

**Total raw line count (full `git rev-list --all`, uncapped):** 1971
**Unique `file:line:content` tuples (deduped across commits):** 236
**Files with at least one hit anywhere in history:** 19

### Highest-risk surfaces in history (categorized)

| File (historical) | Surface | Category | Rationale |
| ----------------- | ------- | -------- | --------- |
| `.agents/ad-copy-plan.md` (deleted in Task 1) | "LemonSqueezy thank-you redirect" mentions, ad-spend plan, `$19` pricing | **(a)** + **(c)** | Internal ad-campaign planning copy. No secret values; describes a public LemonSqueezy thank-you URL and prior pricing. D-01 removed from working tree; D-09 preserves history. |
| `.agents/community-posts.md` (deleted in Task 1) | "Sold direct (DMG download via LemonSqueezy). 30-day money-back guarantee." with $10/$19/$24 price points | **(c)** | Three pricing-iteration snapshots (the price went $10 → $19 → $24 across drafts). All publicly visible during Product Hunt launch. No secret values. |
| `.agents/product-marketing-context.md` (deleted in Task 1) | "Sold via LemonSqueezy (direct download DMG)" | **(a)** | Public-fact description of the sales channel. No secret values. |
| `.astro/data-store.json` (untracked in Task 2) | `/buy` redirect target `jkrush.lemonsqueezy.com/checkout/buy/<uuid>` | **(b)** | Public buyer-facing LemonSqueezy checkout URL. Same URL category as `astro.config.mjs`. D-05 untrack closes the future re-track vector; D-09 leaves it in history. |
| `astro.config.mjs` (kept, not modified) | `/buy` redirect declaration | **(b)** | Public LemonSqueezy checkout URL. Phase 17 SITE-05 rewrites. |
| `scripts/send-survey.mjs` (deleted in Task 1) | `RESEND_API_KEY`, `KV_REST_API_URL`, `KV_REST_API_TOKEN`, `hello@wrangleapp.dev`, `LemonSqueezy customers` | **(a)** | Env-var NAMES referenced via `process.env.*` — never the values. `hello@wrangleapp.dev` is the public marketing email. No secret values. |
| `src/pages/api/feedback.ts` (kept, not modified) | `RESEND_API_KEY`, `hello@wrangleapp.dev` | **(a)** | Env-var NAME + public email. No secret values. |
| `src/pages/api/trial/*.ts` (deleted in Task 1) | `trial:email:*` / `trial:hw:*` KV key prefixes | **(a)** | Vercel KV key namespace strings (`trial:email:`, `trial:hw:`) — not secrets, just internal key prefixes. |
| `src/pages/terms.astro` (deleted in Task 1) | "wrangle is a one-time purchase processed through LemonSqueezy" | **(a)** | Plain-English description of the prior sales channel. No secrets. |
| `dist/index.html` (build output committed in an early commit, since superseded) | Token-count feature copy | **(a)** | Build-output snapshot. No credentials. |
| `pencil/wrangle-landing-1.pen` | Encrypted bytes occasionally matching the regex | (excluded) | D-04 keeps the file; the bytes are encrypted noise. Excluded from working-tree audit; some matches surface in history grep as expected. |
| `pnpm-lock.yaml` | npm package-name substrings (`comma-separated-tokens`, `@azure/keyvault-secrets`, etc.) | **(a)** | Coincidental regex hits on legitimate package identifiers. |
| `src/data/use-cases.json` | Feature copy + `$19` pricing snippets | **(a)** + **(c)** | Phase-17 reposition territory. |
| `src/pages/compare/*.astro` | Feature copy + `$19` snippets | **(a)** + **(c)** | Phase-17 reposition territory. |
| `src/pages/index.astro` | Feature copy + `$19` / `$24` snippets in pricing/CTA blocks | **(a)** + **(c)** | Phase 17 reposition. |
| `src/layouts/Layout.astro` | Default description with `$19 one-time` (pre-Task-2 commits); feature copy (post-Task-2 commits) | **(c)** then **(a)** | History preserves prior versions; current state is neutralized. |
| `vercel.json` (if present in any commit) | (none matched) | — | No vercel.json hits in any commit. |

**Category totals (history):**

| Category | Approx count | Notes |
| -------- | ------------ | ----- |
| (a) env-var NAME / package-name / feature-copy substring | ~1900 | Vast majority of the 1971 raw hits. `pnpm-lock.yaml` alone contributes ~150 hits per commit × multiple commits = ~1500+. |
| (b) public URL artifact | ~50 | Multiple historical revisions of the `/buy` redirect in `astro.config.mjs` (UUID `866499` → `8860d1f0-c122-4ab6-8528-ee727d3065e3`) and in `.astro/data-store.json` build cache. All variants are public LemonSqueezy URLs. |
| (c) historical pricing copy | ~30 | `$10` / `$19` / `$24` in `.agents/*`, `src/data/use-cases.json`, `src/pages/compare/*`, `src/pages/index.astro`, `src/layouts/Layout.astro` across prior versions. |
| **(d) ACTUAL SECRET VALUE** | **0** | **Zero credentials ever committed to this repo's history.** |

### Specific D-11 audit promises verified

- `RESEND_API_KEY` appears only as `process.env.RESEND_API_KEY` / `import.meta.env.RESEND_API_KEY` (env-var NAME). **No `re_...` Resend API value committed.**
- `KV_REST_API_URL` / `KV_REST_API_TOKEN` appear only as `process.env.KV_REST_API_*` (env-var NAMES) in the deleted `scripts/send-survey.mjs` and deleted `src/pages/api/trial/*.ts`. **No KV credentials, no Vercel KV URL/token VALUES committed.**
- `LemonSqueezy` URLs are all the public `jkrush.lemonsqueezy.com/checkout/buy/<uuid>` checkout endpoint — anyone with the URL can attempt to buy. **No LemonSqueezy API key, no webhook secret, no store secret committed.**
- `hello@wrangleapp.dev` is a public outbound marketing email address (sender on the feedback form). **Not credentials.**
- `plausible|fathom|posthog`: **zero hits anywhere in working tree or history.** No analytics-vendor surface ever existed in this repo.

---

## D-09 Branch Decision

## D-09 stands: history posture preserved, zero secret values found

- Category (d) count in working tree: **0**
- Category (d) count in history: **0**
- No `git filter-repo` invocation needed.
- No force-push needed.
- Phase 18 (FLIP-03) can flip this repo public with zero credential exposure.
- The public LemonSqueezy URL surfaces in working tree (`astro.config.mjs`) and history are honest portfolio narrative — "shipped paid via LemonSqueezy, flipped OSS" — and exactly what D-09 anticipated. Phase 17 SITE-05 rewrites the `/buy` redirect when repositioning the site copy.

### History posture revisit triggers (NOT tripped)

Per CONTEXT.md `<deferred>` — reconsider D-09 ONLY if:

- ~~The audit (D-11) surfaces an actual secret VALUE in any historical commit.~~ → Did not happen. Zero (d)-category hits.
- A future contributor (or the user) files an issue saying the old commits embarrass them in a portfolio-review context. → Not applicable to this plan.

**D-09 stands. Plan 02 proceeds.**

---

## Plan-Internal Inconsistency Acknowledged (NOT a deviation)

The plan's Task 3 `<acceptance_criteria>` line predicted `jkrush.lemonsqueezy.com` count = 0 in the post-Task-1+2 working tree, with the rationale: *"Task 1 Bundle C link-fixup + Task 2 Edit B `.astro/` untrack are responsible for removing all working-tree references."*

Reality: **1 surviving line** in `astro.config.mjs:17` — the `/buy` redirect declaration. The plan's `<must_haves>` and CONTEXT.md `<canonical_refs>` both explicitly put `astro.config.mjs` in the "do not touch" list (`"package.json, astro.config.mjs, and the @astrojs/vercel adapter are NOT modified (Phase 15 scope boundary)"`).

These two statements in the same plan document are mutually contradictory. The plan provides an escape valve in the acceptance line itself: *"If non-zero, the audit MUST catalogue every remaining hit before the verify clause is allowed to pass."* That cataloguing is done here (see "Hit breakdown by file" → `astro.config.mjs`).

**Outcome:** D-09 stands (category-(d) count = 0). The `astro.config.mjs` `/buy` redirect is a public-URL artifact (category (b)) and is Phase 17 SITE-05's reposition territory. No history rewrite indicated.

---

## Verification of the No-History-Rewrite Posture

```bash
cd "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page" && git reflog | grep -ciE 'filter-repo|reset --hard|push.*force'
```

Returns: **0** — no history-rewriting command was invoked during this audit.
