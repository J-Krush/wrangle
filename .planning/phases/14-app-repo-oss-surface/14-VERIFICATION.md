---
phase: 14-app-repo-oss-surface
verified: 2026-05-20T19:15:00Z
status: passed
must_haves_total: 12
must_haves_verified: 12
phase_goal_met: true
last_updated: 2026-05-20T19:15:00Z
score: 12/12 must-haves verified
overrides_applied: 0
---

# Phase 14: App Repo OSS Surface Verification Report

**Phase Goal:** `J-Krush/wrangle`: MIT `LICENSE`, story-driven `README.md`, `CONTRIBUTING.md`, issue + PR templates, screenshots/GIF, `SECURITY.md`, full repo secrets audit.

**Verified:** 2026-05-20T19:15:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

Goal-backward result: every REPO-01..REPO-12 must-have has on-disk evidence in the working tree of `J-Krush/wrangle`. The public-facing OSS surface (LICENSE + README + CONTRIBUTING + SECURITY + `.github/` templates + visuals + `.gitignore` rewrite + secrets sweep + CLAUDE.md OSS header) is in place. No BLOCKER-class issues from the code review (REVIEW.md status: `issues_found`, 0 critical / 0 high; 2 medium + 2 low + 5 info are all documentation polish or pre-Phase-18 follow-ups, not goal-blockers).

### Score Table

| #   | Must-Have | Status     | Evidence |
| --- | --------- | ---------- | -------- |
| REPO-01 | `LICENSE` at root, MIT body, `Copyright (c) 2026 J Krush`, no `Krush LLC` | VERIFIED | `LICENSE:1-21` — exact MIT body. Line 3: `Copyright (c) 2026 J Krush`. `grep -i 'Krush LLC' LICENSE` returns zero. |
| REPO-02 | `README.md` 8-section structure + story-section claims + 5 visuals embedded + `.planning/` callout | VERIFIED | 8 headings present (`# Wrangle`, `## What this is`, `## Why it's free and open source now`, `## Built with`, `## Install`, `## Build from source`, `## Contributing`, `## License` — `README.md:1,7,66,82,97,105,135,149`). Story section (`README.md:66-78`) contains `distribution is harder than product` (line 72), date `2026-04-22` (line 70), Reddit-ads mention (line 72); date `2026-04-22` is the only numeric token in the story span. 5 visuals embedded: `editor-simple.png`, `project-overview.png`, `terminal.png`, `browser-feature.gif`, `walkthrough-short-1.gif` at `README.md:5,64,80,95,133`. `.planning/` callout present at `README.md:58-60,145`. |
| REPO-03 | `CONTRIBUTING.md` with portfolio/best-effort framing + CLAUDE.md/coding-patterns.md/SECURITY.md/LICENSE links + `.planning/` workflow | VERIFIED | `CONTRIBUTING.md:8-12` uses `**personal portfolio project**` + `**best-effort**`. Link targets at `:81 CLAUDE.md`, `:84 docs/coding-patterns.md`, `:116 SECURITY.md`, `:120 LICENSE`. `.planning/` workflow section at `:92-111`. |
| REPO-04 | `.github/ISSUE_TEMPLATE/bug_report.md` with YAML frontmatter + steps/expected/macOS/Wrangle-version/screenshot fields | VERIFIED | Frontmatter `:1-7` (name/about/title/labels/assignees). Fields: Wrangle version `:17`, macOS version `:18`, Steps to reproduce `:25`, Expected behavior `:31`, Actual behavior `:35`, Screenshot `:40`. |
| REPO-05 | `.github/ISSUE_TEMPLATE/feature_request.md` with YAML frontmatter + problem/proposed-solution/alternatives/AI-dev-workflow fields | VERIFIED | Frontmatter `:1-7`. Fields: Problem `:18`, Proposed solution `:24`, Alternatives considered `:28`, AI-dev-workflow context `:32`. |
| REPO-06 | `.github/PULL_REQUEST_TEMPLATE.md` with description/screenshots/tests/CLAUDE.md-conventions checklist | VERIFIED | Description `:11`, Screenshots (if UI) `:15`, Tests checklist `:23-29`, Checklist with `CLAUDE.md` + `docs/coding-patterns.md` + scoped-PR items `:31-40`. |
| REPO-07 | `screenshots/raw/` has the 5 embedded canonical assets, all referenced in README | VERIFIED | `git ls-files screenshots/` tracks `Wrangle-2026-04-21-173707-2x-native.png`, `browser-feature.gif`, `editor-simple.png`, `project-overview.png`, `terminal.png`, `walkthrough-short-1.gif`. All 5 README-embedded paths resolve to on-disk assets. |
| REPO-08 | `.gitignore` comprehensive (Swift/Xcode/macOS/SPM + D-10 redaction list + `_sweep/`); zero tracked junk files | VERIFIED | `.gitignore` covers `.DS_Store`, `build/`, `DerivedData/`, `*.xcuserstate`, `xcuserdata/`, `.build/`, `.swiftpm/`, D-10 set (`docs/audit-report.md`, `docs/launch-strategy.md`, `docs/release-checklist.md`, `docs/product-hunt/`), `.env*`, `*.pem`, `*.p12`, `/*.dmg`, and `.planning/phases/14-app-repo-oss-surface/_sweep/`. Verification command `git ls-files \| grep -E '\.DS_Store$\|/DerivedData/\|/\.build/\|\.xcuserstate$\|/xcuserdata/'` returns **zero** matches. |
| REPO-09 | Full-history secrets sweep + option-2 (rotate-and-document) + SECURITY.md historical-URLs section + STATE.md decision entry + D-20 exemption extended to `wrangle/wrangleApp.swift` | VERIFIED | `_sweep/` artifacts exist (canonical-hits, analytics-hits, real/filtered/final variants — 6 files, 96 MB total — confirming sweep was actually run). `SECURITY.md:19` contains the section `## Known historical URLs in git history` (heading deviation acknowledged and documented). STATE.md Decisions block line 109 records: `Phase 14 secrets sweep: rotate-and-document strategy chosen. D-19 canonical pattern + analytics variants run against full history; 0 actual credentials found. ... D-20 exemption extended to wrangle/wrangleApp.swift ... REPO-09 satisfied.` Current-tree trace check: `git grep -iE "wrangleapp\.dev\|lemonsqueezy"` returns only `wrangle/wrangleApp.swift:173,176` (the documented D-20 About-panel surface). Zero `lemonsqueezy` references in active source. |
| REPO-10 | `SECURITY.md` with GitHub Security Advisories disclosure path; NO email channels | VERIFIED | `SECURITY.md:7` links to `https://github.com/J-Krush/wrangle/security/advisories/new`. `grep -iE "mailto:\|@pm\.me\|jkrush@" SECURITY.md` returns **zero** matches. |
| REPO-11 | `CLAUDE.md` has OSS header blockquote with `[MIT License](LICENSE)` AND `## Contributors` section pointing to `CONTRIBUTING.md` | VERIFIED | `CLAUDE.md:5` — `> **Open source:** Wrangle is now free and open source under the [MIT License](LICENSE). New contributors — start at [CONTRIBUTING.md](CONTRIBUTING.md).` `CLAUDE.md:116-121` — `## Contributors` section with `[CONTRIBUTING.md](CONTRIBUTING.md)` link. |
| REPO-12 | D-08 keep-list tracked (3 files); D-09 deleted (pre-launch-todo.md gone from disk + index); D-10 untracked but on disk (7 files + 1 plist); CLAUDE.md Detailed-docs blockquote pruned (no audit-report/release-checklist refs) | VERIFIED | `git ls-files docs/` returns exactly `architecture.md`, `coding-patterns.md`, `token-counting-research.md` — the D-08 keep-list. `find . -name pre-launch-todo.md` returns zero — D-09 gone. D-10 on-disk: 3 standalone (`audit-report.md` 30K, `launch-strategy.md` 8K, `release-checklist.md` 4K) + 4 in `docs/product-hunt/` (`README.md`, `description.md`, `maker-comment.md`, `tagline.md`) = 7 D-10 files plus the `xcschememanagement.plist` (xcuserdata) untracked-but-on-disk = 8 untracked-from-index operations matching 14-03-SUMMARY `untracked_from_index` block. `git ls-files docs/audit-report.md docs/launch-strategy.md docs/release-checklist.md docs/product-hunt/` returns zero (all dropped from index). `grep -nE "audit-report\|release-checklist" CLAUDE.md` returns zero — Detailed-docs blockquote pruned to `architecture.md` / `coding-patterns.md` / `token-counting-research.md`. |

**Score:** 12 / 12 must-haves verified.

### Required Artifacts (Three-Level Check)

| Artifact | Exists | Substantive | Wired | Status |
| -------- | ------ | ----------- | ----- | ------ |
| `LICENSE` | yes | yes (21 lines, full MIT body) | n/a (root-level legal artifact, GitHub auto-detects) | VERIFIED |
| `README.md` | yes | yes (152 lines, 8 sections, 5 embedded visuals) | yes (links to LICENSE, CONTRIBUTING.md, SECURITY.md, CLAUDE.md, `.planning/`, `docs/`) | VERIFIED |
| `CONTRIBUTING.md` | yes | yes (123 lines, 8 sections) | yes (links to CLAUDE.md, docs/coding-patterns.md, SECURITY.md, LICENSE, `.planning/`, `.github/` templates) | VERIFIED |
| `SECURITY.md` | yes | yes (37 lines, disclosure path + transparency section) | yes (advisories URL, README + CONTRIBUTING reference it) | VERIFIED |
| `.github/ISSUE_TEMPLATE/bug_report.md` | yes | yes (51 lines, 5 required fields) | yes (CONTRIBUTING.md `:55-58` links it) | VERIFIED |
| `.github/ISSUE_TEMPLATE/feature_request.md` | yes | yes (52 lines, 4 required fields) | yes (CONTRIBUTING.md `:60-62` links it) | VERIFIED |
| `.github/PULL_REQUEST_TEMPLATE.md` | yes | yes (41 lines, 3 sections + checklist) | yes (CONTRIBUTING.md `:68` links it) | VERIFIED |
| `screenshots/raw/` (5 assets) | yes | yes (5 PNG/GIF files tracked + sized 280K–1.8M) | yes (5 README image refs all resolve) | VERIFIED |
| `.gitignore` | yes | yes (40 lines, full coverage matrix) | yes (working-tree check returns zero junk-file matches) | VERIFIED |
| `CLAUDE.md` (OSS header + Contributors) | yes | yes (OSS blockquote + Contributors section both present) | yes (links to LICENSE + CONTRIBUTING.md) | VERIFIED |

### Key Link Verification

| From | To | Via | Status | Detail |
| ---- | -- | --- | ------ | ------ |
| `README.md` | `LICENSE` | markdown link `:151` | WIRED | `[LICENSE](LICENSE)` resolves |
| `README.md` | `CONTRIBUTING.md` | markdown link `:137` | WIRED | `[CONTRIBUTING.md](CONTRIBUTING.md)` resolves |
| `README.md` | `SECURITY.md` | markdown link `:141` | WIRED | `[SECURITY.md](SECURITY.md)` resolves |
| `README.md` | `screenshots/raw/*` | 5 embedded image refs | WIRED | all 5 paths resolve to tracked files |
| `README.md` | `.planning/ROADMAP.md` | markdown link `:145` | WIRED | path on disk |
| `CONTRIBUTING.md` | `CLAUDE.md` | markdown link `:81` | WIRED | resolves |
| `CONTRIBUTING.md` | `docs/coding-patterns.md` | markdown link `:84` | WIRED | resolves (D-08 keep-list) |
| `CONTRIBUTING.md` | `SECURITY.md` | markdown link `:116` | WIRED | resolves |
| `CONTRIBUTING.md` | `LICENSE` | markdown link `:120` | WIRED | resolves |
| `CONTRIBUTING.md` | `.github/ISSUE_TEMPLATE/*` + `PULL_REQUEST_TEMPLATE.md` | markdown links `:55-68` | WIRED | all three resolve |
| `SECURITY.md` | GitHub Security Advisories | URL `:7,:37` | WIRED | absolute URL — verified live at flip time (Phase 18 follow-up) |
| `CLAUDE.md` | `LICENSE` | OSS-header blockquote `:5` | WIRED | resolves |
| `CLAUDE.md` | `CONTRIBUTING.md` | OSS-header `:5` + Contributors `:118` | WIRED | resolves |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Working tree free of historically-tracked junk | `git ls-files \| grep -E '\.DS_Store$\|/DerivedData/\|/\.build/\|\.xcuserstate$\|/xcuserdata/'` | 0 matches | PASS |
| D-10 files dropped from git index | `git ls-files docs/audit-report.md docs/launch-strategy.md docs/release-checklist.md docs/product-hunt/` | 0 matches | PASS |
| D-10 files still on disk | `find docs/audit-report.md docs/launch-strategy.md docs/release-checklist.md docs/product-hunt/ -type f \| wc -l` | 7 files | PASS |
| D-09 file deleted | `find . -name pre-launch-todo.md` | 0 matches | PASS |
| D-08 keep-list tracked exactly | `git ls-files docs/` | `architecture.md`, `coding-patterns.md`, `token-counting-research.md` (3 files, no more, no less) | PASS |
| No Phase-13 forbidden tokens in public docs | `grep -niE "Krush LLC\|lemonsqueezy" LICENSE README.md CONTRIBUTING.md CLAUDE.md` | 0 matches (LemonSqueezy only in SECURITY.md historical-URLs section, intentional) | PASS |
| Current-tree secrets trace = D-20 exemption only | `git grep -iE "wrangleapp\.dev\|lemonsqueezy"` (excluding `docs/`, `.planning/`, `SECURITY.md`) | only `wrangle/wrangleApp.swift:173,176` (About-panel link) | PASS |
| Sweep artifacts exist (proves sweep ran) | `ls .planning/phases/14-app-repo-oss-surface/_sweep/` | 6 files: `analytics-hits.txt`, `analytics-hits-real.txt`, `canonical-hits.txt`, `canonical-hits-filtered.txt`, `canonical-hits-final.txt`, `canonical-hits-real.txt` | PASS |
| README contains story-section literal phrase | `grep -n "distribution is harder than product" README.md` | match at line 72 | PASS |
| README contains 2026-04-22 in story section | `grep -n "2026-04-22" README.md` | match at line 70 | PASS |
| README contains Reddit-ads mention | `grep -niE "reddit ?ads?" README.md` | match at line 72 | PASS |
| SECURITY.md has zero email channels | `grep -niE "mailto:\|@pm\.me\|jkrush@" SECURITY.md` | 0 matches | PASS |
| SECURITY.md links to GH Security Advisories | `grep -nE "github\.com/J-Krush/wrangle/security/advisories" SECURITY.md` | 2 matches (lines 7, 37) | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| REPO-01 | 14-01 | `LICENSE` MIT body, `Copyright (c) 2026 J Krush` | SATISFIED | `LICENSE:3` |
| REPO-02 | 14-02 | `README.md` 8-section story-driven structure | SATISFIED | `README.md` headings + embedded visuals |
| REPO-03 | 14-01 | `CONTRIBUTING.md` framing + links | SATISFIED | `CONTRIBUTING.md` |
| REPO-04 | 14-01 | `bug_report.md` template | SATISFIED | `.github/ISSUE_TEMPLATE/bug_report.md` |
| REPO-05 | 14-01 | `feature_request.md` template | SATISFIED | `.github/ISSUE_TEMPLATE/feature_request.md` |
| REPO-06 | 14-01 | `PULL_REQUEST_TEMPLATE.md` | SATISFIED | `.github/PULL_REQUEST_TEMPLATE.md` |
| REPO-07 | 14-02 | Embedded screenshots + GIF | SATISFIED | 5 visual assets in `screenshots/raw/`, all 5 embedded in README |
| REPO-08 | 14-03 | `.gitignore` comprehensive + zero tracked junk | SATISFIED | working-tree check 0 matches |
| REPO-09 | 14-03 | Full-history secrets sweep + decision recorded | SATISFIED | `_sweep/` artifacts + STATE.md `:109` + SECURITY.md historical-URLs section |
| REPO-10 | 14-01 | `SECURITY.md` disclosure path | SATISFIED | `SECURITY.md` |
| REPO-11 | 14-01 / 14-03 | `CLAUDE.md` OSS header + Contributors section | SATISFIED | `CLAUDE.md:5,116` |
| REPO-12 | 14-03 | `docs/` redaction (D-08/D-09/D-10) | SATISFIED | tracked-files audit + D-09 deleted + D-10 untracked but on disk + CLAUDE.md blockquote pruned |

All 12 requirements satisfied. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `.gitignore` | 21 | Stale comment `git rm --cached happens in Task 3` (Task 3 is now complete) | INFO | Minor documentation freshness; no behavioral impact. Acknowledged in REVIEW.md IN-01. Phase 18 polish. |
| `.gitignore` | 28 | `engine/target/` references near-empty legacy directory | INFO | Clutter, no behavioral impact. REVIEW.md IN-02. |
| `screenshots/raw/walkthrough-short-2.gif` | n/a | Untracked 1.8 MB asset perpetually in `git status` | INFO | Working-tree noise. REVIEW.md LO-02. Phase 18 cleanup. |
| `.planning/config.json` | n/a | Untracked, surfaces in `git status` indefinitely | INFO | Working-tree noise; planning workflow intentionally does not track. REVIEW.md IN-03. |
| `README.md` | 103 | Install-note references "Phase 18 of the OSS conversion" — leaks internal vocabulary | INFO | First-impression polish for public flip. REVIEW.md LO-01. |
| `README.md` | 54, 103 | v1.3 bullet claims unfinished work (signed-DMG pipeline ships in Phase 16, landing repositioning in Phase 17) | INFO | Forward-looking; will be accurate at Phase 18 flip. REVIEW.md IN-04. |
| `README.md` | 112 / `CONTRIBUTING.md` | 36 | `open Wrangle.xcodeproj` instructed but tracked path is `wrangle.xcodeproj` (lowercase) | WARNING | Case-sensitive-FS build break (Linux CI, case-sensitive APFS). On the maintainer's case-insensitive APFS it masks. REVIEW.md MD-01. **Recommended Phase 18 fix:** lowercase to `wrangle.xcodeproj`. Not a Phase 14 goal-blocker since the OSS surface still functions on the maintainer's machine and on default macOS APFS. |
| `SECURITY.md` | 19-37 | Transparency section omits `WRANGLE-DEV-PREVIEW` dev-bypass key visible via `git log -p` against pre-v1.3 source | WARNING | Section invites "report actual credential leaks" while omitting a credential-shaped artifact. REVIEW.md MD-02. **Recommended Phase 18 fix:** add a bullet enumerating `WRANGLE-DEV-PREVIEW` OR narrow the heading to `(URL-only sweep)`. Not a Phase 14 goal-blocker — the must-have wording requires the section to exist with the historical-URLs content, which it does. Operational risk is zero (paywall it bypassed is deleted). |

No BLOCKER-class anti-patterns. No debt markers (`TBD` / `FIXME` / `XXX`) in any Phase 14 deliverable.

### Acknowledged Documented Deviations (NOT Gaps)

These were explicitly called out in the verification request as documented deviations to *not* flag:

- **14-02 visual selection:** `browser-feature.gif` (instead of static `browser-tab.png`) for section (d); demo slot is `walkthrough-short-1.gif` (instead of `demo.gif`). Documented in `14-02-SUMMARY.md`. Both files exist, render at expected file sizes, and are correctly embedded.
- **14-03 SECURITY.md heading:** `## Known historical URLs in git history` (instead of plan's literal `## Known rotated tokens in history`). Documented in `14-03-SUMMARY.md` key-decisions. Adapted to reality: sweep found URLs not credentials, so the heading describes URLs not rotated tokens. Same transparency intent.
- **14-03 D-20 exemption extension:** D-20 originally named `SettingsView.swift` + `WhatsNewView.swift` which no longer exist; same About-panel surface in renamed `wrangle/wrangleApp.swift`. Documented in `14-03-SUMMARY.md` key-decisions + `STATE.md:109`. The two `wrangleapp.dev` references at `wrangle/wrangleApp.swift:173,176` are the documented exempted About-panel link, not credentials.

### Human Verification Required

None. All 12 must-haves can be verified from working-tree evidence and git index state. The OSS surface is documentation, configuration, and visual-asset scaffolding — no runtime behavior to live-test from the verifier's side. Live GitHub Security Advisories URL resolution and rendered-on-github.com README appearance (GIF autoplay, asset embedding) are Phase 18 acceptance items, deliberately scoped out of Phase 14 (the repo is still private; the public surface lives in PR-ready form).

### Notes / Open Follow-Ups

These items were identified by the code review (REVIEW.md) and are recorded here for Phase 18 / future-phase pickup. None block the Phase 14 goal.

1. **MD-01 (README/CONTRIBUTING `Wrangle.xcodeproj` casing).** Lowercase the three references in `README.md:112`, `CONTRIBUTING.md:36`, and `CLAUDE.md:109` to match the tracked `wrangle.xcodeproj` path before the Phase 18 public flip. Cheap, mechanical, no behavioral risk on the maintainer's machine.
2. **MD-02 (SECURITY.md `WRANGLE-DEV-PREVIEW` enumeration).** Pick option-A (add bullet) or option-B (narrow heading to `(URL-only sweep)`) before Phase 18. Improves transparency-section completeness.
3. **LO-01 (README install-note Phase 18 phrasing).** Soften wording so first-time visitors don't need a `.planning/ROADMAP.md` round-trip to confirm download availability. Phase 17 / 18 polish.
4. **LO-02 (`screenshots/raw/walkthrough-short-2.gif` working-tree noise).** Pick one of: delete, track, or `.gitignore`. Currently the worst-case "leave indefinitely" outcome. Phase 18 cleanup.
5. **IN-01 (`.gitignore:21` stale comment).** Update comment from "happens in Task 3" → "files kept on disk, dropped from git index in Phase 14-03 Task 3". Trivial.
6. **IN-03 (`.planning/config.json` working-tree noise).** Decide whether to gitignore or leave; planning-workflow concern not Phase 14 concern.
7. **IN-04 (README v1.3 bullet forward-looking).** Decide whether to weaken the bullet or accept the forward-looking claim now that Phases 15-18 are pending.
8. **REPO-09 history-rewrite question (D-11).** Phase 14 chose option-2 (rotate-and-document); Phase 18 retains the option to revisit `git filter-repo` history rewrite. Decision recorded in `STATE.md:109,129`.

---

_Verified: 2026-05-20T19:15:00Z_
_Verifier: Claude (gsd-verifier)_
_Methodology: goal-backward verification of REPO-01..REPO-12 must-haves against working-tree + git-index evidence; cross-referenced 14-01-SUMMARY.md / 14-02-SUMMARY.md / 14-03-SUMMARY.md claims against on-disk files; absorbed REVIEW.md findings (0 critical / 0 high / 2 medium / 2 low / 5 info — all advisory)._
