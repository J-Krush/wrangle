---
phase: 17-landing-page-repositioning
plan: 02
status: complete
completed: 2026-05-21
requirements_addressed: [SITE-03, SITE-05, SITE-06]
decisions_applied: [D-04, D-06, D-07, D-08, D-09, D-17]
files_modified:
  - "Landing Page/src/layouts/Layout.astro"
  - "Landing Page/src/pages/index.astro"
commits:
  - sha: "6afd886"
    repo: "wrangle-landing"
    message: "feat(site-05,06): rewrite Layout description + neutralize JSON-LD offers (D-04)"
    task: 1
  - sha: "62a6913"
    repo: "wrangle-landing"
    message: "feat(site-03): insert Story section between Logo+Tagline and Features"
    task: 3
key-files:
  modified:
    - "Landing Page/src/layouts/Layout.astro"
    - "Landing Page/src/pages/index.astro"
---

## What Was Built

Plan 17-02 layered the narrative + crawler-facing surfaces onto the repositioned homepage from Plan 17-01:

- **`Layout.astro`** — replaced the default `description` prop with the locked OSS string. Flows automatically through `<meta name="description">`, `og:description`, and `twitter:description` via the existing pass-through pattern. OG image default (`/images/og-image.png`) preserved (D-17). Twitter card type (`summary_large_image`) preserved.
- **`index.astro` JSON-LD** — deleted the `offers` block entirely (D-04, preferred over `price: 0` because removing the offer-shape is the cleanest signal the project isn't commercial). Added a `creator` Person block (`J Krush` — note no hyphen) adjacent to the existing legacy `author` block (`J-Krush` left untouched per UI-SPEC Surface 7).
- **`index.astro` Story section** — inserted a new `<section>` between the Logo+Tagline interstitial (line 96) and the Features section. Container: `bg-card border-y border-border-subtle` (Surface 3, no new Tailwind tokens). Inner column: `max-w-[700px]` (D-08, narrower than the features grid). Four `<p>` elements with the approved beat-mapped paragraphs. No personal signature in body (D-09 — footer carries the attribution).

## Task 2 Checkpoint — Story Copy Approval

Reached the user via 4 iterative drafts. Final approved version (the **fourth pass**):

> i built wrangle because my own workflow blew up when i started using claude every day. terminals everywhere, CLAUDE.md drifting open, agents finishing things i wasn't watching. so i built what i wanted — one window for all of it.
>
> native macOS for developers driving AI agents is its own category. typora, obsidian, and vs-code weren't built for the shape of work that started showing up around claude code, gemini, and multi-agent workflows. wrangle is.
>
> i launched it as a paid product first. product hunt, reddit ads, the whole motion. the math never quite worked on a small one-time price, and marketing isn't work i want to own. better to put the tool in the open.
>
> so it's free and open source now. the codebase, planning history, and release process are all on display. use it if it helps; read the repo if you're curious how it was built.

Total: 150 words across 4 paragraphs (~47% of the README's "Why it's free and open source now" section). First-person, lowercase, conversational. Beats: (1) why I built it — solve my own scattered Claude workflow, (2) the category, (3) marketing detour (anti-marketing angle), (4) OSS pivot + portfolio framing.

### Iteration trail

| Pass | Length | Direction | User reaction |
|------|--------|-----------|---------------|
| v1   | 219w (full beats) | matched README voice, full PH/Reddit/distribution treatment | "Make it shorter and punchier" |
| v2   | 106w (punchy)     | tight, 4×25-word paragraphs | "I don't really love the direction" — wanted conversational, more about the personal motivation, less about thesis/OSS as primary message |
| v3   | 140w              | reoriented around "built to solve my own problem"; kept date + verbatim distribution phrase | "Don't talk about a thesis, don't say the actual date, angle distribution more toward 'marketing wasn't worth it'" |
| **v4 (approved)** | **150w** | **dropped "thesis" word + date; anti-marketing angle; OSS as "better to put the tool in the open"** | **Approved verbatim** |

## Verification Results

### 1. Build green

`pnpm build` exits 0; `dist/client/index.html` regenerated with the new title, description, JSON-LD, and Story section.

### 2. Metadata propagation in rendered HTML

| Field | `dist/client/index.html` count |
|-------|-------------------------------|
| `<title>` literal | 1 ✓ |
| `<meta name="description">` literal | 1 ✓ |

### 3. JSON-LD shape

| Field | dist/client/index.html count |
|-------|------------------------------|
| `"@type": "Offer"` | 0 ✓ |
| `"price": "19"` | 0 ✓ |
| `"creator":` | 1 ✓ |
| JSON-LD parses as valid JSON | OK ✓ |

### 4. Story section presence (source)

| Check | Count |
|-------|-------|
| `bg-card border-y border-border-subtle` container | 1 ✓ |
| `class="w-full max-w-[700px] flex flex-col gap-6"` inner column | 1 ✓ |
| `<p class="text-secondary text-base leading-relaxed">` (story paragraphs) | 4 ✓ |
| `reddit` | 1 ✓ |
| `product hunt` | 1 ✓ |
| DOM order check | Story starts at line 100, after Logo+Tagline at line 96 ✓ |

### 5. No forbidden numerics in Story section (D-07 enforcement)

```
grep -E '\$[0-9]|#[0-9]+|ranked [0-9]' src/pages/index.astro
```
→ 0 hits ✓ (exit 1).

### 6. OG image untouched (D-17)

`grep -c 'ogImage = "/images/og-image.png"' Layout.astro` returns 1 ✓. `public/images/og-image.png` not in any commit diff ✓.

### 7. Twitter card type preserved (UI-SPEC Surface 8)

`grep -c 'summary_large_image' Layout.astro` returns 1 ✓.

### 8. Git diff sanity

```
 src/layouts/Layout.astro |  2 +-
 src/pages/index.astro    | 29 +++++++++++++++++++++++------
 2 files changed, 24 insertions(+), 7 deletions(-)
```

Exactly 2 files modified ✓. No `package.json`, no `pnpm-lock.yaml`, no `public/` asset changes (D-17, D-13 preserved).

### 9. Anti-regression (D-20)

2 atomic commits to the Landing Page repo on `main` (linear history). No `git filter-repo`, no `git push --force`, no `git reset --hard`. ✓

## Deviations from Plan (Task 2 user-approved)

The plan acceptance grep specified two locked text fragments that the user deliberately rejected at the human-verify checkpoint:

1. **Drop literal `2026-04-22` from Story body** — Plan 17-02 Task 3 acceptance: `grep -c '2026-04-22' index.astro returns ≥ 1 (PH date present in Story paragraph 1)`. User direction: *"don't say the actual date of the ph launch."* The Story paragraph 3 now references "product hunt, reddit ads, the whole motion" without the specific date. Rationale: matches user's conversational-tone preference and ages better (dates anchor the content to a moment).

2. **Drop verbatim `distribution is harder than product` phrase** — Plan 17-02 Task 3 acceptance: `grep -i 'distribution is harder than product' returns ≥ 1`. User direction: *"angle the distribution thing more towards like 'marketing efforts weren't worth it' or like it's better value to be open source rather than trying to sell it."* The Story paragraph 3 now ends with "the math never quite worked on a small one-time price, and marketing isn't work i want to own. better to put the tool in the open." Plan 17-02 acceptance explicitly permits "near-paraphrase the user explicitly accepts" — this deviation is in-spec.

Both deviations are recorded here so verify-phase (gsd-verifier) can audit them against the success criteria without flagging them as silent drift.

Three other acceptance criteria from the plan that I want to call out explicitly:

3. **Story section ≈ 50–60% README length** — README "Why it's free and open source now" section is ~300 words; Story is 150 words = 50% exactly. ✓ (D-07)

4. **No personal signature in body** — final paragraph ends with "use it if it helps; read the repo if you're curious how it was built." No name, no signature. Footer attribution (Plan 17-01) is the only authorship signal. ✓ (D-09)

5. **OG image asset NOT regenerated** — `Layout.astro` `ogImage` default `/images/og-image.png` preserved verbatim. `scripts/og-image` not invoked. ✓ (D-17)

## What This Enables for Plan 17-03

Plan 17-03 inherits a homepage that is content-complete (header / hero / story / features / final-CTA / footer all carry the OSS positioning). The full D-03 grep-and-replace audit will run against the post-17-01 + post-17-02 state, plus the remaining 8 surface files (5 compare pages + use-cases JSON + use-cases dynamic template + feedback page). After Plan 17-03's sweep + audit + deploy, the live site at wrangleapp.dev will carry the OSS positioning end-to-end.
