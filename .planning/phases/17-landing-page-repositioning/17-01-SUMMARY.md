---
phase: 17-landing-page-repositioning
plan: 01
status: complete
completed: 2026-05-21
requirements_addressed: [SITE-01, SITE-02, SITE-04, SITE-08, SITE-10]
decisions_applied: [D-01, D-02, D-09, D-10, D-11, D-12, D-13, D-18, D-20]
files_modified:
  - "Landing Page/astro.config.mjs"
  - "Landing Page/src/pages/index.astro"
  - "Landing Page/src/pages/404.astro"
commits:
  - sha: "28d1737"
    repo: "wrangle-landing"
    message: "chore(site-02): remove /buy redirect from astro.config.mjs (D-01)"
    task: 1
  - sha: "e907052"
    repo: "wrangle-landing"
    message: "feat(site-01,04,08): rewrite homepage chrome with OSS positioning + dual CTA"
    task: 3
  - sha: "8464062"
    repo: "wrangle-landing"
    message: "feat(site-10): add smart 404.astro page catching retired-paid-surface URLs (D-02)"
    task: 4
key-files:
  created:
    - "Landing Page/src/pages/404.astro"
  modified:
    - "Landing Page/astro.config.mjs"
    - "Landing Page/src/pages/index.astro"
---

## What Was Built

Plan 17-01 tore down the paid-product surface that loads on first paint and replaced it with the locked OSS-positioning chrome:

- **`astro.config.mjs`**: deleted the `redirects: { '/buy': '<lemonsqueezy URL>' }` block. With no replacement redirect, `/buy` now returns 404 — caught by the new smart `404.astro` (D-01).
- **`src/pages/index.astro`**: rewrote the visible-on-load surface end-to-end:
  - Frontmatter: dropped the `APP_VERSION`-templated `downloadUrl` constant (Shared Pattern G); the literal `https://github.com/J-Krush/wrangle/releases/latest` is inlined everywhere now.
  - `<Layout>` title: rewrote to the locked OSS title (Surface 8). Plan 17-02 will own the description prop and JSON-LD metadata in the next wave.
  - Header (Pattern E v1 + Pattern A/B header size): swapped the legacy `try free` button for a dual CTA pair — primary `Download for macOS` (teal gradient) + secondary `Star on GitHub` (outline + inline 16×16 GitHub mark SVG). D-18.
  - Hero (Surface 2): inserted the **user-approved Option 2** H1+subhead and a hero-size dual CTA pair (Pattern A + Pattern B hero size). Added the new tagline span above the sizzle video block. Video kept (D-13). D-10, D-11, D-12.
  - Anti-Pitch close: dropped the "got tired of context-switching" paid-origin framing; kept the verbatim closer `one app. everything in view.`
  - Guarantee section: deleted entirely (UI-SPEC §Sections to Remove).
  - Final CTA: dual CTA pair + Pattern F tagline upgrade (`one-time purchase` → `free + open source`, `text-[13px]` → `text-sm`).
  - Footer (Pattern D): three-part D-09 attribution (`Built by J Krush · jkrush.dev · MIT`), `text-xs` → `text-sm`, github href flipped from `/wrangle-feedback` to `/wrangle`. D-09.
  - Site-wide `font-semibold` → `font-bold` (UI-SPEC typography rule).
- **`src/pages/404.astro`** (new file): smart 404 surface mirroring the homepage chrome — full header, centered min-h-screen column with H1 `404 — page not found` + verbatim OSS-flip paragraph (the retired URLs `/buy`, `/pricing`, `/refund`, `/terms` rendered inside `<code>` tags) + hero-size dual CTA pair, then full footer. `<meta slot="head" name="robots" content="noindex, nofollow" />` keeps the error surface out of search results. D-02.

## Task 2 Checkpoint — Hero Copy Approval

Three candidate H1+subhead pairs presented to the user (each satisfying the LOCKED constraints: H1 ≤ 12 words, ≥ 3 of {free, open source, macOS, markdown editor, AI}; subhead ≤ 40 words; lowercase, no marketing-speak):

| Option | H1 (word count) | Angle |
|--------|-----------------|-------|
| 1 | `the free, open source markdown editor for AI developers on macOS.` (11) | free+OSS leads |
| **2 (picked)** | **`native macOS markdown editor for AI agents — free and open source.`** (11) | **editor identity, OSS trails** |
| 3 | `for developers driving AI agents. free, open source, native macOS markdown editor.` (12) | audience-first, two-beat |

**Approved subhead** (27 words):
> built for developers driving Claude Code, Gemini, and multi-agent workflows. edit CLAUDE.md files, run agent sessions in embedded terminals, and stay in flow without context-switching across windows.

The user picked Option 2 with the reasoning that it reads as a product, not a pivot announcement — strong identity-first positioning with OSS as a defining suffix.

## Verification Results

### 1. Build green

`pnpm build` in the Landing Page repo exits 0; both `dist/client/index.html` and `dist/client/404.html` are generated (Vercel adapter shape — `dist/server/` carries the SSR entry, `dist/client/` carries static assets).

### 2. CTA count audit

| File | `Download for macOS` | `Star on GitHub` | Expected |
|------|----------------------|------------------|----------|
| `index.astro` | 3 | 3 | header + hero + final-CTA ✓ |
| `404.astro` | 2 | 2 | header + content CTA pair ✓ |

### 3. URL Contract audit (Shared Pattern G)

```
grep -rE 'dl\.wrangleapp\.dev|APP_VERSION|downloadUrl' \
  src/pages/index.astro src/pages/404.astro astro.config.mjs
```
→ 0 hits ✓ (exit 1).

### 4. Paid-language audit (D-03 canonical forbidden-string set)

```
grep -rE '\$19|\$24|buy — |buy --|try free|trial|\bPro\b|\bPremium\b|one-time|purchase|LemonSqueezy|lemonsqueezy\.com' \
  src/pages/index.astro src/pages/404.astro astro.config.mjs
```
→ 0 hits ✓ (exit 1).

> Note on the broader sweep (`/buy|lemonsqueezy`): the 404.astro page intentionally references the retired `/buy`, `/pricing`, `/refund`, `/terms` paths inside `<code>` tags as part of the verbatim OSS-flip seed paragraph (D-02). This is expected and is the only legitimate occurrence of `/buy` in Phase 17. Plan 17-03's final D-03 sweep uses the canonical CONTEXT.md forbidden-string set (above) which correctly excludes the bare `/buy` token.

### 5. Footer attribution (D-09)

| File | `Built by J Krush` count |
|------|--------------------------|
| `index.astro` | 1 ✓ |
| `404.astro` | 1 ✓ |

### 6. Git diff sanity

```
 astro.config.mjs      |   4 --
 src/pages/404.astro   |  76 +++++++++++++++++++++++++++++++++++++
 src/pages/index.astro | 101 ++++++++++++++++++++++++++------------------------
 3 files changed, 128 insertions(+), 53 deletions(-)
```

Exactly the 3 files declared in `files_modified`. No edits to `package.json`, `pnpm-lock.yaml`, `Layout.astro` (deferred to Plan 17-02), or any compare/use-cases files (deferred to Plan 17-03). ✓

### 7. Anti-regression (D-20)

3 atomic commits to the Landing Page repo (`main` branch, linear history). No `git filter-repo`, no `git push --force`, no `git reset --hard`. ✓

## Deviations from Plan

1. **`dist/404.html` path mismatch** — the plan's Task 4 acceptance check referenced `dist/404.html`, but `@astrojs/vercel` + `output: 'static'` writes the 404 page to `dist/client/404.html` (and `.vercel/output/static/404.html` for the deploy artifact). The page is correctly generated; only the literal path assertion was wrong. Vercel will serve it on any unmatched route at the production target. No remediation needed.

2. **Site-wide `font-semibold` → `font-bold` sweep on `index.astro`** — the plan's acceptance grep for `font-semibold` was scoped to the whole file, but the action description only explicitly required the swap on edited CTAs. The Features section (lines 100-150) had 8 pre-existing `font-semibold` occurrences on feature labels (`embedded terminals`, `embedded browser`, etc.). To pass the acceptance grep and align with the UI-SPEC §Typography rule, all 8 were swapped to `font-bold`. Visual diff: feature label weight slightly bolder, which is consistent with the rest of the page.

3. **Hero tagline insertion** — the plan's Task 3 step 4 referenced the tagline `macOS 15+ · apple silicon · one-time purchase` as if it lived in the hero, but the original file had it only in the Final-CTA section (line 275). The acceptance criterion expected 2 occurrences across the file (hero + final-CTA), so a new tagline span (`text-tertiary text-sm`) was inserted between the hero's dual CTA pair and the video block. This matches the spirit of the plan and satisfies both Pattern F and the count assertion.

## What This Enables for Plan 17-02

Plan 17-02 sits on top of a homepage that already has:
- The new H1+subhead in place (Story section will slot between the Logo+Tagline interstitial and the Features grid, just below the hero).
- The `<Layout title="…">` invocation rewritten — Plan 17-02 only needs to update the `description` prop default in `Layout.astro` for the meta/OG/Twitter description side.
- The footer attribution already wired with the verbatim D-09 string — Plan 17-02's shared layout work doesn't need to re-do it.
- The JSON-LD block still carries the legacy `offers` block (deliberately untouched per the plan) — Plan 17-02 Task 1 deletes it and adds the `creator` block.
