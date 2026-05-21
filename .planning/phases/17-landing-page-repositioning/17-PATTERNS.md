# Phase 17: Landing Page Repositioning - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 11 (1 created, 10 modified)
**Analogs found:** 11 / 11 (every modified file is its own analog; created file maps to two donor patterns)

> All analogs live in `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/` — the working code is in the sibling `wrangle-landing` repo, **not** in the Wrangle planning repo at `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Landing Page/src/pages/404.astro` (NEW) | page (error/static) | request-response (SSG) | `Landing Page/src/pages/feedback.astro` (shell) + `Landing Page/src/pages/index.astro` lines 59–72 (dual CTA donor) | composite (new role) |
| `Landing Page/astro.config.mjs` | config | build-time | `Landing Page/astro.config.mjs` (self — single-file edit) | exact (self-edit) |
| `Landing Page/src/pages/index.astro` | page (root) | request-response (SSG) | `Landing Page/src/pages/index.astro` (self) | exact (self-edit) |
| `Landing Page/src/layouts/Layout.astro` | layout (shell) | request-response (SSG) | `Landing Page/src/layouts/Layout.astro` (self — props default + meta tags) | exact (self-edit) |
| `Landing Page/src/styles/global.css` | config (theme) | build-time | `Landing Page/src/styles/global.css` (self — tokens already defined) | exact (self-edit, audit-only) |
| `Landing Page/src/pages/compare/cursor.astro` | page (long-form content) | request-response (SSG) | `Landing Page/src/pages/compare/cursor.astro` (canonical pattern; the other 4 are siblings) | exact (self-edit) |
| `Landing Page/src/pages/compare/ia-writer.astro` | page (long-form content) | request-response (SSG) | `Landing Page/src/pages/compare/cursor.astro` (identical shape — 6 paid-language occurrences each) | exact (sibling) |
| `Landing Page/src/pages/compare/obsidian.astro` | page (long-form content) | request-response (SSG) | `Landing Page/src/pages/compare/cursor.astro` | exact (sibling) |
| `Landing Page/src/pages/compare/typora.astro` | page (long-form content) | request-response (SSG) | `Landing Page/src/pages/compare/cursor.astro` | exact (sibling) |
| `Landing Page/src/pages/compare/vs-code.astro` | page (long-form content) | request-response (SSG) | `Landing Page/src/pages/compare/cursor.astro` | exact (sibling) |
| `Landing Page/src/data/use-cases.json` | data (content) | build-time | `Landing Page/src/data/use-cases.json` (self — 3 of 20 entries edited) | exact (self-edit) |
| `Landing Page/src/pages/use-cases/[slug].astro` | page (dynamic route) | request-response (SSG, getStaticPaths) | `Landing Page/src/pages/use-cases/[slug].astro` (self — header/footer CTA only) | exact (self-edit) |
| `Landing Page/src/pages/feedback.astro` | page (form) | request-response → POST `/api/feedback` | `Landing Page/src/pages/feedback.astro` (self — light audit only) | exact (self-edit, audit-only) |

**Stack confirmation (from `Landing Page/package.json`):** Astro ^5.17.1 + `@tailwindcss/vite` ^4.2.1 + `@astrojs/vercel` ^8.1.4 + `@astrojs/sitemap` ^3.7.1 + `resend` ^6.9.4 + `@vercel/kv` ^3.0.0. **No new dependencies in Phase 17** (UI-SPEC constraint #2). Astro stays pinned (UI-SPEC constraint #4).

---

## Pattern Assignments

### `Landing Page/src/pages/404.astro` (page, NEW)

**Analogs:**
- **Shell donor:** `Landing Page/src/pages/feedback.astro` — simplest single-purpose Astro page using `<Layout>`, header, main content block, footer.
- **CTA donor:** `Landing Page/src/pages/index.astro` lines 59–72 (current `flex-col items-center gap-3` CTA stack) — pattern to lift into the new dual CTA per UI-SPEC Surface 4.

**Frontmatter pattern** (lifted from `feedback.astro:1-3`):
```astro
---
import Layout from "../layouts/Layout.astro";
import "../styles/global.css";
---
```
No `getStaticPaths`, no `Astro.props`, no version variable (per UI-SPEC URL Contract: literal URL only — `https://github.com/J-Krush/wrangle/releases/latest`).

**Layout invocation pattern** (lifted from `feedback.astro:18-19`, adapted per UI-SPEC Surface 4):
```astro
<Layout title="404 — wrangle" description="Page not found.">
  <meta slot="head" name="robots" content="noindex, nofollow" />
```
Note: `feedback.astro` uses `noindex, nofollow` on `<meta slot="head">` — recommend mirroring on 404 (low-value error surface).

**Header pattern** (lifted from `feedback.astro:21-30` — logo + home link, NO CTA in feedback header; but UI-SPEC Surface 4 says "404 page includes the same `<header>` (with dual CTA) and `<footer>` as `index.astro`"). So the donor for the header is `index.astro:34-49` (after Phase 17 rewrite to dual CTA per UI-SPEC Surface 1). Use the same header block as the new homepage.

**Centered column pattern** (UI-SPEC Surface 4 — no existing analog, this is a new layout shape):
```astro
<div class="min-h-screen flex flex-col items-center justify-center px-5 lg:px-[200px] py-16 gap-8">
  <div class="w-full max-w-[700px] flex flex-col items-center gap-6 text-center">
    <h1 class="text-[28px] sm:text-[36px] lg:text-[48px] font-bold text-center leading-[1.15]">
      404 — page not found
    </h1>
    <p class="text-secondary text-base leading-relaxed max-w-[600px] text-center">
      Wrangle is now free and open source. The old paid surface (<code>/buy</code>, <code>/pricing</code>, <code>/refund</code>, <code>/terms</code>) was retired in the OSS flip.
    </p>
    <div class="flex flex-col sm:flex-row items-center gap-3">
      <!-- primary + secondary buttons here -->
    </div>
  </div>
</div>
```

**Footer pattern:** Identical to the new homepage footer (see Shared Pattern: Footer Attribution below).

---

### `Landing Page/astro.config.mjs` (config, MODIFIED)

**Analog:** Self.

**Current pattern** (`astro.config.mjs:15-18`):
```javascript
redirects: {
  // Update this URL once your LemonSqueezy store + product is created
  '/buy': 'https://jkrush.lemonsqueezy.com/checkout/buy/8860d1f0-c122-4ab6-8528-ee727d3065e3',
},
```

**Edit pattern (D-01):** Delete the entire `redirects: { ... }` property and the preceding comment line. The `defineConfig({ ... })` call should keep `site`, `integrations`, `vite`, `adapter`, `output` and lose only the redirects block. After edit, the trailing comma on the preceding line (`output: 'static',`) is fine to leave (JS allows trailing object comma).

**Verification:** `grep -E "buy|lemonsqueezy|redirects" astro.config.mjs` must return 0 hits after the edit.

---

### `Landing Page/src/pages/index.astro` (page, MODIFIED)

**Analog:** Self (the largest single edit in the phase).

**Surface map by line range** (current `index.astro`):

| Lines | Current content | Phase 17 action |
|-------|-----------------|-----------------|
| 1–7 | Frontmatter with `version` + `downloadUrl` | DELETE `version` + `downloadUrl` constants (UI-SPEC URL Contract). Frontmatter becomes 3 lines (Layout import, CSS import). |
| 9 | `<Layout title="…">` invocation | REWRITE title to `wrangle — free macOS markdown editor for AI developers` (UI-SPEC Surface 8). |
| 11–32 | JSON-LD `<script>` | DELETE `offers` block (lines 20–25). ADD `creator` block after `author` (UI-SPEC Surface 7). |
| 34–49 | `<header>` — single `try free` button | REWRITE to dual CTA (Download primary + Star on GitHub secondary). See Shared Pattern: Header Dual CTA. |
| 51–84 | `<section>` Hero — `buy — $19` primary + `try free` text link | REWRITE H1 + subhead (deferred to executor per D-10, human checkpoint). REPLACE CTA pair with dual CTA (hero size). See Shared Pattern: Hero Dual CTA. Video at lines 73–83 untouched (D-13). |
| 87–90 | Logo + Tagline interstitial | INSERT new `<section>` for Story (UI-SPEC Surface 3) AFTER this block, BEFORE the Features section at line 93. |
| 234–241 | Anti-Pitch | REWRITE final sentence per UI-SPEC Copywriting Contract — remove "got tired of context-switching" framing, keep "one app. everything in view." close. |
| 243–249 | Guarantee `<section>` | DELETE entirely (UI-SPEC "Sections to Remove"). |
| 258–276 | Final CTA `<section>` | REPLACE inner CTA pair with dual CTA (hero size). UPDATE tagline at line 275: `one-time purchase` → `free + open source`; class `text-[13px]` → `text-sm`. |
| 278–290 | `<footer>` | REWRITE left column to three-part attribution (`Built by J Krush · jkrush.dev · MIT`). UPDATE right-column github href from `wrangle-feedback` → `wrangle`. Container `text-xs` → `text-sm`. See Shared Pattern: Footer Attribution. |
| 292–306 | Video click `<script>` | UNTOUCHED — keeps autoplay/click-to-pause behavior. |

**Concrete excerpt — current header (lines 34-49):**
```astro
<header class="flex items-center justify-between px-5 lg:px-[200px] py-4">
  <div class="flex items-center gap-2.5">
    <img
      src="/images/wrangle-logo-13.png"
      alt="wrangle logo"
      class="w-8 h-8 rounded"
    />
    <span class="text-base font-bold">wrangle</span>
  </div>
  <a
    href={downloadUrl}
    class="inline-flex items-center justify-center rounded-lg bg-linear-to-b from-teal to-teal-dark px-6 py-2.5 text-sm font-medium text-dark hover:brightness-110 transition-all"
  >
    try free
  </a>
</header>
```
Note: existing button uses `font-medium` (500). UI-SPEC Typography section requires Phase 17 normalize this to `font-bold` (700) on all CTA buttons. The right-side anchor becomes a `flex flex-row gap-2` container holding the new primary + outline secondary buttons (UI-SPEC Surface 1).

**Concrete excerpt — current hero CTA (lines 59-72):**
```astro
<div class="flex flex-col items-center gap-3">
  <a
    href="/buy"
    class="inline-flex items-center justify-center rounded-lg bg-linear-to-b from-teal to-teal-dark px-8 py-4 text-base font-semibold text-dark hover:brightness-110 transition-all"
  >
    buy — $19
  </a>
  <a
    href={downloadUrl}
    class="text-secondary text-sm hover:text-primary transition-colors"
  >
    try free — 3 day trial
  </a>
</div>
```
Note: existing primary button uses `font-semibold` (600) — UI-SPEC §Typography normalizes all CTA labels to `font-bold` (700). Outer container becomes `flex flex-col sm:flex-row items-center gap-3` (UI-SPEC Surface 2). The `text-link` secondary is REPLACED by the outline button (UI-SPEC §"Secondary CTA visual style" — LOCKED).

**Concrete excerpt — current JSON-LD offers block (lines 20-25) to DELETE:**
```javascript
"offers": {
  "@type": "Offer",
  "price": "19",
  "priceCurrency": "USD",
  "availability": "https://schema.org/InStock"
},
```
And ADD this block adjacent to the existing `author` block (lines 26-30):
```javascript
"creator": {
  "@type": "Person",
  "name": "J Krush",
  "url": "https://jkrush.dev"
},
```
(UI-SPEC Surface 7 — both `author` and `creator` co-exist.)

**Story section (NEW section to insert):** No existing analog inside `index.astro`. Container pattern locked by UI-SPEC Surface 3:
```astro
<section class="bg-card border-y border-border-subtle flex flex-col items-center px-5 lg:px-[200px] py-16 lg:py-[100px]">
  <div class="w-full max-w-[700px] flex flex-col gap-6">
    <!-- 4 paragraphs, each: -->
    <p class="text-secondary text-base leading-relaxed">…</p>
  </div>
</section>
```
Paragraph class matches the existing prose pattern at `compare/cursor.astro:46-51` (`text-secondary text-base leading-relaxed max-w-[700px]`). The outer container already constrains width via `max-w-[700px]` on the inner `<div>`, so per-paragraph `max-w-[700px]` is redundant here and should be omitted.

---

### `Landing Page/src/layouts/Layout.astro` (layout, MODIFIED)

**Analog:** Self.

**Current default prop pattern** (`Layout.astro:9-14`):
```typescript
const {
  title,
  description = "A native macOS markdown editor for developers working with Claude Code, Gemini, and AI agents. Embedded terminals, smart notifications, token counting.",
  canonical,
  ogImage = "/images/og-image.png",
} = Astro.props;
```

**Edit pattern (UI-SPEC Surface 8):** Replace the default `description` string with:
```typescript
description = "Wrangle is a free, open source native macOS workspace for AI developers. Markdown editor with token counting, embedded terminals, agent notifications, and XML-in-markdown support. Built with Swift on Apple Silicon.",
```

**Untouched:** All `<meta>` tag patterns (lines 26, 32–37, 40–43) — they already read `description` and `title` from props, so the upstream prop change flows automatically. `og:image` default (line 13: `"/images/og-image.png"`) untouched (D-17). `twitter:card` type stays `summary_large_image` (line 40).

**Page-level title invocation (in `index.astro:9`):** Currently `<Layout title="wrangle — markdown editor for Claude Code & AI agents (macOS)" canonical="...">`. Phase 17 rewrites this title prop to `wrangle — free macOS markdown editor for AI developers` (UI-SPEC Surface 8).

---

### `Landing Page/src/styles/global.css` (config, AUDIT-ONLY)

**Analog:** Self.

**Current full content** (all 19 lines):
```css
@import "tailwindcss";

@theme {
  --color-page: #0F0F12;
  --color-card: #18181B;
  --color-terminal-bar: #1F1F23;
  --color-primary: #E5E5E5;
  --color-secondary: #A3A3A3;
  --color-tertiary: #737373;
  --color-dark: #0C0C0C;
  --color-teal: #3DB8A8;
  --color-teal-dark: #2D9B8C;
  --color-border: #27272A;
  --color-border-subtle: #1F1F1F;
  --color-dot-red: #EF4444;
  --color-dot-yellow: #EAB308;
  --color-dot-green: #2D9B8C;
  --font-mono: "JetBrains Mono", monospace;
}
```

**Edit pattern (UI-SPEC §Color):** **No change needed.** The story-section background tint uses the already-defined `--color-card` (`#18181B`) via Tailwind class `bg-card border-y border-border-subtle`. All tokens needed for Phase 17 already exist. This file is "audit-only" — verify no orphaned tokens get added accidentally.

---

### `Landing Page/src/pages/compare/cursor.astro` (page, MODIFIED — canonical compare-page pattern)

**Analog:** Self. This file IS the donor pattern for the other 4 compare pages.

**Surface map** (current `cursor.astro`, 249 lines):

| Lines | Current content | Phase 17 action |
|-------|-----------------|-----------------|
| 1–7 | Frontmatter with `version` + `downloadUrl` | DELETE `version` + `downloadUrl` (UI-SPEC URL Contract). |
| 24–29 | `<header>` single `buy — $19` button | REWRITE to single `Download for macOS` button (UI-SPEC Surface 5 — single CTA, NOT dual, on compare-page headers). Class normalization: `font-medium` → `font-bold`. |
| 60–96 | "where wrangle wins" feature list | AUDIT for `$19 one-time` row (line 93–96 in cursor.astro). The compare-page table row at lines 91–96 in cursor.astro reads `$19 one-time / no subscription. Cursor's AI features run $20/month. wrangle is $19 once, forever.` — rewrite to drop the price comparison (or replace with "free + open source / no subscription, no cost"). Per-file audit per D-14. |
| 142–143 | "you might want wrangle if" bullet about `$19 one-time` | AUDIT — rewrite to drop the price-focused bullet OR replace with "you want a free, open source alternative". |
| 195–205 | Quick-comparison table `price` row | AUDIT — current value `$19 one-time` → `free + open source`. |
| 213–233 | Page-level final CTA section with primary `buy — $19` + secondary `try free` text link + tagline `macOS 15+ · apple silicon · one-time purchase` | REWRITE to full hero dual CTA pair (Download primary + Star on GitHub outline secondary). Update tagline to `macOS 15+ · apple silicon · free + open source`; class `text-[13px]` → `text-sm`. |
| 236–247 | `<footer>` | Same rewrites as `index.astro` footer (see Shared Pattern: Footer Attribution). |

**Concrete excerpt — current header (lines 14-30):**
```astro
<header class="flex items-center justify-between px-5 lg:px-[200px] py-4">
  <a href="/" class="flex items-center gap-2.5">
    <img
      src="/images/wrangle-logo-13.png"
      alt="wrangle logo"
      class="w-8 h-8 rounded"
    />
    <span class="text-base font-bold">wrangle</span>
  </a>
  <a
    href="/buy"
    class="inline-flex items-center justify-center rounded-lg bg-linear-to-b from-teal to-teal-dark px-6 py-2.5 text-sm font-medium text-dark hover:brightness-110 transition-all"
  >
    buy — $19
  </a>
</header>
```
Note: logo wrapped in `<a href="/">` (not `<div>` like in `index.astro:35-42`). Preserve that pattern — compare pages need home navigation. After Phase 17: anchor target becomes `https://github.com/J-Krush/wrangle/releases/latest`, label becomes `Download for macOS`, class `font-medium` → `font-bold` (UI-SPEC Surface 5).

**Concrete excerpt — current final-CTA section (lines 213-233):**
```astro
<section class="flex flex-col items-center justify-center px-5 lg:px-[200px] py-16 lg:py-[100px] gap-6">
  <h2 class="text-[32px] lg:text-[40px] font-bold">wrangle</h2>
  <p class="text-secondary text-base text-center max-w-[500px]">
    the companion to your code editor. manage AI prompts, configs, and agent sessions in one native app. $19, one-time.
  </p>
  <div class="flex flex-col items-center gap-3">
    <a
      href="/buy"
      class="inline-flex items-center justify-center rounded-lg bg-linear-to-b from-teal to-teal-dark px-8 py-4 text-base font-semibold text-dark hover:brightness-110 transition-all"
    >
      buy — $19
    </a>
    <a
      href={downloadUrl}
      class="text-secondary text-sm hover:text-primary transition-colors"
    >
      try free
    </a>
  </div>
  <span class="text-tertiary text-[13px]">macOS 15+ · apple silicon · one-time purchase</span>
</section>
```
Note: paragraph at line 215–217 mentions `$19, one-time` — rewrite to drop the price phrase. CTA stack rewritten to dual CTA (hero size). Tagline rewritten + class bumped to `text-sm`.

---

### `Landing Page/src/pages/compare/{ia-writer,obsidian,typora,vs-code}.astro` (page × 4, MODIFIED — siblings)

**Analog:** `Landing Page/src/pages/compare/cursor.astro` (canonical pattern above).

Verified via `grep -c 'try free\|buy — \$19\|one-time purchase\|/buy'`: each file has exactly **6 paid-language occurrences** matching cursor.astro's count. Structural shape (frontmatter `version`/`downloadUrl`, header CTA, "where wrangle wins" list, "you might want wrangle if" bullets, quick-comparison table, final-CTA section, footer) is identical across all 5 pages.

**Per-file body audit (D-14):** Each compare page MAY have its own competitor-specific price comparison (e.g., "Cursor's AI features run $20/month", "Typora is $14.99 one-time"). The price columns in quick-comparison tables must be reviewed individually. Per-file ~10–15 min audit, as estimated in CONTEXT.md §Boundary.

**Apply cursor.astro's pattern to all 4 siblings:** Same surface map, same line-range actions (approximate — line numbers will differ slightly per file due to body-prose length variation).

---

### `Landing Page/src/data/use-cases.json` (data, MODIFIED — 3 of 20 entries)

**Analog:** Self. The JSON contains 20 entries; only the first 3 (`claude-md-editor`, `markdown-editor-token-counting`, `ai-prompt-editor-macos`) are edited in Phase 17 per D-15.

**Entry shape pattern** (verbatim from entry 1, lines 2-11 of use-cases.json):
```json
{
  "slug": "claude-md-editor",
  "title": "CLAUDE.md Editor for macOS — Wrangle",
  "metaDescription": "Edit CLAUDE.md files with a native macOS editor that understands AI project files. Token counting, XML highlighting, and embedded terminals. $19 one-time.",
  "h1": "the CLAUDE.md editor you've been missing",
  "intro": "CLAUDE.md is the file that shapes how Claude Code works in your project. It deserves better than a code editor's markdown preview pane.",
  "body": "Every Claude Code project starts with a CLAUDE.md file. [...] But editing it in VS Code means staring at raw markdown, no token count, and no sense of how the rendered output actually reads.\n\nWrangle gives CLAUDE.md files first-class treatment. [...]",
  "features": ["AI file awareness", "Token counting", "XML-in-markdown highlighting", "Embedded terminals", "Inline markdown rendering"],
  "keyword": "CLAUDE.md editor"
}
```

**Fields to rewrite per entry (D-15):**

| Field | Current paid-language hits | Phase 17 action |
|-------|----------------------------|-----------------|
| `metaDescription` | "$19 one-time" / "$19 one-time purchase" | Rewrite to drop the dollar phrase; reframe as "free" / "open source" or simply omit the close-out sentence. Keep total length ≤ ~160 chars for SEO. |
| `body` | Entry 3 (`ai-prompt-editor-macos`) ends with literal `"Wrangle is the $19 tool that makes the process dramatically better."` | Rewrite the final sentence(s) per entry — drop the dollar reference; OSS framing acceptable. ~20–30 min/entry per D-15. |
| `h1`, `intro`, `features`, `keyword`, `slug`, `title` | No paid-language hits in these fields for the 3 target entries | LEAVE UNCHANGED unless audit surfaces a hit. |

**Untouched:** All other 17 entries in the array stay as-is. Phase 17 deliberately scopes to 3 entries (D-15).

---

### `Landing Page/src/pages/use-cases/[slug].astro` (page, MODIFIED — header/footer CTA only)

**Analog:** Self.

**Surface map** (current `[slug].astro`, 152 lines):

| Lines | Current content | Phase 17 action |
|-------|-----------------|-----------------|
| 14–15 | `version` + `downloadUrl` constants | DELETE (UI-SPEC URL Contract). |
| 24–39 | `<header>` with single `try free` button | REWRITE to dual CTA matching new homepage header (UI-SPEC Surface 1). Note: this file's header is **dual CTA** (matches index.astro), NOT the single-CTA compare-page header (UI-SPEC Surface 5). |
| 49–62 | Hero CTA stack (primary `buy — $19` + secondary `try free`) | REWRITE to dual CTA (hero size). |
| 108–114 | Guarantee section (`30-day money-back guarantee`) | DELETE entirely. Same pattern as index.astro lines 243–249. |
| 116–137 | Final CTA section | REWRITE inner CTA pair to dual CTA. UPDATE paragraph at line 119–121 (`one-time purchase, no subscription.`) → drop the price phrase, reframe as `free + open source`. UPDATE tagline at line 136 (`one-time purchase` → `free + open source`); class `text-[13px]` → `text-sm`. |
| 140–151 | `<footer>` | Same rewrites as homepage footer (see Shared Pattern: Footer Attribution). |

**Body content is data-driven from `use-cases.json`** (lines 78–80, 89–94) — those template loops do not need edits; the JSON rewrites (above) flow through automatically.

**Concrete excerpt — getStaticPaths pattern (lines 1-16, untouched):**
```astro
---
import Layout from "../../layouts/Layout.astro";
import "../../styles/global.css";
import useCases from "../../data/use-cases.json";

export function getStaticPaths() {
  return useCases.map((uc) => ({
    params: { slug: uc.slug },
    props: { useCase: uc },
  }));
}

const { useCase } = Astro.props;
const version = import.meta.env.APP_VERSION;
const downloadUrl = `https://dl.wrangleapp.dev/Wrangle-${version}.dmg`;
const canonical = `https://wrangleapp.dev/use-cases/${useCase.slug}`;

const paragraphs = useCase.body.split("\n\n").filter((p: string) => p.trim());
---
```
DELETE lines 14–15 (`version`, `downloadUrl`). Keep `canonical` and `paragraphs` lines.

---

### `Landing Page/src/pages/feedback.astro` (page, AUDIT-ONLY)

**Analog:** Self.

**Edit pattern (D-16, UI-SPEC implicit — not listed in §Surfaces):**

| Lines | Current content | Phase 17 action |
|-------|-----------------|-----------------|
| 99–110 | `<footer>` | UPDATE same as all other footers (Shared Pattern: Footer Attribution). Container class `text-xs` → `text-sm`. |
| 21–30 | `<header>` (logo only, no CTA) | NO CHANGE — feedback page header intentionally has no CTA (form is the primary action). |
| 1–98 | Form body, scripts, thank-you panel | NO CHANGE — D-16 explicitly preserves the route. Audit for `paid customer / refund / billing` language — `grep -i 'refund\|billing\|paid customer\|subscriber' feedback.astro` should return 0 hits (current file has none — verified during pattern mapping). |

**Untouched:** `@astrojs/vercel` adapter (via `astro.config.mjs`), `/api/feedback` route, `resend` dependency, `RESEND_API_KEY` env-var (D-16 + UI-SPEC constraint #5).

---

## Shared Patterns

### Shared Pattern A: Primary CTA Button (teal gradient)

**Source:** `Landing Page/src/pages/index.astro:43-48` (header size) and `Landing Page/src/pages/index.astro:60-65` (hero size).
**Apply to:** Every primary CTA across all surfaces.

**Hero size (UI-SPEC Surface 2, 4, 5-footer):**
```astro
<a
  href="https://github.com/J-Krush/wrangle/releases/latest"
  class="inline-flex items-center justify-center rounded-lg bg-linear-to-b from-teal to-teal-dark px-8 py-4 text-base font-bold text-dark hover:brightness-110 transition-all"
>
  Download for macOS
</a>
```

**Header / compact size (UI-SPEC Surface 1, 5-header):**
```astro
<a
  href="https://github.com/J-Krush/wrangle/releases/latest"
  class="inline-flex items-center justify-center rounded-lg bg-linear-to-b from-teal to-teal-dark px-4 py-2 text-sm font-bold text-dark hover:brightness-110 transition-all"
>
  Download for macOS
</a>
```

**Compare-page header variant** (UI-SPEC Surface 5, slightly larger compact padding):
```astro
<a
  href="https://github.com/J-Krush/wrangle/releases/latest"
  class="inline-flex items-center justify-center rounded-lg bg-linear-to-b from-teal to-teal-dark px-6 py-2.5 text-sm font-bold text-dark hover:brightness-110 transition-all"
>
  Download for macOS
</a>
```

**Existing-site delta:** The current pages use `font-medium` (header, 500) and `font-semibold` (hero, 600). UI-SPEC §Typography normalizes ALL CTA labels to `font-bold` (700). `font-semibold` (600) MUST NOT appear on any Phase 17 surface (UI-SPEC §Typography last paragraph). `px-6 py-2.5` is preserved on the compare-page header per the "Inherited exceptions" carve-out in UI-SPEC §Spacing.

---

### Shared Pattern B: Secondary CTA Button (outline)

**Source:** NEW pattern, no existing analog. The current pages use a `text-secondary text-sm` text-link as the secondary; UI-SPEC §"Secondary CTA visual style" explicitly upgrades this to an outline button.
**Apply to:** Every secondary CTA (UI-SPEC Surfaces 1, 2, 4, and the compare-page footer-CTA).

**Hero size (UI-SPEC Surfaces 2, 4):**
```astro
<a
  href="https://github.com/J-Krush/wrangle"
  class="inline-flex items-center justify-center gap-2 rounded-lg border border-border px-8 py-4 text-base font-bold text-primary hover:border-teal-dark hover:text-teal transition-all"
>
  <!-- GitHub mark SVG (20×20) here -->
  Star on GitHub
</a>
```

**Header / compact size (UI-SPEC Surface 1):**
```astro
<a
  href="https://github.com/J-Krush/wrangle"
  class="inline-flex items-center justify-center gap-1.5 rounded-lg border border-border px-4 py-2 text-sm font-bold text-primary hover:border-teal-dark hover:text-teal transition-all"
>
  <!-- GitHub mark SVG (16×16) here -->
  Star on GitHub
</a>
```

**GitHub mark SVG:** Inline directly in the anchor. Use the official 16-viewBox GitHub mark; size via the SVG's width/height attributes (16 for header, 20 for hero). No external icon library (UI-SPEC §Design System).

**`gap-1.5` (6px) on the header variant is preserved per the "Inherited exceptions" carve-out** in UI-SPEC §Spacing — non-multiple-of-4 carried over from the live site.

---

### Shared Pattern C: Dual CTA Container

**Source:** `Landing Page/src/pages/index.astro:59` (current container is `flex flex-col`).
**Apply to:** Hero (Surface 2), 404 (Surface 4), Final CTA on index + compare pages, and use-cases page hero/final-CTA.

**Pattern (UI-SPEC Surface 2, 4):**
```astro
<div class="flex flex-col sm:flex-row items-center gap-3">
  <!-- primary button first (left on desktop, top on mobile) -->
  <!-- secondary button second -->
</div>
```

**Existing-site delta:** Current container is `flex flex-col items-center gap-3` (column-only). Phase 17 adds `sm:flex-row` to make it side-by-side on `sm:` and up. Desktop: side-by-side. Mobile: stacked, Download on top (UI-SPEC §"Mobile" notes).

**Header variant (UI-SPEC Surface 1 — desktop and mobile both `flex-row`):**
```astro
<div class="flex flex-row items-center gap-2">
  <!-- primary + secondary always side-by-side -->
</div>
```

---

### Shared Pattern D: Footer Attribution (three-part)

**Source:** Currently `Landing Page/src/pages/index.astro:279-290` (single attribution); UI-SPEC Surface 6 extends to three-part.
**Apply to:** `index.astro`, all 5 `compare/*.astro`, `use-cases/[slug].astro`, `feedback.astro`, and the NEW `404.astro`. Eight files total carry this footer.

**Current pattern** (verbatim from `index.astro:279-290`):
```astro
<footer class="flex items-center justify-between px-5 lg:px-[200px] py-5 border-t border-border-subtle">
  <div class="flex gap-3 text-tertiary text-xs">
    <span>© 2026 wrangle</span>
    <span>·</span>
    <a href="https://jkrush.dev" target="_blank" class="hover:text-secondary transition-colors">built by J-Krush</a>
  </div>
  <div class="flex gap-3 text-tertiary text-xs">
    <a href="mailto:support@wrangleapp.dev" class="hover:text-secondary transition-colors">support</a>
    <span>·</span>
    <a href="https://github.com/J-Krush/wrangle-feedback" class="hover:text-secondary transition-colors">github</a>
  </div>
</footer>
```

**Phase 17 pattern (UI-SPEC Surface 6, verbatim):**
```astro
<footer class="flex items-center justify-between px-5 lg:px-[200px] py-5 border-t border-border-subtle">
  <div class="flex gap-3 text-tertiary text-sm">
    <span>© 2026 wrangle</span>
    <span>·</span>
    <a href="https://jkrush.dev" target="_blank" class="hover:text-secondary transition-colors">Built by J Krush</a>
    <span>·</span>
    <a href="./LICENSE" class="hover:text-secondary transition-colors">MIT</a>
  </div>
  <div class="flex gap-3 text-tertiary text-sm">
    <a href="mailto:support@wrangleapp.dev" class="hover:text-secondary transition-colors">support</a>
    <span>·</span>
    <a href="https://github.com/J-Krush/wrangle" class="hover:text-secondary transition-colors">github</a>
  </div>
</footer>
```

**Diffs from current:**
1. Both container `<div>`s: `text-xs` → `text-sm` (UI-SPEC §Typography — Fine-print role collapsed into Label/small).
2. Left column: `built by J-Krush` (hyphen, lowercase b) → `Built by J Krush` (capital B, no hyphen) — verbatim from D-09.
3. Left column: ADD `<span>·</span>` + `<a href="./LICENSE">MIT</a>` after the J Krush link.
4. Right column: github href `https://github.com/J-Krush/wrangle-feedback` → `https://github.com/J-Krush/wrangle` (UI-SPEC Surface 6 last paragraph). Label stays `github` (lowercase, unchanged).
5. `support@wrangleapp.dev` mailto: UNTOUCHED.

---

### Shared Pattern E: Header Block (logo + right-side actions)

**Source:** Two variants exist —
- **Variant 1** (root page, `index.astro:34-49`): logo wrapped in `<div>` (not clickable, since it's already the homepage).
- **Variant 2** (sub-pages, `compare/cursor.astro:14-30`, `use-cases/[slug].astro:24-39`, `feedback.astro:21-30`): logo wrapped in `<a href="/">` for home navigation.

**Apply to:** All 11 modified/new files except `astro.config.mjs`, `global.css`, and `use-cases.json`.

**Variant 1 (homepage only) — Phase 17 final shape (UI-SPEC Surface 1):**
```astro
<header class="flex items-center justify-between px-5 lg:px-[200px] py-4">
  <div class="flex items-center gap-2.5">
    <img src="/images/wrangle-logo-13.png" alt="wrangle logo" class="w-8 h-8 rounded" />
    <span class="text-base font-bold">wrangle</span>
  </div>
  <div class="flex flex-row items-center gap-2">
    <!-- primary header button (Pattern A header size) -->
    <!-- secondary header button (Pattern B header size) -->
  </div>
</header>
```

**Variant 2 (all sub-pages — compare/*, use-cases/[slug], 404) — Phase 17 final shape:**
```astro
<header class="flex items-center justify-between px-5 lg:px-[200px] py-4">
  <a href="/" class="flex items-center gap-2.5">
    <img src="/images/wrangle-logo-13.png" alt="wrangle logo" class="w-8 h-8 rounded" />
    <span class="text-base font-bold">wrangle</span>
  </a>
  <!-- For compare/*: single primary header button (Pattern A compare-page header size — UI-SPEC Surface 5) -->
  <!-- For use-cases/[slug] and 404: dual CTA matching Variant 1 -->
</header>
```

**Container padding `px-5 lg:px-[200px] py-4` is preserved exactly** — site-wide convention (UI-SPEC §Spacing "Exceptions").

---

### Shared Pattern F: Final-CTA Section Tagline

**Source:** `Landing Page/src/pages/index.astro:275` (and identically `compare/cursor.astro:232`, `use-cases/[slug].astro:136`).
**Apply to:** All final-CTA tagline spans across index.astro, all 5 compare/*.astro, and use-cases/[slug].astro.

**Current pattern (3 occurrences in the codebase — verified in CONTEXT.md §Boundary D-03 sweep):**
```astro
<span class="text-tertiary text-[13px]">macOS 15+ · apple silicon · one-time purchase</span>
```

**Phase 17 pattern (UI-SPEC Copywriting Contract):**
```astro
<span class="text-tertiary text-sm">macOS 15+ · apple silicon · free + open source</span>
```

**Diffs:** Class `text-[13px]` → `text-sm` (14px, UI-SPEC §Typography Fine-print collapse). Copy `one-time purchase` → `free + open source`.

---

### Shared Pattern G: Download URL Removal

**Source:** Three files declare `const downloadUrl = \`https://dl.wrangleapp.dev/Wrangle-${version}.dmg\`` in frontmatter:
- `Landing Page/src/pages/index.astro:5-6`
- `Landing Page/src/pages/use-cases/[slug].astro:14-15`
- `Landing Page/src/pages/compare/cursor.astro:5-6` (and identically in the 4 sibling compare pages)

**Apply to:** All 7 files declaring these constants.

**Edit pattern (UI-SPEC URL Contract):**
1. DELETE both lines from the frontmatter block.
2. Replace every `href={downloadUrl}` interpolation in the template body with the literal string `"https://github.com/J-Krush/wrangle/releases/latest"`.

**Verification:** After Phase 17, `grep -rn 'downloadUrl\|dl.wrangleapp.dev\|APP_VERSION' Landing\ Page/src/` must return 0 hits.

---

## No Analog Found

| File | Role | Data Flow | Reason / Donor |
|------|------|-----------|----------------|
| `Landing Page/src/pages/404.astro` | page (error) | request-response (SSG) | No existing 404 in the repo. Composite of two donors: shell from `feedback.astro` (Layout + noindex pattern), CTA stack from `index.astro:59-72` after Phase 17 rewrite. The `min-h-screen flex-col items-center justify-center` centered-column shape is new — UI-SPEC Surface 4 specifies it inline. |

Note: there is no truly "no analog" file in this phase. The 404 page is new but every visual primitive (Layout invocation, header, footer, CTA stack, typography roles) is lifted from existing analogs and recombined.

---

## Metadata

**Analog search scope:** `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/src/` (recursive), `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/astro.config.mjs`, `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/package.json`.
**Files scanned (read in full or targeted):** 7 (`astro.config.mjs`, `Layout.astro`, `global.css`, `index.astro`, `compare/cursor.astro` as canonical compare donor, `use-cases/[slug].astro`, `feedback.astro`) plus `package.json` and partial `use-cases.json` (first 5 entries).
**Files scanned (listing/grep only):** 5 (the 4 sibling compare pages — confirmed identical paid-language count to cursor.astro via grep, so cursor.astro is the canonical donor).
**Pattern extraction date:** 2026-05-21
