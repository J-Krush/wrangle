# Phase 17: Landing Page Repositioning - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 17 rewrites the Astro landing page at `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/` (repo `J-Krush/wrangle-landing`, currently private) from "Buy Wrangle for $24/$19" positioning to "Free + open source macOS markdown editor for AI devs," with a working download CTA pointed at the v1.3.0 GitHub Release DMG produced by Phase 16.

Deliverables:

1. **Pricing teardown** — Remove the `/buy` redirect from `astro.config.mjs`; `/buy` becomes 404. Full grep-and-replace sweep across `.astro` / `.ts` / `.json` to strip "$19" / "$24" / "buy" / "trial" / "Pro" / "Premium" mentions (SITE-01, SITE-02, SITE-07).
2. **Smart 404.astro** — `404 — page not found` + OSS-flip context paragraph + dual CTA (Download for macOS / Star on GitHub). Catches old PH/Reddit inbound traffic from retired URLs (`/buy`, `/pricing`, `/refund`, `/terms`) and gives them somewhere useful to land (SITE-10).
3. **Hero rewrite** — New H1 + subhead under locked constraints (references free + open source + macOS + markdown editor + AI; ≤12 words / ≤40 words; lowercase, no marketing-speak). Dual CTA with `Download for macOS` primary (solid teal) + `Star on GitHub` secondary (outline / text link). Download targets `https://github.com/J-Krush/wrangle/releases/latest`. Existing `wrangle-1.2-sizzle.mp4` retained (SITE-01, SITE-08).
4. **Story section** — Inline homepage block between hero and features, first-person voice matching the app-repo README (PH 2026-04-22 launch beat, Reddit ads channel experiment, native-for-AI-devs thesis, "distribution is harder than product" takeaway, OSS-as-portfolio framing). ~50–60% of README length; no PH ranking specifics, no ad-spend dollars. Visually distinct from rest of page (lighter background, narrower column). Footer carries `Built by J Krush · jkrush.dev · MIT` attribution (SITE-03).
5. **Top-nav update** — Remove "Buy" / "Pricing" / "try free" entries (currently the header has "try free" + the hero has "buy — $19"). Add a "GitHub" link (icon + label) (SITE-04).
6. **SEO + social metadata** — `Layout.astro` page title / meta description / Open Graph tags rewritten for the OSS positioning. Twitter / X card metadata matches (SITE-05, SITE-06). **OG image not regenerated** — existing asset reused; only text metadata changes.
7. **Compare pages audit (5 entries)** — `compare/cursor.astro` / `ia-writer.astro` / `obsidian.astro` / `typora.astro` / `vs-code.astro`: substance kept (positioning is OSS-neutral), header CTA + footer CTA + download URL updated. ~10–15 min of automated find-and-replace per page (SITE-07).
8. **Use-cases audit (3 entries)** — `src/data/use-cases.json` JSON entries (`claude-md-editor`, `markdown-editor-token-counting`, `ai-prompt-editor-macos`): rewrite `metaDescription` + `body` to drop `"$19 one-time"` claims; reframe as "free" / "open source"; update CTAs + download URL. ~20–30 min per entry (SITE-07).
9. **Feedback form retained + audited** — `/feedback` + `/api/feedback` stay (carryover from Phase 15 D-03). Audit `feedback.astro` for "paid customer / refund" language. Keep `@astrojs/vercel` adapter; `RESEND_API_KEY` env-var dependency preserved.
10. **Deploy** — Same production target that currently serves `wrangleapp.dev` (Vercel per existing `@astrojs/vercel` adapter). Deploy is reversible. Plan determines whether `vercel.json` rewrites are needed for any redirect logic beyond the smart 404 (SITE-09).

What Phase 17 does NOT deliver:

- **LemonSqueezy store / product deactivation** — Phase 18 (FLIP) handles vendor-account cleanup as part of the final pre-flip sweep. Phase 17 keeps focus on the landing page itself.
- **Repo public flip** — Phase 18 (FLIP-02 / FLIP-03). Phase 17 ships changes while `J-Krush/wrangle-landing` is still private.
- **GH Release publish** — Phase 18 (FLIP-05). Phase 17's download CTA points at `releases/latest` which returns 404 during Phase 17 (private repo + draft state — D-10 from Phase 13). Phase 18 publishing flips it to 200.
- **`scripts/og-image` regeneration** — text-only metadata update (SITE-05 satisfied at the text level; OG image asset reused).
- **`.env.example`** — deferred from Phase 15 D-13; reconsider in v1.4 if contributor onboarding matters.
- **Vercel adapter swap to static** — kept because `/api/feedback` requires server execution (carryover from Phase 15).
- **New marketing assets** (new sizzle, new GIFs, new OG image) — v1.4 territory if needed.

</domain>

<decisions>
## Implementation Decisions

### Pricing teardown (SITE-01, SITE-02, SITE-07)

- **D-01:** Remove the `/buy` redirect entirely from `astro.config.mjs`; `/buy` returns 404. No replacement redirect to LemonSqueezy or GitHub. Pairs with D-02's smart 404 to catch the traffic.
- **D-02:** `404.astro` is a smart 404. Renders `404 — page not found` H1 + one-paragraph OSS-flip context: *"Wrangle is now free and open source. The old paid surface (`/buy`, `/pricing`, `/refund`, `/terms`) was retired in the OSS flip."* + dual CTA (`Download for macOS` → `releases/latest`; `Star on GitHub` → `https://github.com/J-Krush/wrangle`). Same component shape as the homepage hero CTA pair so visually consistent.
- **D-03:** Full grep-and-replace sweep, single plan. Pattern set: `$19`, `$24`, `buy — `, `buy --`, `try free`, `trial`, `\bPro\b` (word-boundary), `\bPremium\b`, `one-time`, `purchase`, `LemonSqueezy`, `lemonsqueezy.com`. Verify zero hits in `.astro` / `.ts` / `.json` working-tree after sweep (audit-style check, matches Phase 13's APP-13 + Phase 15's LAND-05 patterns).
- **D-04:** Neutralize JSON-LD Offer block in `src/pages/index.astro`. **Drop the `offers` schema property entirely** (preferred) rather than setting `price: 0`. Rationale: removing the Offer block is the cleanest signal that this isn't a commercial product anymore; `price: 0` keeps the offer-shape and can confuse Google's free-software rich result. SoftwareApplication schema is fine without an `offers` property.
- **D-05:** LemonSqueezy account (`jkrush.lemonsqueezy.com/checkout/buy/8860d1f0-...`) deactivation deferred to Phase 18 FLIP work. Phase 17 only removes the landing-page-side references; the LS dashboard cleanup is a vendor-account chore that doesn't gate the deploy.

### Story section (SITE-03)

- **D-06:** Story is an **inline homepage section between the hero and the features list**. Replaces or sits just after the existing `Logo + Tagline` interstitial (`<img wrangle-logo-transparent.png /> + "wrangle your agents." H2`). No new page (no `/story` or `/about`).
- **D-07:** Story content matches the app-repo README voice and beats (Phase 14 Plan 02 D-01..D-05 locked copy), but ~50–60% the length. Beats to include: PH launch on 2026-04-22, Reddit ads as a channel experiment that didn't scale, native-for-AI-devs thesis, "distribution is harder than product" takeaway, OSS-as-portfolio framing. **Do NOT include**: specific PH ranking numbers, specific ad-spend dollar amounts, specific conversion rates. Reason: numbers age, less-specific copy ages better.
- **D-08:** Voice — first-person, lowercase, no marketing-speak (matches both the README and the rest of the landing page's existing register). Visually distinct from the rest of the page: lighter background (subtle tint, not stark white), narrower max-width column (`max-w-[700px]` to match story-paragraph readability vs the `max-w-[1040px]` features grid). Signals "this is the honest part" without breaking page rhythm.
- **D-09:** No personal signature inside the story section body. Footer carries the attribution: `Built by J Krush · jkrush.dev · MIT` (the existing footer doesn't currently surface this — Phase 17 adds it as a single line). The reader infers authorship from first-person voice + footer link; no redundant signature mid-story.

### Hero rewrite + dual CTA (SITE-01, SITE-08)

- **D-10:** Hero H1 + subhead — **constraints locked, exact wording is Claude's discretion** (executor proposes 2–3 options at execution time; user picks before final commit). Constraints:
  - H1 references at least 3 of: `free`, `open source`, `macOS`, `markdown editor`, `AI` (or AI-dev variants).
  - H1 length: ≤ 12 words.
  - Subhead echoes the app-repo README's *"native macOS workspace for developers driving AI agents"* beat.
  - Subhead length: ≤ 40 words.
  - Tone: lowercase, no marketing-speak. Matches the existing register on the live page (`the markdown editor built for AI-native development.`).
  - Implicit: do NOT promise features the v1.3.0 binary doesn't ship.
- **D-11:** Dual CTA visual hierarchy — `Download for macOS` is **primary** (existing solid teal gradient button style — the current "buy — $19" treatment); `Star on GitHub` is **secondary** (outlined button OR text-link-with-icon; planner picks based on visual balance). Order: Download first (left), GitHub second (right). Mobile: stacked, Download on top.
- **D-12:** Download CTA target: `https://github.com/J-Krush/wrangle/releases/latest`. **Future-proof**: GitHub redirects to the newest published release; v1.4 ships without code changes. Lands on the Release page (not direct DMG download) — visitor clicks the `Wrangle-1.3.0.dmg` asset to pull the file. One extra click but visitors see release notes + verify they got the right thing. Replaces the existing `https://dl.wrangleapp.dev/Wrangle-${version}.dmg` template entirely (`dl.wrangleapp.dev` DNS is unused after Phase 17 — Phase 18 may retire the subdomain or leave it dangling).
- **D-13:** Keep the existing `public/videos/wrangle-1.2-sizzle.mp4` autoplaying in the hero. The video showcases features that still ship in v1.3 (browser tabs, terminal, editor, AI-file recognition). Marketing surface ≠ product surface; the video is honest about what Wrangle does. No regeneration in Phase 17.

### Existing-pages audit (SITE-07)

- **D-14:** All 5 `compare/*.astro` pages (cursor, ia-writer, obsidian, typora, vs-code) **kept**. Substance is OSS-neutral (positioning of Wrangle relative to each competitor doesn't depend on commercial framing). Phase 17 sweep updates: header CTA (`buy — $19` → matches new hero CTA pair OR a single `Download` button per page), download URL template, footer CTA. No body-prose edits unless a page has explicit "$19" / "trial" / "Pro" language (planner audits each).
- **D-15:** All 3 `use-cases.json` entries (`claude-md-editor`, `markdown-editor-token-counting`, `ai-prompt-editor-macos`) **kept**. Each has heavier paid-product language in `metaDescription` + `body` than the compare pages (e.g., `"$19 one-time purchase"`, `"Wrangle is the $19 tool that makes the process dramatically better."`). Rewrite both fields per entry to drop pricing claims — replace with "free" / "open source" / drop the dollar-amount sentence entirely. ~20–30 min per entry. CTAs + download URL also updated. `[slug].astro` template only needs header/footer CTA updates (it's largely data-driven from the JSON).
- **D-16:** `/feedback` page + `/api/feedback` route **kept** (carryover from Phase 15 D-03). Phase 17 audits `feedback.astro` for "paid customer / refund / billing" language; otherwise leaves the route alone. `@astrojs/vercel` adapter stays. `RESEND_API_KEY` env-var stays as dev-time-warning-tolerable per Phase 15 D-12.
- **D-17:** OG image — existing asset reused (whichever PNG `Layout.astro` currently references). Only text metadata (page title, meta description, OG title, OG description, Twitter card title/description) is updated. `scripts/og-image` not run in Phase 17. SITE-05 satisfied at the text level; new OG asset is v1.4 territory if needed.

### Cross-cutting (SITE-04, SITE-09, deploy)

- **D-18:** Top-nav rewrite. Current header has `try free` button (top-right). Replace with the dual CTA (Download primary + GitHub secondary, smaller scale than hero CTA pair). The hero retains the larger dual CTA; the header is a compact echo. Internal nav links to `/pricing` (if any in `Layout.astro` or any page header/footer) get updated/removed — planner greps and fixes.
- **D-19:** Deploy uses the existing `@astrojs/vercel` adapter and the production target currently serving `wrangleapp.dev`. Deploy is reversible (Vercel keeps previous deployments; one click to roll back). No `vercel.json` introduced unless the smart 404 + the removed `/buy` redirect require server-config rewrites — planner determines (likely not needed; Astro's `404.astro` + the removed `redirects: { '/buy': … }` in `astro.config.mjs` handles both via Astro routing).
- **D-20:** Anti-regression — same shape as Phase 14 D-09 / Phase 15 D-09 / Phase 16 D-09. **No `git filter-repo`, no `git push --force`, no `git reset --hard`** in the landing repo during Phase 17. History is preserved per Phase 15 D-09. Any commit that breaks deploys gets reverted via a new commit (not history rewrite).

### Claude's Discretion

- **Exact H1 + subhead text** — executor proposes 2–3 options at execution time; user picks before final commit (per D-10).
- **Story-section paragraph structure** — 3–5 paragraphs; planner drafts and user accepts/edits during the Task 3 (or wherever the story lands in the task breakdown) human-verify checkpoint.
- **Visual differentiation of the story section** — lighter background tint (planner picks the exact value within Tailwind's palette to match the page's color system; recommend a slightly desaturated variant of the existing dark theme), narrower max-width column.
- **GitHub link button style for secondary CTA** — outline button vs text-link-with-GitHub-icon. Planner picks based on visual balance in mobile + desktop renders.
- **Whether the top-nav becomes a sticky-on-scroll element** — current isn't sticky; Phase 17 doesn't require a change. If the planner wants sticky-nav for download-CTA-always-visible reasons, that's a Phase 17 addition under SITE-04. Otherwise, skip.
- **Header CTA on compare pages** — keep both `Download` + `GitHub` OR simplify to just `Download` (since the page itself is comparison content; cleaner header). Planner picks; default recommendation: just `Download` to reduce header noise on long pages.
- **JSON-LD `creator` / `maintainer` schema property** — when removing the `offers` block, the schema can optionally add `creator: { @type: Person, name: "J Krush", url: "https://jkrush.dev" }` to signal authorship. Planner adds if it doesn't make the block more complex.
- **Order of Phase 17 commits / plans** — planner breaks into 2–3 plans (ROADMAP estimated 3: hero+nav+pricing teardown / story+OG+SEO / download wiring+deploy). Either 2 or 3 plans is acceptable; the work has natural seams.
- **Whether `dl.wrangleapp.dev` DNS gets explicitly retired in Phase 17 or left dangling** — Phase 17 only removes references from the landing-page code. DNS-record cleanup is Phase 18's call (it's a separate provider account).
- **Whether to verify the deployed site against an automated end-to-end check** (Playwright or curl-based) or rely on manual smoke test — planner picks based on existing Phase 14/15 verification patterns (which used manual + grep audits, not browser automation).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements

- `.planning/REQUIREMENTS.md` §SITE — `SITE-01` through `SITE-10` (the 10 requirements this phase satisfies, 1-to-1 with Phase 17).
- `.planning/ROADMAP.md` §"Phase 17: Landing Page Repositioning" — Goal, Depends-on (Phase 15 + Phase 16), Success Criteria (5 rows), Plans (expected: 3).
- `.planning/PROJECT.md` §"Current Milestone v1.3" — milestone narrative; paragraph on "Landing page repositioning" target features. §"Key Decisions" — MIT-OSS posture, both-repos-flip-public-at-end posture.

### Prior-phase context that flows through

- `.planning/phases/15-landing-repo-oss-surface/15-CONTEXT.md` — Phase 15 D-08 deleted `/refund` + `/terms`; D-09 preserved history; D-10 audit-deliverable shape; D-11 forbidden-string list (Phase 17 mirrors the audit pattern for SITE-07 sweep); D-12 clean-checkout verification (Phase 17 should re-run after its changes); deferred items list at the bottom names exactly the surfaces Phase 17 picks up (compare pages, use-cases, og-image, feedback-form fate, Vercel-adapter swap option).
- `.planning/phases/14-app-repo-oss-surface/14-02-SUMMARY.md` — README locked copy (D-15 7 bullets verbatim, story-section voice from D-01..D-05). Phase 17 story section reuses the same voice and the same beats at a tighter length.
- `.planning/phases/13-app-de-commercialization/13-CONTEXT.md` — D-09/D-10/D-11 (UpdateChecker repoint, `/api/version.json` retirement); APP-13 grep-audit pattern (Phase 17 mirrors for the SITE-07 sweep); "strip wholesale" philosophy that Phase 17 continues.
- `.planning/phases/16-signed-dmg-release-pipeline/16-02-SUMMARY.md` — DMG SHA-256, GH Release URL pattern, draft-state behavior. Phase 17's download CTA depends on the v1.3.0 GH Release that exists as a draft at Phase 17 start; Phase 18 publishes it.

### Repo on disk (the actual Phase 17 working surface)

- `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/` — repo root for `J-Krush/wrangle-landing` (remote: `git@github.com:J-Krush/wrangle-landing.git`).
- `Landing Page/astro.config.mjs` — has the `/buy` redirect (current line 16–19). Remove per D-01.
- `Landing Page/src/pages/index.astro` — current homepage. Hero rewrite (D-10..D-13) + JSON-LD neutralization (D-04) + new story section insertion (D-06..D-08) + footer attribution add (D-09) + nav rewrite (D-18).
- `Landing Page/src/pages/404.astro` — does NOT currently exist. Create per D-02. Astro's default 404 fires until then.
- `Landing Page/src/pages/compare/{cursor,ia-writer,obsidian,typora,vs-code}.astro` — 5 files. Header CTA + footer CTA + download URL updates per D-14.
- `Landing Page/src/pages/use-cases/[slug].astro` + `Landing Page/src/data/use-cases.json` — dynamic route + 3 JSON entries. JSON rewrite per D-15.
- `Landing Page/src/pages/feedback.astro` + `Landing Page/src/pages/api/feedback.ts` — kept per D-16. Light audit only.
- `Landing Page/src/layouts/Layout.astro` — global metadata (page title, description, OG, Twitter). SITE-05/06 updates. Phase 15 D-08 already neutralized the default description; Phase 17 rewrites comprehensively.
- `Landing Page/src/styles/global.css` — Tailwind base + any custom theme tokens. Story-section background-tint discretion lives here.
- `Landing Page/public/videos/wrangle-1.2-sizzle.mp4` — kept per D-13. No change.
- `Landing Page/public/images/og-*.png` (whichever file Layout.astro references) — kept per D-17.
- `Landing Page/public/images/wrangle-logo-13.png`, `wrangle-logo-transparent.png` — kept; used by header + the logo+tagline section.
- `Landing Page/.env` (LOCAL ONLY — gitignored) — `APP_VERSION=1.3.0` (per `scripts/bump-version.sh` from the app repo). Phase 17 may stop using `import.meta.env.APP_VERSION` if D-12's `releases/latest` URL doesn't need version templating.
- `Landing Page/package.json` + `pnpm-lock.yaml` — Astro v5.18.0 + `@astrojs/vercel` + `@astrojs/sitemap` + Tailwind. No new dependencies expected (the redirect-removal + the 404.astro + the JSON edits are pure-Astro work).

### Templates and conventions

- App-repo README at `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/README.md` — story-section voice source per D-07/D-08. Phase 14 Plan 02 D-15 locked 7 bullets verbatim; Phase 17 uses a subset.
- Phase 14 + Phase 15 commit cadence — atomic commits per logical change (Pattern E). Phase 17 follows the same convention.
- Phase 13 APP-13 grep-audit pattern — Phase 17 mirrors for the SITE-07 sweep (D-03).

### Documents to (NOT) write in this phase

- `SECURITY.md` — Phase 14 (REPO-10) covers the app repo; landing repo doesn't need one (no security surface beyond Vercel-managed deploy). Phase 15 already decided.
- `CONTRIBUTING.md` for the landing repo — landing repo doesn't have one and Phase 17 doesn't add one. Future phase if needed.
- `.env.example` — deferred from Phase 15 D-13; Phase 17 also does NOT add (lock).
- Standalone `SITE-AUDIT.md` inside the landing repo — Phase 14/15 pattern is to record audit results inside the phase SUMMARY.md, not in a repo-visible file. Phase 17 follows the same pattern.
- Anything in `pencil/` — leave the Pencil design file untouched (Phase 15 D-04). Not a Phase 17 surface.

</canonical_refs>

<specifics>
## Specific Ideas

- **Download CTA URL (verbatim)**: `https://github.com/J-Krush/wrangle/releases/latest`. Used in: homepage hero, header nav, smart 404, compare pages, use-cases pages, anywhere a download button exists. Single canonical URL across the site.
- **GitHub CTA URL (verbatim)**: `https://github.com/J-Krush/wrangle`. Used in: homepage hero, header nav, smart 404, footer, story section. Single canonical URL.
- **Footer attribution (verbatim)**: `Built by J Krush · jkrush.dev · MIT`. Three elements separated by middle dots. Each is a link: `jkrush.dev` → `https://jkrush.dev`; `MIT` → `./LICENSE` (the LICENSE file in the landing repo, added in Phase 15 LAND-02).
- **404.astro paragraph (verbatim seed — refine in plan)**: *"Wrangle is now free and open source. The old paid surface (`/buy`, `/pricing`, `/refund`, `/terms`) was retired in the OSS flip."* Followed by the dual CTA pair.
- **PH launch date**: `2026-04-22`. Used in the story section verbatim.
- **PH ranking**: NOT included. Per D-07.
- **Reddit ads beat**: included as "ran Reddit ads as a channel experiment" (or similar wording). NO dollar amounts. Per D-07.
- **OSS-as-portfolio framing (verbatim seed)**: *"Wrangle is now free and open source — shipped as a portfolio piece for anyone who'd find it useful."* Already locked in the v1.3.0 WhatsNewChangelog entry (Phase 13) and the README (Phase 14 Plan 02).
- **JSON-LD schema property change**: drop the `offers: { @type: "Offer", price: "19", priceCurrency: "USD", availability: "https://schema.org/InStock" }` block entirely from the `index.astro` JSON-LD. Keep the rest of the SoftwareApplication schema (name, description, url, applicationCategory, operatingSystem, processorRequirements, author, screenshot).
- **Astro version**: v5.18.0 (per Phase 15 D-12 verification). No upgrade in Phase 17.
- **pnpm commands**: `pnpm install` / `pnpm dev` / `pnpm build` (per Phase 15 README D-14). Phase 17 doesn't change these.
- **Tailwind classes used in hero**: `bg-linear-to-b from-teal to-teal-dark` for primary CTAs; `text-secondary` for muted text. Existing palette preserved.
- **Sticky header**: NOT introduced in Phase 17 (Claude's Discretion default).
- **Header CTA on compare pages**: single `Download` button only (Claude's Discretion default; reduces header noise).
- **Twitter card type**: `summary_large_image` (assumed current; Phase 17 only updates title/description text, not the card type).

</specifics>

<deferred>
## Deferred Ideas

- **LemonSqueezy store/product deactivation** — Phase 18 (FLIP) vendor-account cleanup. Per D-05.
- **`dl.wrangleapp.dev` DNS retirement** — Phase 18's call. Phase 17 stops referencing the subdomain in code; the DNS record itself outlives Phase 17. Per D-12.
- **Repo public flip** — Phase 18 FLIP-02 / FLIP-03.
- **GH Release publish** — Phase 18 FLIP-05. Phase 17's download CTA returns 404 unauth between Phase 17 deploy and Phase 18 publish; this is expected (D-10 locked from Phase 13).
- **OG image regeneration via `scripts/og-image`** — v1.4 if needed. Phase 17 keeps the existing asset (D-17).
- **`.env.example`** — Phase 15 D-13 deferred; Phase 17 also defers. v1.4 if contributor onboarding matters.
- **Vercel adapter swap to static** — Phase 17 keeps `@astrojs/vercel` because `/api/feedback` requires server execution (D-16). v1.4 if `/feedback` gets removed and the route count drops to zero.
- **Sticky-on-scroll header / download-CTA-always-visible UX** — Claude's Discretion; default is "skip in Phase 17". v1.4 polish if engagement data warrants.
- **Automated end-to-end deploy verification (Playwright / curl-based)** — Claude's Discretion; default matches Phase 14/15 manual+grep verification.
- **`feedback.astro` route redesign / moving to GitHub Issues** — kept in Phase 17 (D-16). If post-flip feedback volume is low, v1.4 may redirect /feedback → GitHub Issues and drop the Resend dependency.
- **GitHub Actions / CI for the landing repo** — out of milestone (deferred to v1.4 per `REQUIREMENTS.md` "Future Requirements").
- **PH ranking + ad-spend dollar amounts in the story section** — deliberately excluded per D-07; v1.4 may add a longer-form "lessons learned" page if there's audience signal.
- **Personal signature inside the story section body** — rejected in favor of footer-only attribution per D-09. Revisit only if reader feedback says the section feels unattributed.
- **JSON-LD `creator` / `maintainer` schema property** — Claude's Discretion; planner adds if it's cheap. Otherwise v1.4.
- **A dedicated `/story` or `/about` page** — Phase 17 chooses inline-only per D-06. If the story section grows past ~5 paragraphs, v1.4 can break it out.
- **`pricing` URL** — never existed as a separate Astro page (it was always implicitly the `/buy` redirect). Phase 17 doesn't reserve `/pricing` — if a future change wants a `/pricing` page, v1.4 owns the decision.

### Posture revisit triggers

Reconsider D-12 (`releases/latest` URL) ONLY if:
- v1.4 ships and the `releases/latest` redirect breaks for an unexpected GitHub-side reason.
- A user reports the extra-click-from-Release-page UX is hurting download conversion.

Reconsider D-13 (keep sizzle video) ONLY if:
- The v1.2 sizzle's UI no longer matches the v1.3 product after the OSS flip (it should — the OSS pivot didn't change the in-app UI).
- A polished new sizzle becomes available and the swap is cheap.

Reconsider D-17 (reuse existing OG image) ONLY if:
- Twitter/LinkedIn unfurl shows the old image with a misleading association (paid-product framing in the image text).
- Social-card click-through rates underperform after the OSS-flip launch.

</deferred>

---

*Phase: 17-landing-page-repositioning*
*Context gathered: 2026-05-21*
