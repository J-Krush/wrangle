---
phase: 17-landing-page-repositioning
verified: 2026-05-23T00:00:00Z
status: passed
score: 5/5 success criteria verified (10/10 requirements satisfied, 8/8 plan-level truths verified)
overrides_applied: 0
---

# Phase 17: Landing Page Repositioning — Verification Report

**Phase Goal:** The live `wrangleapp.dev` site presents Wrangle as a free, open-source macOS markdown editor for AI devs — with a working "Download for macOS" CTA pointing at the real v1.3.0 GitHub Release DMG, a "Star on GitHub" CTA, a story section, and zero remaining "Buy $24" / pricing surface.

**Verified:** 2026-05-23
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### ROADMAP.md Success Criteria

| # | Success Criterion | Status | Evidence |
|---|-------------------|--------|----------|
| 1 | Hero dual CTA + no `$24`/`Buy Wrangle` site-wide | VERIFIED | Live homepage shows 3× `Download for macOS` (header + hero + final-CTA) and 3× `Star on GitHub` with literal `https://github.com/J-Krush/wrangle/releases/latest` and `https://github.com/J-Krush/wrangle` hrefs; live grep returns 0 hits for `$24`, `Buy Wrangle`, `$19`. Hero H1: "native macOS markdown editor for AI agents. free and open source." |
| 2 | Pricing page deleted with smart 404 handling old links | VERIFIED | No `pricing.astro` / `buy.astro` exists in `Landing Page/src/pages/`. `astro.config.mjs` has no `redirects` block. Live: `curl /buy`, `/pricing`, `/refund`, `/terms` all return HTTP 404 and serve the smart 404 body (`page not found` + `retired in the OSS flip`). |
| 3 | Story section covering PH launch + Reddit ads + thesis + OSS pivot | VERIFIED (with documented user deviations) | 4-paragraph Story section live on homepage with `bg-card border-y border-border-subtle` container. Beats: (1) workflow scatter origin, (2) category thesis, (3) PH/Reddit/marketing detour, (4) OSS pivot. Contains `product hunt`, `reddit ads`. User-approved deviations (documented in 17-02-SUMMARY): dropped literal date `2026-04-22` and verbatim phrase `distribution is harder than product` per Plan 17-02 checkpoint v4 approval. |
| 4 | SEO + social metadata reflect OSS positioning; no Pro/Trial/Premium on feature pages | VERIFIED | Live `<title>`: `wrangle: free macOS markdown editor for AI developers`. Live `<meta name="description">`: `Wrangle is a free, open source native macOS workspace for AI developers...`. OG title + Twitter title both bound to the same OSS string. `summary_large_image` Twitter card type preserved. OG image `/images/og-image.png` reused per D-17. Repo-wide grep across `Landing Page/src/`: 0 hits for `$19`, `$24`, `buy — `, `try free`, `lemonsqueezy`. JSON-LD has `creator` Person and 0 `Offer` block. |
| 5 | Deploy to wrangleapp.dev with working Download CTA | VERIFIED | Live homepage returns HTTP 200; 5 compare pages, 3 target use-cases, `/feedback` all return 200. Download CTA href is the canonical literal `https://github.com/J-Krush/wrangle/releases/latest`. **Note:** the URL currently returns HTTP 404 unauthenticated — this is EXPECTED per CONTEXT.md (D-10 LOCKED) until Phase 18 publishes the v1.3.0 GitHub Release. Wiring is correct; the binary becomes available when Phase 18 ships. Vercel atomic deploys provide rollback (D-19). |

**Score:** 5/5 success criteria verified.

### PLAN-Level Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 (17-01) | `/buy` redirect removed entirely; `/buy` returns 404 live | VERIFIED | `astro.config.mjs` has no `redirects` property (lines 1-15); no `buy`/`lemonsqueezy`/`redirects` substring. Live `curl -sILo /dev/null -w "%{http_code}" https://wrangleapp.dev/buy` → 404. |
| 2 (17-01) | Hero dual CTA pointing at locked URLs | VERIFIED | `index.astro:64-78` contains the hero dual CTA pair with literal `releases/latest` (primary) and `github.com/J-Krush/wrangle` (secondary) hrefs. Live verified: 3 `Download for macOS` + 3 `Star on GitHub`. |
| 3 (17-01) | Header dual CTA at compact size; `try free` removed | VERIFIED | `index.astro:39-53` renders header dual CTA with `px-4 py-2 text-sm` (Surface 1 size). Repo-wide grep `try free` → 0 hits. |
| 4 (17-01) | Smart 404.astro catches retired URLs with H1 + body + dual CTA | VERIFIED | `404.astro` exists; renders `404. page not found.` H1 + `retired in the OSS flip` paragraph + dual CTA pair + `noindex, nofollow` meta. Live `/buy`, `/pricing`, `/refund`, `/terms` all return 404 with this body. |
| 5 (17-01) | wrangle-1.2-sizzle.mp4 video preserved in hero | VERIFIED | `index.astro:81-89` contains `<video src="/videos/wrangle-1.2-sizzle.mp4" autoplay loop muted playsinline>` per D-13. |
| 6 (17-01) | Footer attribution `Built by J Krush · jkrush.dev · MIT` (D-09) | VERIFIED | `index.astro:288-293` carries the verbatim three-part attribution. Live grep on `/` returns 1× `Built by J Krush`. Repo-wide: every modified page (`404.astro`, 5 compare pages, `[slug].astro`, `feedback.astro`) has 1× `Built by J Krush`. |
| 7 (Story 17-02) | Story section visually distinct without new Tailwind tokens | VERIFIED | `index.astro:241` uses `bg-card border-y border-border-subtle flex flex-col items-center px-5 lg:px-[200px] py-16 lg:py-[100px]`. Inner column `max-w-[700px]`. All tokens pre-existing in palette (per UI-SPEC §Color). |
| 8 (17-02) | Page title + description + OG/Twitter cards reflect OSS positioning | VERIFIED | Live `<title>` and `<meta name="description">` both carry the locked OSS strings. OG/Twitter inherit via the Layout.astro pass-through pattern (verified in `Layout.astro:11`). Twitter `summary_large_image` preserved. |
| 9 (17-02) | JSON-LD has no `offers` block; has `creator` Person block | VERIFIED | Live JSON-LD on `/`: 0 hits for `"@type": "Offer"` and `"price": "19"`. 1 hit for `"creator":{"@type":"Person","name":"J Krush","url":"https://jkrush.dev"}`. Legacy `author` `J-Krush` preserved adjacent. Parses as valid JSON. |
| 10 (17-03) | All 5 compare pages have header single CTA + final-CTA dual + locked footer + tagline | VERIFIED | Live verification (per slug): Download=2, Star=1, Footer=1, Tagline≥3, $19=0, try_free=0. UI-SPEC Surface 5 single-CTA-header pattern applied. |
| 11 (17-03) | use-cases.json 3 target entries cleaned; 17 untouched; 7 additional caught in audit | VERIFIED | All 20 entries present (`node -e JSON.parse...` succeeds). The 3 target entries have 0 `$19`/`one-time` in metaDescription+body. JSON-wide audit: 0 entries with `$19`, `one-time`, or `purchase`. The Plan 17-03 Task 5 audit caught 7 extra `$19` survivors in non-target entries and fixed them in commit `e156f56` (documented deviation #3 in 17-03-SUMMARY). |
| 12 (17-03) | use-cases [slug].astro template applies all Phase 17 patterns; guarantee section deleted | VERIFIED | Source grep: `Download for macOS` = 3, `Star on GitHub` = 3, `Built by J Krush` = 1, 30-day money-back guarantee = 0. Live `/use-cases/{3 slugs}` all return 200 with DL=3 / Star=3 / Footer=1. |
| 13 (17-03) | feedback.astro footer matches Pattern D; body untouched | VERIFIED | Source: `Built by J Krush` = 1, `wrangle-feedback` legacy = 0, `refund/billing/paid customer/subscriber` = 0. Live `/feedback` returns 200 with new footer. |
| 14 (17-03 D-03) | Full-repo zero hits for hard-locked forbidden patterns | VERIFIED | Cross-repo grep over `src/`, `astro.config.mjs`, `package.json`: `$19` = 0, `$24` = 0, `buy — ` = 0, `buy --` = 0, `try free` = 0, `LemonSqueezy` = 0, `dl.wrangleapp.dev` / `APP_VERSION` / `downloadUrl` = 0. Soft pattern `one-time` survives in exactly 3 documented exemption sites (see below). |
| 15 (17-03 D-19) | Live deploy to wrangleapp.dev via @astrojs/vercel adapter; reversible | VERIFIED | All 14 expected URLs return correct status codes. Vercel adapter unchanged in `astro.config.mjs`. Per Plan 17-03 deploy: previous-deploy URL captured for one-click rollback. |
| 16 (D-20) | Anti-regression: linear-history standard commits only | VERIFIED | 11 Phase 17 commits identified by their SUMMARY SHAs: `28d1737`, `e907052`, `8464062`, `6afd886`, `62a6913`, `2ee8c4f`, `3df4584`, `eb9f2f0`, `835335f`, `e156f56`, `bfd8e1f`. All present in `git log`. No force-push, no filter-repo signatures. |

**Score:** 16/16 plan-level truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Landing Page/astro.config.mjs` | redirects block removed; preserve site/adapter/output | VERIFIED | 15-line file. No `redirects`, `buy`, or `lemonsqueezy`. `site:`, `adapter: vercel()`, `output: 'static'` preserved. |
| `Landing Page/src/pages/index.astro` | rewritten header/hero/story/final-CTA/footer | VERIFIED | 317 lines; all surfaces match the locked patterns; Story section at lines 241-256; final-CTA at lines 266-284. |
| `Landing Page/src/pages/404.astro` | new smart 404 with H1 + body + dual CTA + noindex | VERIFIED | 76 lines; full header + centered min-h-screen content + footer; `noindex, nofollow` meta present. |
| `Landing Page/src/layouts/Layout.astro` | OSS default description; OG image untouched | VERIFIED | `Layout.astro:11` carries locked OSS description; `ogImage` default `/images/og-image.png` preserved (D-17); `summary_large_image` preserved. |
| `Landing Page/src/pages/compare/{cursor,ia-writer,obsidian,typora,vs-code}.astro` | Phase 17 sweep on all 5 | VERIFIED | All 5 live pages return 200 with Download=2 (header + final-CTA), Star=1 (final-CTA), Footer=1, Tagline≥3. |
| `Landing Page/src/data/use-cases.json` | 20-entry JSON valid; 0 paid-language across all entries | VERIFIED | Parses; 20 entries; 0 entries with `$19`, `one-time`, or `purchase`. Plan 17-03 Task 5 audit fixed 7 extras beyond the original D-15 scope. |
| `Landing Page/src/pages/use-cases/[slug].astro` | Phase 17 patterns + guarantee deleted | VERIFIED | 3 Download, 3 Star, 1 Footer, 0 forbidden strings, 0 30-day money-back. |
| `Landing Page/src/pages/feedback.astro` | footer Pattern D; body untouched | VERIFIED | Built by J Krush = 1, wrangle-feedback = 0, paid-customer terms = 0. /api/feedback route untouched (separate file). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|------|--------|---------|
| index.astro hero | github.com/J-Krush/wrangle/releases/latest | primary CTA href | WIRED | Live `<a href="https://github.com/J-Krush/wrangle/releases/latest">Download for macOS</a>` rendered in hero. |
| index.astro hero | github.com/J-Krush/wrangle | secondary CTA href | WIRED | Live `<a href="https://github.com/J-Krush/wrangle"><svg>...</svg>Star on GitHub</a>` rendered in hero. |
| index.astro header | github.com/J-Krush/wrangle/releases/latest | primary header CTA | WIRED | Same href, header-size class string. |
| 404.astro | Layout.astro shell | `import Layout from "../layouts/Layout.astro"` | WIRED | Layout import on 404.astro:2; renders via `<Layout title="404: wrangle" description="Page not found.">`. |
| Layout.astro default description | `<meta name="description">` + OG + Twitter | props pass-through | WIRED | Layout.astro:26, :35, :42 all bind to `{description}` prop. Live HTML shows the OSS string in all three meta tags. |
| index.astro `<Layout title>` | live `<title>` element | Layout title prop | WIRED | Live: `<title>wrangle: free macOS markdown editor for AI developers</title>`. |
| compare/*.astro (5) | releases/latest | header + final-CTA href | WIRED | Each file has 2 hits (per URL Contract census: cursor=2, ia-writer=2, obsidian=2, typora=2, vs-code=2). |
| use-cases/[slug].astro | releases/latest | header + hero + final-CTA | WIRED | 3 hits per Plan 17-03 Task 3 surface map. |
| Vercel production deploy | wrangleapp.dev | @astrojs/vercel adapter + git push origin main | WIRED | Live homepage returns 200; deploy commit `bfd8e1f` triggered Vercel webhook auto-deploy. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| index.astro Story section | static 4-paragraph copy | inline HTML in `<section>` | yes (user-approved verbatim copy) | FLOWING |
| use-cases/[slug].astro body | `paragraphs` from use-cases.json via getStaticPaths | JSON file with 20 entries | yes (live URLs return correct slug content) | FLOWING |
| 404.astro | static H1 + paragraph + CTA | inline content | yes (rendered live for /buy /pricing /refund /terms) | FLOWING |
| Layout.astro `<meta name="description">` | `description` prop default | Layout.astro:11 string | yes (live HTML carries OSS string) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Homepage returns 200 | `curl -sILo /dev/null -w "%{http_code}" https://wrangleapp.dev/` | 200 | PASS |
| /buy returns 404 with smart body | `curl -sL https://wrangleapp.dev/buy \| grep -c 'page not found'` | 1 | PASS |
| All 5 compare pages return 200 | `curl -sILo /dev/null -w "%{http_code}"` × 5 | all 200 | PASS |
| All 3 target use-case pages return 200 | curl × 3 | all 200 | PASS |
| /feedback returns 200 | curl | 200 | PASS |
| Homepage Download CTA count = 3 | live grep | 3 | PASS |
| Homepage Star on GitHub count = 3 | live grep | 3 | PASS |
| Homepage JSON-LD has 0 Offer | live grep | 0 | PASS |
| Homepage JSON-LD has 1 creator | live grep | 1 | PASS |
| 404 page CTA count = 2 each | live grep | 2 each | PASS |
| Use-cases.json has 20 entries (data integrity) | `node JSON.parse` | 20 entries, valid JSON | PASS |
| All 11 Phase 17 commits present in landing repo | `git log -1 <sha>` × 11 | all present | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| (no probes declared in plans for this phase; project does not use `scripts/*/tests/probe-*.sh` for landing-page work) | — | — | N/A |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SITE-01 | 17-01 | Hero dual CTA (Download + Star on GitHub) replacing Buy Wrangle | SATISFIED | Live hero shows dual CTA pair; 0 `Buy Wrangle` / `$24` hits site-wide. |
| SITE-02 | 17-01 | Pricing page deleted / rewritten; no internal "Pricing"/"Buy" links | SATISFIED | No `pricing.astro`/`buy.astro` files; `/buy` redirect removed; nav has no Pricing entry. |
| SITE-03 | 17-02 | Story section covering PH launch / Reddit / thesis / OSS pivot | SATISFIED | 4-paragraph Story section live; beats present (with user-approved date drop per 17-02 checkpoint). |
| SITE-04 | 17-01 | Top-nav updated: no Buy/Pricing; GitHub link added | SATISFIED | Header dual CTA with `Star on GitHub` (GitHub icon + label); `try free` button gone. |
| SITE-05 | 17-02 | SEO metadata (title + description + OG) reflects OSS positioning | SATISFIED | Live `<title>`, `<meta description>`, `og:title`, `og:description` all carry OSS strings; OG image preserved per D-17. |
| SITE-06 | 17-02 | Twitter / X social-card metadata updated | SATISFIED | Live `twitter:title` and `twitter:description` carry OSS strings; `summary_large_image` card type preserved. |
| SITE-07 | 17-03 | Feature pages reviewed; no Pro/Trial limit/Premium copy | SATISFIED | All 5 compare pages, [slug].astro template, 3 target use-cases entries swept; D-03 full audit passes for hard-locked patterns; 7 extra `$19` survivors caught and fixed by Plan 17-03 Task 5 audit. |
| SITE-08 | 17-01 | Download CTA points at GitHub Release URL | SATISFIED | All 18 Download CTAs across repo use the canonical literal `https://github.com/J-Krush/wrangle/releases/latest`. The URL returns 404 unauth currently (expected per D-10 / CONTEXT.md deferred — flips to 200 when Phase 18 publishes the release). |
| SITE-09 | 17-03 | Deployed to production target; deploy reversible | SATISFIED | Live wrangleapp.dev returns 200 with new positioning; Vercel atomic deploys provide rollback (D-19). |
| SITE-10 | 17-01 | 404.astro fallback in place for retired pages | SATISFIED | `404.astro` exists and serves on `/buy`, `/pricing`, `/refund`, `/terms` (all return 404 with smart 404 body). |

**Coverage:** 10/10 requirements satisfied. No orphaned requirements (all 10 SITE-XX IDs appear in exactly one plan).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `index.astro` | 250 | `one-time` substring in user-approved Story copy | Info | Describes the historical paid-product model in the OSS-pivot story paragraph ("the math never quite worked on a small one-time price..."). User-approved verbatim copy from Plan 17-02 v4 checkpoint. Not a Wrangle pricing claim. Acceptable per Plan 17-03 `<interfaces>` "one-time hits in user-supplied story copy [...] are permissible IF the user explicitly approves them" — user did. |
| `compare/ia-writer.astro` | 212 | `$50 one-time` in comparison table competitor price cell | Info | Competitor pricing fact (iA Writer's Mac App Store price). D-14 exemption: competitor-pricing facts preserved; only Wrangle-side claims must be rewritten. Documented in 17-03-SUMMARY deviation #2. |
| `compare/typora.astro` | 207 | `$15 one-time` in comparison table competitor price cell | Info | Competitor pricing fact (Typora). D-14 exemption: same logic as ia-writer. Documented in original Plan 17-03 Task 2 acceptance criteria as the ONE place where `one-time` is permissible. |

No 🛑 BLOCKER or ⚠️ WARNING anti-patterns found. No `TBD`/`FIXME`/`XXX` debt markers in modified files. No empty implementations, no placeholder copy, no stub components.

### Plan-Level Deviations Acknowledged (per prompt directives)

1. **Plan 17-02 acceptance: `grep -c '2026-04-22' ≥ 1`** — user-direction drop at Plan 17-02 Task 2 v4 checkpoint. Documented in 17-02-SUMMARY deviation #1. Acceptable.
2. **Plan 17-02 acceptance: `grep -i 'distribution is harder than product' ≥ 1`** — user-approved near-paraphrase ("the math never quite worked on a small one-time price, and marketing isn't work i want to own"). Plan 17-02 acceptance clause permits "near-paraphrase the user explicitly accepts". Documented in 17-02-SUMMARY deviation #2. Acceptable.
3. **Plan 17-03 Task 7 live grep `2026-04-22` returns 0** — inherits from #1. Acceptable.
4. **Plan 17-01 Task 4 / Plan 17-03 Task 4 `dist/404.html` and `dist/feedback/index.html` paths** — actual path is `dist/client/404.html` etc due to @astrojs/vercel adapter shape. Files exist; path assertion wording was wrong, not the implementation. Documented in 17-01-SUMMARY deviation #1 and 17-03-SUMMARY deviation #4. Acceptable.
5. **Plan 17-01 acceptance: hero H1 with em-dash → period sweep** — approved with em-dash at Plan 17-01 Task 2 checkpoint, later swept to period at Plan 17-03 Task 6 user direction. Documented in 17-03-SUMMARY commit `bfd8e1f`. Acceptable (live H1: `"native macOS markdown editor for AI agents. free and open source."`).
6. **Plan 17-03 Task 6 post-checkpoint user-direction commit `bfd8e1f`** — relocated Story section to between Full Workspace Overview and AI Disclosure (replacing the legacy Anti-Pitch position); stripped em-dashes site-wide from prose. Both improvements caught at user pre-deploy review. Live verified. Acceptable.

### Human Verification Required

None required for automated verification — all live URL checks, source greps, JSON parsing, and metadata propagation can be (and were) verified programmatically.

**Optional visual smoke-tests the user may still want to run:**

- Visual rendering of the Story section background `bg-card` against `bg-page` (verified to be visually distinct per UI-SPEC §Color).
- OG-image preview unfurl on Twitter/X / LinkedIn / Slack (the existing OG image was preserved per D-17 — no regeneration was attempted, which is the intended D-17 behavior).
- Visual flow of the homepage scroll order with the relocated Story section (per `bfd8e1f` it now sits between the workspace overview and the AI disclosure, near the end of the page rather than between Logo+Tagline and Features).

These are post-launch UX observations rather than gating verifications.

### Gaps Summary

**No gaps.** All 5 ROADMAP.md Success Criteria are observably true on the live `wrangleapp.dev` site. All 10 SITE-XX requirements are satisfied with traceable evidence. All 16 plan-level must-have truths verified. All artifacts exist at the expected paths and pass Levels 1–4 (exists, substantive, wired, data flowing). All documented plan deviations are user-approved and recorded in the per-plan SUMMARYs.

The only "soft" patterns surviving in the repo are 3 instances of `one-time` — all 3 are documented exemptions per Plan 17-02 (user-approved Story copy) and D-14 (competitor pricing cells preserved). The hard-locked forbidden patterns (`$19`, `$24`, `buy — `, `try free`, `LemonSqueezy`, `dl.wrangleapp.dev`, `APP_VERSION`, `downloadUrl`) all return 0 hits.

The Download CTA's current HTTP 404 status (`https://github.com/J-Krush/wrangle/releases/latest` unauthenticated) is the EXPECTED end-of-Phase-17 state per D-10 / Phase 13 LOCKED and the CONTEXT.md deferred item. The wiring is correct; the binary becomes available when Phase 18 publishes the v1.3.0 GitHub Release.

---

_Verified: 2026-05-23_
_Verifier: Claude (gsd-verifier)_
