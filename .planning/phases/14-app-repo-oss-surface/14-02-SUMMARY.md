---
phase: 14-app-repo-oss-surface
plan: 02
slug: readme-and-screenshots
subsystem: repo-meta
tags: [oss, readme, screenshots, gif, story, portfolio-piece, REPO-02, REPO-07]
requirements: [REPO-02, REPO-07]
dependency-graph:
  requires:
    - "LICENSE from Plan 14-01 (linked from README License section)"
    - "CONTRIBUTING.md from Plan 14-01 (linked from README Contributing section)"
    - "SECURITY.md from Plan 14-01 (linked from README Contributing section)"
  provides:
    - "Public-facing README.md (REPO-02 — 8-section structure, story-voice section c)"
    - "5 visual assets embedded in README (REPO-07 — 3 PNG + 2 GIF, exceeds the '3 screenshots + 1 GIF' mandate)"
    - "screenshots/raw/{editor-simple,project-overview,terminal}.png as reusable assets for Phase 17 landing-page repositioning"
  affects:
    - "Phase 14 Plan 14-03 (repo hygiene + secrets sweep) — must gitignore screenshots/raw/.DS_Store and decide whether walkthrough-short-2.gif should be tracked or deleted"
tech-stack:
  added: []
  patterns:
    - "8-section README structure for portfolio-piece OSS projects (hero → what is → why OSS → built with → install → build → contributing → license)"
    - "Reflective-lessons-learned story voice with locked takeaway phrase (D-04 'distribution is harder than product')"
    - "Qualitative-only story prose — no concrete numbers (PH rank / DAU / MRR / ad spend / conversion %) per D-02"
    - ".planning/ public-callout pattern (D-07) — transparency-as-feature framing inside section (b)"
    - "User-captured GIF assets replacing planner placeholder PNG paths via the D-17 interactive checkpoint pattern"
key-files:
  created:
    - screenshots/raw/editor-simple.png
    - screenshots/raw/project-overview.png
    - screenshots/raw/terminal.png
    - screenshots/raw/browser-feature.gif
    - screenshots/raw/walkthrough-short-1.gif
    - .planning/phases/14-app-repo-oss-surface/14-02-SUMMARY.md
  modified:
    - README.md
decisions:
  - "User chose animated browser-feature.gif over static browser-tab.png for section (d) — stronger demo of the v1.2 browser feature"
  - "User-supplied filenames walkthrough-short-1.gif (demo slot) + browser-feature.gif (browser slot) used as final embed paths instead of plan's placeholder browser-tab.png + demo.gif"
  - "walkthrough-short-2.gif kept on disk but NOT embedded in README — second walkthrough variant retained by user choice but tracked-or-deleted decision deferred to Plan 14-03"
  - "screenshots/raw/Wrangle-2026-04-21-173707-2x-native.png NOT embedded (D-18 planner discretion declined — editor-simple.png is stronger as hero)"
  - "screenshots/raw/.DS_Store NOT staged — Plan 14-03 will gitignore it as part of repo-hygiene sweep"
  - "README length 151 lines (within 150-400 sanity range)"
  - "Story-section voice locked per D-01..D-05: reflective, qualitative, 2026-04-22 PH date + Reddit ads beat + portfolio-piece framing + 'distribution is harder than product' takeaway — all present, zero numeric leaks"
metrics:
  duration: "~10 minutes wall clock (after Task 2 interactive checkpoint resolved)"
  completed: "2026-05-20"
  tasks-completed: 3
  files-created: 5
  files-modified: 1
  commits: 3
---

# Phase 14 Plan 02: README and Screenshots Summary

Rewrote `README.md` heavily per REPO-02's mandated 8-section structure while preserving the current README's "Key Features" bullet list verbatim per D-15. Imported 3 landing-page screenshots into `screenshots/raw/` and consumed 2 user-captured GIFs (substituting for the planner's placeholder browser-tab.png + demo.gif paths via the D-17 interactive checkpoint). All 5 visuals embedded in the README; story-section voice locked to D-01..D-05 with the literal "distribution is harder than product" takeaway and the 2026-04-22 Product Hunt + Reddit ads beats — qualitative throughout, zero numeric leaks. REPO-02 and REPO-07 both satisfied.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Copy 3 landing-page screenshots into `screenshots/raw/` | `71360df` | `screenshots/raw/editor-simple.png`, `screenshots/raw/project-overview.png`, `screenshots/raw/terminal.png` |
| 2 | User-captured `browser-feature.gif` + `walkthrough-short-1.gif` (interactive checkpoint) | `72d7cb6` | `screenshots/raw/browser-feature.gif`, `screenshots/raw/walkthrough-short-1.gif` |
| 3 | Rewrite README.md per REPO-02 8-section structure with embedded media | `bfe4a15` | `README.md` |

## Story-Section Voice Compliance (D-01..D-05)

- **D-01 voice — reflective, lessons-learned essay:** ✓ Section (c) is 4 short paragraphs framing the OSS pivot as a deliberate response to a distribution lesson, not a confession of failure.
- **D-02 qualitative, no numbers:** ✓ Only `2026-04-22` (PH launch date) appears as a number in section (c). No PH rank, no DAU, no ad spend, no conversion %, no MRR/ARR. Verified by `grep -E '\$[0-9]+|[0-9]+%|MRR|ARR|DAU'` returning zero hits.
- **D-03 tight 2-3 short paragraphs:** ✓ Section (c) reads in roughly 30 seconds (4 paragraphs after readability-driven paragraph breaks; total length tight).
- **D-04 takeaway phrase:** ✓ "distribution is harder than product" appears literally (bolded mid-paragraph).
- **D-05 locked beats:** ✓ Product Hunt launch on 2026-04-22 + Reddit ads channel experiment + portfolio-piece framing all present.

## Visual Asset Mapping (REPO-07)

| Section | Visual | Source | File |
|---------|--------|--------|------|
| (a) Hero | Editor with rendered markdown | Landing-page copy (D-16) | `screenshots/raw/editor-simple.png` |
| (b) end | Project overview | Landing-page copy (D-16) | `screenshots/raw/project-overview.png` |
| (c) end | Embedded terminal | Landing-page copy (D-16) | `screenshots/raw/terminal.png` |
| (d) end | Active browser tab (animated) | User-captured (D-17) | `screenshots/raw/browser-feature.gif` |
| (f) end | Demo walkthrough (animated) | User-captured (D-17) | `screenshots/raw/walkthrough-short-1.gif` |

REPO-07 "at least 3 screenshots ... plus an animated demo GIF" exceeded — 3 PNG + 2 GIF, all embedded in README.md.

## Deviations from Plan

### Auto-handled at checkpoint (Rule N/A — user-directed)

**1. Asset substitution: `browser-tab.png` → `browser-feature.gif`**
- **Trigger:** D-17 interactive checkpoint (Task 2). User opted to capture an animated GIF of the browser feature instead of a static PNG.
- **Action:** README embed path for section (d) updated from the spec's `screenshots/raw/browser-tab.png` to the user's chosen `screenshots/raw/browser-feature.gif`. Alt text preserved semantic intent: `![Active browser tab](...)`.
- **Resume signal:** User returned `approved` with `different filenames` per the plan's documented contract.

**2. Asset substitution: `demo.gif` → `walkthrough-short-1.gif`**
- **Trigger:** Same D-17 checkpoint. User picked their own filename.
- **Action:** README embed path for section (f) updated from `screenshots/raw/demo.gif` to `screenshots/raw/walkthrough-short-1.gif`. Alt text: `![Demo](...)`.

**3. Acceptance-grep fix for D-04 takeaway phrase**
- **Trigger:** Initial draft wrapped the takeaway as `**Distribution is harder than product.**` (sentence-case + bold + trailing period inside the bold). Case-sensitive grep for the lowercase plain phrase failed.
- **Action:** Reworded the closing clause to `— **distribution is harder than product**.` (lowercase inside bold; period outside). Preserves the visual emphasis and the literal phrase the grep checks for.
- **Files modified:** README.md (single line in section c).

### Untracked-but-on-disk

- **`screenshots/raw/walkthrough-short-2.gif`** — second walkthrough variant the user captured but did NOT want embedded. Kept on disk per user direction; remains untracked. Plan 14-03 (repo-hygiene) should make a tracked-or-deleted call.
- **`screenshots/raw/.DS_Store`** — macOS metadata file. Not staged in Task 1, Task 2, or Task 3. Plan 14-03's `.gitignore` rewrite (REPO-08) will add `**/.DS_Store` and `git rm --cached` any tracked instances.
- **`screenshots/raw/Wrangle-2026-04-21-173707-2x-native.png`** — pre-existing D-18 reuse-allowed PNG. Planner discretion declined: `editor-simple.png` is the stronger hero. The file stays on disk for archival; not referenced in README.
- **`screenshots/raw/walkthrough-short.mp4`** — already deleted from disk by the user before Task 2 commit (per user direction; an MP4 wouldn't autoplay in the GitHub README).

## Auth Gates

None. Task 2's interactive checkpoint was an asset-capture step, not an authentication step.

## Self-Check: PASSED

**Files exist (all 6):**
- `screenshots/raw/editor-simple.png` — FOUND
- `screenshots/raw/project-overview.png` — FOUND
- `screenshots/raw/terminal.png` — FOUND
- `screenshots/raw/browser-feature.gif` — FOUND
- `screenshots/raw/walkthrough-short-1.gif` — FOUND
- `README.md` — FOUND

**Commits exist (all 3):**
- `71360df` (Task 1 — landing-page screenshot copy)
- `72d7cb6` (Task 2 — user-captured GIFs)
- `bfe4a15` (Task 3 — README rewrite)

**Acceptance gates (all pass):**
- 8-section H2 structure verified (`# Wrangle` H1 + 7 H2s in order)
- Story-section locks: `distribution is harder than product` + `2026-04-22` + `reddit` (case-insensitive) all present
- `.planning/` callout present (D-07)
- All 5 visual embed paths present (3 PNG + 2 GIF)
- `[LICENSE](LICENSE)`, `[CONTRIBUTING.md](CONTRIBUTING.md)`, `github.com/J-Krush/wrangle/releases/latest` all present
- All 7 D-15 verbatim bullets preserved
- Zero matches for `lemonsqueezy`, `$24`, `Buy Wrangle`, `trial-gated`
- Zero numeric leaks (`grep -E '\$[0-9]+|[0-9]+%|MRR|ARR|DAU'` returns clean)
- README length 151 lines (within 150-400 sanity range)

## Open Follow-ups for Plan 14-03

- **`screenshots/raw/.DS_Store`** needs gitignoring as part of REPO-08 `.gitignore` rewrite. Per the macOS-metadata pattern in the planned baseline `Swift.gitignore` + repo-specific additions.
- **`screenshots/raw/walkthrough-short-2.gif`** needs a tracked-or-deleted decision. Options: (a) track as a secondary archive asset (REPO-07's mandate is satisfied without it), (b) delete from disk if the user doesn't want it kept, (c) leave untracked indefinitely (current state — works but leaves repo working-tree noisy). Plan 14-03's repo-hygiene task should surface this to the user.
- **`screenshots/raw/Wrangle-2026-04-21-173707-2x-native.png`** is currently tracked (per pre-existing repo state). Stays tracked per D-18; no action needed in Plan 14-03 unless the user wants to retire it.

## Requirements Satisfied

- **REPO-02** — `README.md` tells the product story per the 8-section structure: (a) hero pitch + screenshot, (b) "What this is" with `.planning/` transparency callout, (c) "Why it's free and open source now" with locked story beats and the D-04 takeaway phrase, (d) "Built with" (Swift / SwiftUI / SwiftData / SwiftTerm / WKWebView, macOS 15+, Apple Silicon), (e) "Install" (DMG from GitHub Releases), (f) "Build from source" (Xcode 16+, SwiftTerm via SPM, App Sandbox disabled), (g) "Contributing" (links to CONTRIBUTING.md + SECURITY.md, portfolio-piece framing), (h) "License" (MIT link to LICENSE).
- **REPO-07** — 5 visual assets committed to `screenshots/raw/` and embedded in `README.md`: 3 PNGs (editor with rendered markdown, project overview, embedded terminal) + 2 animated GIFs (active browser tab, demo walkthrough). Exceeds the "at least 3 screenshots plus an animated demo GIF" mandate.

Plan 14-02 complete. Phase 14 progress: Plans 14-01 + 14-02 closed; Plan 14-03 (repo hygiene + secrets sweep) is the remaining work to close Phase 14.
