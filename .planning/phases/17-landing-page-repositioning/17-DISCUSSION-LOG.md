# Phase 17: Discussion Log

**Discussion conducted:** 2026-05-21
**Mode:** discuss (default; 4 questions per area, 4 areas)
**Areas selected:** all 4 (Pricing teardown + /404; Story section; Hero + CTA + download; Existing-pages audit)

This log captures the question-by-question flow for audit / retrospective purposes. It is NOT consumed by downstream agents (researcher, planner, executor) — `17-CONTEXT.md` is the canonical record.

---

## Area 1: Pricing teardown + /404 strategy

### Q1/4 — /buy redirect fate

**Options presented:**
1. Remove the redirect entirely — /buy returns 404 (Recommended)
2. Redirect /buy → GitHub Release (latest)
3. Redirect /buy → homepage with a banner explaining the change

**Selection:** Remove the /buy redirect entirely.

**Becomes:** D-01.

### Q2/4 — 404.astro shape

**Options presented:**
1. Smart 404 — OSS-flip context + dual CTA (Recommended)
2. Minimal 404 — "page not found" + back-to-home link
3. Vercel-level rewrites — specific 410 Gone for /buy /pricing /refund /terms; everything else → /

**Selection:** Smart 404.

**Becomes:** D-02.

### Q3/4 — Pricing/trial copy teardown scope

**Options presented:**
1. Full sweep — grep-and-replace every $19 / $24 / trial / buy / Pro mention (Recommended)
2. Homepage hero only — leave compare/use-cases CTAs for SITE-07 audit
3. Replace pricing claims but keep the schema.org Offer block with price: 0

**Selection:** Full sweep.

**Becomes:** D-03 + D-04 (the schema-org neutralization is part of the sweep, chose to drop the offers block entirely rather than `price: 0` per the recommendation).

### Q4/4 — LemonSqueezy account

**Options presented:**
1. Out of scope for Phase 17 — Phase 18 handles (Recommended)
2. Include in Phase 17 — deactivate LemonSqueezy store before deploy
3. Mark as a Phase 18 prerequisite todo, don't gate Phase 17

**Selection:** Out of scope for Phase 17.

**Becomes:** D-05.

---

## Area 2: Story section — placement, scope, voice

### Q1/4 — Story section placement

**Options presented:**
1. Inline homepage section, between hero and features (Recommended)
2. Dedicated /story (or /about) page + a 'Read the story' link on homepage
3. Both — short inline excerpt on homepage + full /story page with deep dive

**Selection:** Inline homepage section.

**Becomes:** D-06.

### Q2/4 — Story content scope

**Options presented:**
1. Match the README voice + numbers, but tighter (Recommended)
2. Lean essay with specifics — PH ranking, ad-spend numbers, conversion-rate data
3. Short manifesto — 3-4 sentences max, no dates/numbers

**Selection:** Match the README voice + numbers, but tighter.

**Becomes:** D-07.

### Q3/4 — Story voice + framing

**Options presented:**
1. Match README's voice verbatim where possible — distinct from rest of page (Recommended)
2. Lift README phrasing but soften into landing-page voice (third person)
3. Distinct narrative voice — lean into the portfolio-piece angle harder

**Selection:** Match README's voice verbatim.

**Becomes:** D-08.

### Q4/4 — Attribution

**Options presented:**
1. Story signs off with a small 'by J Krush' + jkrush.dev link
2. Footer-only attribution — keep story body voice-driven but unsigned (Recommended)
3. No personal attribution — 'Wrangle is open source, MIT' is enough

**Selection:** Footer-only attribution.

**Becomes:** D-09.

---

## Area 3: Hero rewrite + dual CTA + download target

### Q1/4 — Hero copy

**Options presented:**
1. Lock the new H1 + subhead verbatim now (most certainty)
2. Lock constraints, Claude drafts (Recommended)
3. Keep current H1, only update CTA + subhead

**Selection:** Lock constraints, Claude drafts.

**Becomes:** D-10.

### Q2/4 — CTA hierarchy

**Options presented:**
1. Download for macOS = primary (solid teal); Star on GitHub = secondary (outline / text link) (Recommended)
2. Co-equal dual buttons — both teal, side by side
3. Star on GitHub = primary (the OSS pivot is the story); Download = secondary

**Selection:** Download primary, GitHub secondary.

**Becomes:** D-11.

### Q3/4 — Download URL

**Options presented:**
1. `https://github.com/J-Krush/wrangle/releases/latest` (Recommended)
2. Direct pinned DMG URL
3. Astro endpoint that fetches /releases/latest then redirects
4. Keep dl.wrangleapp.dev pattern, repoint DNS at GitHub

**Selection:** `releases/latest`.

**Becomes:** D-12.

### Q4/4 — Sizzle video

**Options presented:**
1. Keep the existing video — it shows the product working (Recommended)
2. Replace with a screenshot/GIF montage from the app-repo README
3. Drop the video, no hero visual until a replacement is recorded

**Selection:** Keep the existing video.

**Becomes:** D-13.

---

## Area 4: Existing-pages audit scope

### Q1/4 — Compare pages

**Options presented:**
1. Keep all 5 — audit-and-update CTAs + download URLs only (Recommended)
2. Audit + delete pages whose narrative depends on paid-vs-free framing
3. Delete all 5 — compare pages are paid-launch SEO artifacts, retire with the pricing

**Selection:** Keep all 5 — audit-and-update CTAs.

**Becomes:** D-14.

### Q2/4 — Use-cases

**Options presented:**
1. Keep all 3 — rewrite the JSON to remove pricing language (Recommended)
2. Keep but defer to a v1.4 SEO refresh
3. Delete the use-cases route + JSON entirely

**Selection:** Keep all 3 — rewrite JSON.

**Becomes:** D-15.

### Q3/4 — Feedback form

**Options presented:**
1. Keep — audit copy for OSS positioning (Recommended)
2. Remove — redirect feedback to GitHub Issues
3. Keep route but disable the form post-deploy — explain on the page

**Selection:** Keep + audit.

**Becomes:** D-16.

### Q4/4 — OG image

**Options presented:**
1. Keep existing OG — only update text metadata (Recommended)
2. Generate new OG via scripts/og-image (mentioned in SITE-05)
3. Generate a new OG manually in Pencil

**Selection:** Keep existing OG.

**Becomes:** D-17.

---

## Cross-cutting decisions added during analysis

These weren't asked as explicit questions but were locked from the discussion context + Phase 15 carryover:

- **D-18** (top-nav rewrite) — derived from D-11 + Phase 15 D-08 (no /refund /terms in nav); planner finalizes.
- **D-19** (deploy via existing @astrojs/vercel + reversible) — derived from Phase 15 D-03 (adapter kept) + Phase 17 SITE-09; planner verifies.
- **D-20** (anti-regression: no filter-repo, no force-push, no hard-reset) — uniform pattern across Phase 14/15/16; Phase 17 continues.

## Deferred ideas captured

(Full list in `17-CONTEXT.md` `<deferred>` section.)

- LemonSqueezy account deactivation → Phase 18
- `dl.wrangleapp.dev` DNS retirement → Phase 18
- Repo public flip → Phase 18 (FLIP-02/03)
- GH Release publish → Phase 18 (FLIP-05)
- OG image regeneration via `scripts/og-image` → v1.4
- `.env.example` for contributor onboarding → v1.4 (also deferred in Phase 15 D-13)
- Vercel adapter swap to static → v1.4 (only if /feedback removed)
- Sticky-on-scroll header → v1.4
- Automated end-to-end deploy verification (Playwright) → v1.4
- `feedback.astro` redesign / GitHub Issues redirect → v1.4
- GitHub Actions / CI for landing repo → v1.4 (also deferred per REQUIREMENTS.md)
- PH ranking + ad-spend dollar amounts in story section → deliberately excluded; v1.4 may add a longer-form "lessons learned" page
- Personal signature inside story body → rejected in favor of footer-only attribution
- JSON-LD `creator` / `maintainer` schema property → Claude's Discretion; default skip
- Dedicated `/story` or `/about` page → not in Phase 17; v1.4 if story grows
- `/pricing` URL fate → never existed as a separate page; not reserved by Phase 17

## Scope creep redirects

None encountered during this discussion. The 4 areas selected map cleanly to SITE-01..SITE-10 plus the Phase 15 carryover items (compare/use-cases/feedback/OG-image). No new capabilities were proposed.
