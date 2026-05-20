---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Open Source Release
status: completed
stopped_at: Phase 15 Plan 01 complete; Plan 02 ready to execute
last_updated: "2026-05-20T22:12:59.280Z"
last_activity: 2026-05-20 -- Phase 15 marked complete
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 8
  completed_plans: 7
  percent: 33
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-19)

**Core value:** Every surface — editor, terminal, file tree, browser — serves a developer driving AI agents. Speed, density, and AI-file awareness win over breadth of consumer features.
**Current focus:** Phase 15 — landing-repo-oss-surface

## Current Position

Phase: 15 — COMPLETE
Plan: 2 of 2 — complete
Status: Phase 15 complete
Last activity: 2026-05-20 -- Phase 15 marked complete

**Progress:** [█████████░] 88%

### Phase 13 Outstanding

- **Manual GUI smoke** (Plan 02 Task 4, steps 3–8) — ✓ confirmed by user 2026-05-20. WhatsNew v1.3.0 modal, Star on GitHub CTA, About panel dual links, dismiss + non-recurrence, Scratch Pad + Browser tab all verified.
- **Xcode test target wired up (Plan 13-03 complete, 2026-05-20)** — `WrangleTests` target added via Xcode 26 `PBXFileSystemSynchronizedRootGroup` (folder-synced membership, no per-file pbxproj entries). Shared scheme `Wrangle.xcscheme` committed. All 7 test files green: 106 test cases across `EditorDocumentTests` (14), `FileTypeTests` (37), `LicenseResidueCleanupTests` (4), `LinkRouterTests` (10), `MarkdownParserTests` (20), `TokenCounterTests` (17), `WhatsNewManagerTests` (4). Two trivial in-scope fixes: `import SwiftUI` in `TokenCounterTests`, off-by-one assertion (`33→34`) in `EditorDocumentTests.cachedStats`. No RED-defer remaining.
- **APP-13 exemption list** finalized in `13-02-SUMMARY.md` — `wrangleapp.dev` (2 hits = 1 logical About-panel surface per D-12), `trial`/`License`/`license` substrings inside `LicenseResidueCleanup.swift` (deletion-target constants, structurally exempt), `license` in `FileTreeNode.swift:49` (repo-metadata matcher, exempt).

## Performance Metrics

**Velocity (v1.2):**

- Total plans completed: 13 across 12 phases (one phase ran two plans on the polish pass)
- Build verification: passed after every phase

**By Phase (v1.2 history retained for context):**

| Phase | Core artifacts |
|-------|----------------|
| 1. Restore Entry Points | 4 edits (SidebarView, TitleBarTabStrip, BookmarkListView, wrangleApp) |
| 2. Core Hardening | 5 files (FaviconCache, NewTabPage, BrowserFindBar + 2 edits) |
| 3. Dev Tools Shortcuts | 2 edits (BrowserTabContentView key handler, ElementInspectorView notifier) |
| 4. Browser Chrome & Security | 7 files (PadlockView, BrowserUserAgent + BrowserTab/WebView/Toolbar/TabBar/Settings edits) |
| 5. Bookmark Foundations | 9 files (BrowserBookmark/Folder @Models, BookmarkStore, StarButton, BookmarkSidebarSection, BookmarkEditSheet + 3 edits) |
| 6. Bookmark Import | 8 files (5 importer files + 3 edits: AppState, wrangleApp, ContentView) |
| 7. Browsing History | 11 files (BrowsingHistoryEntry @Model, HistoryStore, HistoryView, URLSuggestionPopover + 7 edits) |
| 8. Downloads | 6 files (BrowserDownloadRecord @Model, DownloadManager, DownloadsPopover + 3 edits) |
| 9. Private / Incognito Mode | 5 files (AppState, BrowserSession, BrowserWebView, BrowserToolbar, wrangleApp) |
| 10-01. Unified Creation Pattern (1/2) | 5 files (UnifiedAddMenu created + NewBookmarkSheet, SidebarView, TitleBarTabStrip, ProjectOverviewView edits) — 3 task commits, build green |
| 10-02. Per-Section Chrome Removal (2/2) | 4 files edited (SidebarView, ProjectOverviewView, BookmarkSidebarSection, SidebarSectionHeader) — 4 task commits, build green; ~3min |
| 11-01. Sidebar Hide-When-Empty + Nested Bookmarks (1/2) | 2 files (BookmarkSidebarSection renamed → NestedBookmarkSubSection + SidebarView edited) — 2 task commits, build green; ~4min |
| 11-02. Overview Hide-When-Empty + Empty-Hero + Nested Bookmarks Card (2/2) | 1 file (ProjectOverviewView edited) — 2 task commits, build green; ~3m34s |
| 12-01. Section Parity & Polish | static-sidebar pivot mid-phase; SidebarStorageKeys.swift created then reverted; build green |

**v1.3 plans (TBD):**

| Phase | Expected Plans |
|-------|----------------|
| 13. App De-Commercialization | 2 (file/plumbing strip; "free + OSS" note) |
| 14. App Repo OSS Surface | 3 (LICENSE+templates; README+media; secrets/`.gitignore`/docs audit) |
| 15. Landing Repo OSS Surface | 2 (LICENSE+README; secrets sweep+`.gitignore`) |
| 16. Signed-DMG Release Pipeline | 2 (build/sign/notarize/staple; DMG+Release draft) |
| 17. Landing Page Repositioning | 3 (hero+nav+pricing; story+SEO; download wiring+deploy) |
| 18. Public Flip + v1.3.0 Release | 1 (final sweep + flip + publish) |
| **Total** | **13** |

**v1.3 actual execution:**

| Phase / Plan | Duration | Tasks | Files / Commits | Notes |
|--------------|----------|-------|-----------------|-------|
| Phase 13 (App De-Commercialization) | — | — | — | Closed 2026-05-19 / 2026-05-20 |
| Phase 14 (App Repo OSS Surface) | — | — | — | Planned 2026-05-20 (00-CONTEXT.md + 01..03-PLAN.md drafted) |
| Phase 15 Plan 01 (Landing repo deletions + audit) | ~30min | 3 | 9 modified + 11 deleted + 6 untracked + audit (planning host) | 6 atomic Landing Page commits (e002769..f4a8402) + 1 planning-host SUMMARY commit (c2c867c). D-09 stands; zero category-(d) secret values. |
| Phase 15 Plan 02 (LICENSE + README + clean-checkout verify) | ~2min | 3 | 1 created (LICENSE) + 1 modified (README) + 3 SUMMARY/audit files (planning host) | 2 atomic Landing Page commits (418bd25 LICENSE, a4c6506 README) + 1 planning-host commit (f7d17c6 SUMMARY+audit+per-plan-02). D-12 clean-checkout PASSED: /tmp clone booted pnpm dev on http://localhost:4321/ in 715ms. All 5 LAND-IDs closed; all 16 D-XX decisions implemented; D-09 stands. |

## Accumulated Context

### Decisions (v1.3, locked at planning)

- **MIT license** picked deliberately (not BSL / AGPL / non-commercial). Recognizable, zero friction; niche audience makes the "fork-and-commercialize" risk negligible. Goal is signal, not protection.
- **Strip the commercial surface wholesale** — no conditional/feature-flag retention of `LicenseManager` etc. Carrying dead code through a portfolio-piece release is worse than the (tiny) loss of "ability to re-monetize." (See PROJECT.md Key Decisions.)
- **Both repos flip public at milestone end, not earlier.** Lower stakes if something needs to be yanked; cleaner narrative; lets README + LICENSE + CONTRIBUTING land before the world sees the repo.
- **Local-build signed DMG, no GitHub Actions automation this milestone.** GH Actions notarization is ~1 day of work and not on the critical path. Deferred to v1.4.
- **"Star on GitHub" replaces the paywall CTA** — no GitHub Sponsors / Buy Me a Coffee in v1.3. Honest signal for a portfolio piece, less to maintain.
- **No migration path for paid v1.2 users.** License-key flow is being torn out wholesale; any v1.2 license-holder simply opens v1.3 to the editor.
- **One-time "free + open source" note** uses the existing `WhatsNewView` mechanism if compatible; otherwise a one-off sheet keyed off the v1.3 version bump (APP-11). Dismissable, does not re-appear, does not block the editor.
- **Critical-path ordering: 13 → 16 → 17 → 18**, with 14 and 15 parallel-eligible. Phase 17's "Download for macOS" CTA literally needs the URL produced in Phase 16.

### Decisions (v1.3, validated during execution)

- **Phase 15 Plan 01 — D-09 stands** (2026-05-20). Full D-11 audit (working tree + 23-commit history) found zero category-(d) actual secret values. No `git filter-repo`, no `git push --force`. Phase 18 cleared to flip `wrangle-landing` public from a credential-exposure standpoint. Audit working artifact at `.planning/phases/15-landing-repo-oss-surface/15-01-AUDIT.md` (uncommitted in Plan 01 per D-10; Plan 02 commits it together with the phase SUMMARY).
- **Phase 15 Plan 01 — Plan-internal acceptance conflict acknowledged** (2026-05-20). Task 3's `<acceptance_criteria>` zero-LemonSqueezy assertion contradicted the plan's own `astro.config.mjs` "do not touch" scope boundary. Invoked the audit's catalogue-every-hit escape valve: `astro.config.mjs:17` (public `/buy` checkout URL) catalogued as category-(b); Phase 17 SITE-05 owns the redirect rewrite.
- **Phase 15 Plan 02 complete — D-12 clean-checkout verified, D-09 stands** (2026-05-20). LICENSE added (canonical SPDX MIT, `Copyright (c) 2026 J Krush` exact) + README rewritten to D-14 4-section public-facing structure (pnpm command table preserved verbatim; 2x github.com/J-Krush/wrangle link-backs per D-15; RESEND_API_KEY dev-warning documented per D-12; @astrojs/vercel deploy adapter named; License footer per D-16). D-12 clean-checkout verification PASSED: /tmp clone with no .env booted `pnpm dev` on http://localhost:4321/ (Astro v5.18.0 ready in 715ms). Pre-flight audit gate passed; D-09 stands. All 5 LAND-IDs closed; all 16 D-XX decisions implemented. Landing Page commits: `418bd25` (LICENSE), `a4c6506` (README). Planning-host commit: `f7d17c6` (SUMMARY + audit + per-plan-02 SUMMARY).
- **macOS `timeout`-substitute pattern documented** (2026-05-20, Phase 15 Plan 02). The orchestrator's `<clean_checkout_handling>` recipe assumes GNU coreutils `timeout`. On macOS the binary is not on PATH; substitute with `(pnpm dev > log 2>&1 & echo $! > pid) ; sleep 12 ; kill $(cat pid)`. Captured boot line via post-hoc log grep. Reusable for any future plan whose verification assumes coreutils.

### Decisions (shipped, v1.2 — retained for context)

- Browser was reactivated via uncommenting + additive edits; no core Browser/ files needed rewriting.
- Bookmark import is one-way + re-runnable; Safari requires Full Disk Access (user-chosen direct plist path).
- SwiftData schema bumped 2→3 with four new @Models. Migration is additive/lightweight.
- Phase 12 sidebar pivot to static headers (no chevron / no expansion state) superseded the originally-specified collapsible UIX-20 contract. `SidebarStorageKeys.swift` constants got created then removed because there was no expansion state left to centralize.

### Pending Todos

- Manual UAT per Phase 13 success criteria (smoke-test editor opens with no gate, grep for forbidden strings, verify "free + OSS" note appears once and dismisses).
- Capture the 3+ README screenshots + animated demo GIF in Phase 14 (editor with rendered markdown, browser tab, project overview).
- Confirm the local Developer ID Application certificate is in Keychain and the app-specific password for `notarytool` is ready before kicking off Phase 16.
- Decide between deleting `/pricing` outright vs. rewriting it during Phase 17 — affects whether SITE-10's `404.astro` fallback is needed.

### Blockers/Concerns

- **Apple notarization credentials** — Phase 16 requires a valid Developer ID Application certificate + an app-specific password tied to the Apple ID + the Team ID. If any of these are missing or expired, Phase 16 stalls on Apple-side bureaucracy, not code.
- **Repo history secrets** — Phase 14 and Phase 15 audits may turn up committed secrets in old history (LemonSqueezy / wrangleapp.dev tokens, analytics keys). If found, the choice is `git filter-repo` history rewrite (clean, but rewrites tags) vs. rotate-and-document. Decision deferred to phase execution; see FLIP-01 / REPO-09 / LAND-05. **LAND-05 FULLY RESOLVED (2026-05-20, Phase 15 close):** Phase 15 Plans 01+02 both complete; D-11 audit found zero category-(d) actual secret values in `wrangle-landing`'s working tree OR 23-commit history. D-09 stands; no rewrite needed for the landing repo. **Phase 14 audit still pending for the app repo** (REPO-09).
- **Landing-page deploy reversibility (SITE-09)** — production target is whatever currently serves `wrangleapp.dev`. Need to confirm the host (Vercel / Netlify / static) supports instant rollback before pushing the OSS-positioned build.
- **Multi-window NSEvent monitors** (v1.2 carry-over) — process-scoped, filtered by session ID. Not scoped into v1.3.

## Session Continuity

Last session: 2026-05-20T22:03:36.373Z
Stopped at: Phase 15 Plan 01 complete; Plan 02 ready to execute
Resume file: None
