---
phase: 17-landing-page-repositioning
plan: 03
status: complete
completed: 2026-05-23
requirements_addressed: [SITE-07, SITE-09]
decisions_applied: [D-03, D-14, D-15, D-16, D-19, D-20]
files_modified:
  - "Landing Page/src/pages/compare/cursor.astro"
  - "Landing Page/src/pages/compare/ia-writer.astro"
  - "Landing Page/src/pages/compare/obsidian.astro"
  - "Landing Page/src/pages/compare/typora.astro"
  - "Landing Page/src/pages/compare/vs-code.astro"
  - "Landing Page/src/data/use-cases.json"
  - "Landing Page/src/pages/use-cases/[slug].astro"
  - "Landing Page/src/pages/feedback.astro"
  - "Landing Page/src/pages/index.astro"
  - "Landing Page/src/pages/404.astro"
  - "Landing Page/src/layouts/Layout.astro"
commits:
  - sha: "2ee8c4f"
    repo: "wrangle-landing"
    message: "chore(site-07): apply Phase 17 OSS sweep to compare/cursor.astro (D-14)"
    task: 1
  - sha: "3df4584"
    repo: "wrangle-landing"
    message: "chore(site-07): apply Phase 17 OSS sweep to 4 sibling compare pages (D-14)"
    task: 2
  - sha: "eb9f2f0"
    repo: "wrangle-landing"
    message: "chore(site-07): rewrite 3 use-cases JSON entries + [slug] template (D-15)"
    task: 3
  - sha: "835335f"
    repo: "wrangle-landing"
    message: "chore(site-07): rewrite feedback.astro footer to Phase 17 Pattern D (D-16)"
    task: 4
  - sha: "e156f56"
    repo: "wrangle-landing"
    message: "chore(site-07): strip \\$19 from remaining 7 use-cases entries (D-03 audit fix)"
    task: 5
  - sha: "bfd8e1f"
    repo: "wrangle-landing"
    message: "refactor(17): relocate Story section + sweep em-dashes from prose site-wide"
    task: "6 post-checkpoint (user direction)"
  - sha: "(user-pushed deploy)"
    repo: "wrangle-landing → Vercel"
    message: "git push origin main triggered Vercel webhook auto-deploy"
    task: 7
key-files:
  modified:
    - "Landing Page/src/pages/compare/cursor.astro"
    - "Landing Page/src/pages/compare/ia-writer.astro"
    - "Landing Page/src/pages/compare/obsidian.astro"
    - "Landing Page/src/pages/compare/typora.astro"
    - "Landing Page/src/pages/compare/vs-code.astro"
    - "Landing Page/src/data/use-cases.json"
    - "Landing Page/src/pages/use-cases/[slug].astro"
    - "Landing Page/src/pages/feedback.astro"
    - "Landing Page/src/pages/index.astro"
    - "Landing Page/src/pages/404.astro"
    - "Landing Page/src/layouts/Layout.astro"
---

## What Was Built

Plan 17-03 swept the remaining 8 surface files plus a post-checkpoint typography sweep, then shipped to production.

**Task 1 — `compare/cursor.astro` (canonical)** — applied the locked surface map: single Download for macOS header CTA (UI-SPEC Surface 5), `$19 one-time` → `free + open source` in the "where wrangle wins" feature row + the quick-comparison `price` row + the "you might want wrangle if" bullet; dual hero-size CTA on the Final-CTA section; Pattern D footer.

**Task 2 — 4 sibling compare pages (ia-writer / obsidian / typora / vs-code)** — same surface map applied via a single perl pass for the structural rewrites (frontmatter, header, dual-CTA, footer, font-semibold) plus per-file sed for the Final-CTA paragraphs (each file had a distinct closing paragraph variation). Competitor-pricing facts preserved per D-14 — exempt from the `one-time` ban because they describe a competitor's price model, not Wrangle's claim.

**Task 3 — `use-cases.json` (3 target entries) + `[slug].astro` template** — rewrote the 3 paid-language entries (`claude-md-editor`, `markdown-editor-token-counting`, `ai-prompt-editor-macos`) to drop `$19 one-time` from metaDescription / body and replace with `Free and open source`. Rewrote the template with Phase 17 patterns (dual CTA header + hero + final CTA, Pattern D footer, Guarantee section deleted).

**Task 4 — `feedback.astro` footer** — light audit confirmed body had zero `refund / billing / paid customer / subscriber` hits (pre-existing clean). Footer rewritten to Shared Pattern D.

**Task 5 — full D-03 grep audit** — caught a gap not in the original plan: `$19` survived in 7 OTHER use-cases entries beyond the 3 explicitly named in D-15. Stripped those 7 metaDescription closings to `Free and open source.` (separate commit `e156f56`, documented as plan deviation — the Task 3 scope was too narrow and the audit gate caught it).

**Task 6 — pre-deploy human-verify checkpoint** — user approved with two directives applied as a post-checkpoint commit (`bfd8e1f`):
   1. **Relocate the Story section** from between Logo+Tagline and Features to replace the legacy Anti-Pitch section near the page bottom. Same 4-paragraph content, same visual differentiation (bg-card).
   2. **Strip em-dashes from all user-facing prose site-wide** — user feedback: *"this is a tell for AI generated content. I don't want you to use these long emmex dashes anywhere."* Memory note saved at `~/.claude/projects/.../memory/feedback_no_em_dashes.md` so future sessions honor the rule.

   Em-dash sweep replacements:
   - Hero H1: `"native macOS markdown editor for AI agents. free and open source."` (was: em-dash separator)
   - Story para 1 close: `"so i built what i wanted: one window for all of it."` (was: em-dash)
   - 404.astro H1: `"404. page not found."` (was: `"404 — page not found"`)
   - All `<Layout title>` props in index.astro, 404.astro, feedback.astro, and all 5 compare pages: em-dash separator → colon (e.g., `"wrangle: free macOS markdown editor for AI developers"`)
   - 4 legacy index.astro feature paragraphs (notifications / browser / terminals / workspace overview): em-dash asides → commas or parentheses
   - 5 compare/*.astro files: every prose em-dash swept to `, `
   - `use-cases.json`: 46 field changes across 20 entries (titles, body prose, metaDescription, intro, h1) via JSON-safe transform
   - feedback.astro JS error message: `"no duplicates"` comma form

   Decorative `—` separator spans in feature lists are PRESERVED (typography, not authored prose). The feedback page `<select>` placeholder `—` is also preserved (UI placeholder).

**Task 7 — Deploy + live verification** — user-executed `git push origin main` from `Landing Page/`, triggering the Vercel webhook auto-deploy to `wrangleapp.dev`. The Vercel build succeeded and the new site landed.

## Live Verification Results (Task 7)

### HTTP status checks (with redirect follow)

```
200  /
404  /buy
404  /pricing
404  /refund
404  /terms
200  /compare/cursor
200  /compare/ia-writer
200  /compare/obsidian
200  /compare/typora
200  /compare/vs-code
200  /use-cases/claude-md-editor
200  /use-cases/markdown-editor-token-counting
200  /use-cases/ai-prompt-editor-macos
200  /feedback
```

All 14 URLs verified ✓. Note: the apex `wrangleapp.dev` returns 307 → `www.wrangleapp.dev` (Vercel default redirect); end status with redirect-follow is 200. The grading bar treats the redirect-followed code as the authoritative response.

### Homepage content (live, post-deploy)

| Check | Result |
|-------|--------|
| `Download for macOS` count | 3 ✓ (header + hero + final-CTA) |
| `Star on GitHub` count | 3 ✓ |
| `Built by J Krush` count | 1 ✓ (footer attribution) |
| Story `reddit ads` | 1 ✓ |
| Story `product hunt` | 1 ✓ |
| `free + open source` tagline | 2 ✓ (hero + final-CTA) |
| `releases/latest` hrefs | 3 ✓ |
| Legacy `$19` | 0 ✓ |
| Legacy `buy — ` | 0 ✓ |
| Legacy `try free` | 0 ✓ |
| `<title>` element | `wrangle: free macOS markdown editor for AI developers` ✓ |
| Em-dash count (prose) | 0 ✓ |

### 404 page content (via `/buy`)

| Check | Result |
|-------|--------|
| `page not found` | 1 ✓ |
| `retired in the OSS flip` | 1 ✓ |
| `Download for macOS` count | 2 ✓ (header + content CTA) |

### JSON-LD on homepage

```json
{"@context":"https://schema.org","@type":"SoftwareApplication","name":"Wrangle","description":"...","url":"https://wrangleapp.dev","applicationCategory":"DeveloperApplication","operatingSystem":"macOS 15+","processorRequirements":"Apple Silicon","author":{"@type":"Person","name":"J-Krush","url":"https://jkrush.dev"},"creator":{"@type":"Person","name":"J Krush","url":"https://jkrush.dev"},"screenshot":"https://wrangleapp.dev/images/product-images/editor-simple.png"}
```

| Field | Live count |
|-------|-----------|
| `"@type": "Offer"` | 0 ✓ (block deleted) |
| `"price": "19"` | 0 ✓ |
| `"creator":` | 1 ✓ |
| Parses as valid JSON | ✓ (parsed in live HTML inline) |

### OG / Twitter metadata (live)

| Tag | Live value |
|-----|-----------|
| `<meta name="description">` | `Wrangle is a free, open source native macOS workspace for AI developers...` ✓ |
| `<meta property="og:title">` | `wrangle: free macOS markdown editor for AI developers` ✓ |
| `<meta property="og:description">` | (same as meta description) ✓ |
| `<meta name="twitter:card">` | `summary_large_image` ✓ (UI-SPEC Surface 8 unchanged) |
| `<meta name="twitter:title">` | `wrangle: free macOS markdown editor for AI developers` ✓ |
| `<meta name="twitter:description">` | (same as meta description) ✓ |
| `<meta property="og:image">` | `/images/og-image.png` ✓ (D-17 untouched) |

### Phase 18-deferred behavior (EXPECTED 404)

```
HTTP 404 -> https://github.com/J-Krush/wrangle/releases/latest
```

This 404 is **expected** until Phase 18 publishes the v1.3.0 GitHub Release (D-10 LOCKED from Phase 13). Plan 17-03 acceptance criteria explicitly noted this is the correct end-of-Phase-17 state. Once Phase 18 ships, this URL returns 200 with the v1.3.0 release page; the inline `Wrangle-1.3.0.dmg` asset becomes downloadable.

### Reversibility (D-19)

Vercel keeps every previous deployment. Rollback to the pre-Phase-17 deploy is a one-click action in the Vercel dashboard. The 8 unpushed Landing Page commits that preceded Phase 17 (Phase 15 + Phase 16 work) were also part of this push; if a rollback is needed for any reason, a Vercel-side rollback to the prior production deploy fully restores the pre-Phase-17 paid-product surface.

### Anti-regression (D-20)

11 atomic Phase 17 commits on `main` (linear history). No `git filter-repo`, no `git push --force`, no `git reset --hard`. All commits preserved.

## Plan Deviations (documented for verify-phase audit)

| # | Deviation | Justification |
|---|-----------|---------------|
| 1 | Plan Task 1 acceptance: `grep -c 'Download for macOS' returns ≥ 3`. Actual: 2 (header + final-CTA). | UI-SPEC Surface 5 locks compare-page headers to a single CTA. Plan acceptance grep had been corrected during plan finalization (`grep -c ≥ 2` after a quick-fix during planning); the implementation matches the corrected spec. |
| 2 | Plan Task 2 acceptance: `ia-writer.astro` should have 0 `one-time` hits. Actual: 1 (`$50 one-time` competitor pricing for iA Writer). | D-14 spirit: competitor-pricing facts are FINE to preserve. Same exemption logic the plan applied to `typora.astro` ($15 one-time). |
| 3 | Plan Task 3 scope: only 3 use-cases entries. Actual: 10 entries touched (3 from Task 3 + 7 caught in Task 5 audit). | D-03 is a hard-locked pattern (zero $19 anywhere). The plan-checker missed that the other 17 entries also carried `$19` in metaDescription. Task 5 caught it and the delta fix shipped as `e156f56`. |
| 4 | Plan Task 4 source-assertion: `dist/feedback/index.html` exists. Actual: `dist/client/feedback/index.html`. | @astrojs/vercel adapter splits output between `dist/server/` and `dist/client/` — same as the 404 page in Plan 17-01. The file exists; only the literal path differs. |
| 5 | Plan Task 7 live-content acceptance: `grep -c "2026-04-22"` returns ≥ 1. Actual: 0. | User dropped the `2026-04-22` date from the Story copy at the Plan 17-02 human-verify checkpoint (*"don't say the actual date of the ph launch"*). Plan 17-02 SUMMARY documented this; Plan 17-03 inherits the consequence. |
| 6 | Plan Task 6 checkpoint produced 2 user-direction edits **after** the original sweep finished: (a) Story section relocated from Logo+Tagline neighborhood to replace the Anti-Pitch section; (b) em-dashes stripped from all prose. | Documented in commit `bfd8e1f`. Both edits are improvements caught at the user's pre-deploy review. Plan 17-02's SUMMARY's verification block becomes partially stale (Story-section line numbers shift); this Plan 17-03 SUMMARY is the authoritative post-relocation record. |

## What This Enables for Phase 18

Phase 18 (FLIP) inherits a fully repositioned landing page at `wrangleapp.dev`:
- All public-facing OSS positioning is in place.
- The Download CTA points at `https://github.com/J-Krush/wrangle/releases/latest` and will start returning 200 as soon as Phase 18 publishes the v1.3.0 GitHub Release.
- The LemonSqueezy account / product is still deliberately live (D-05 deferred). Phase 18 FLIP-04 handles the vendor-account cleanup.
- The `dl.wrangleapp.dev` subdomain is no longer referenced from any landing-page code. Phase 18 owns the DNS-record cleanup decision (per D-12).
- The repo (`J-Krush/wrangle-landing`) is still private. Phase 18 FLIP-02 / FLIP-03 flip both the landing repo and the app repo to public simultaneously.
