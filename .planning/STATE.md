---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Open Source Release
status: executing
stopped_at: Phase 13 executed (awaiting manual smoke + verify-phase)
last_updated: "2026-05-19T17:24:00Z"
last_activity: 2026-05-19 -- Phase 13 Wave 1 + Wave 2 executed; 7 commits, build green
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 17
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-19)

**Core value:** Every surface — editor, terminal, file tree, browser — serves a developer driving AI agents. Speed, density, and AI-file awareness win over breadth of consumer features.
**Current focus:** v1.3 roadmap defined — Phase 13 (App De-Commercialization) is next.

## Current Position

Phase: 13 executed (App De-Commercialization) — awaiting manual GUI smoke + `/gsd:verify-phase 13`
Plan: 13-02 complete
Status: Functionally complete; user verification + test-target gap pending
Last activity: 2026-05-19 -- Phase 13 Wave 1 + Wave 2 executed; 7 commits, build green

**Progress:** `[==        ] 1/6 phases (17%)`

### Phase 13 Outstanding

- **Manual GUI smoke** (Plan 02 Task 4, steps 3–8) — autonomous environment cannot drive AppKit. Need user to: launch fresh build → confirm WhatsNew v1.3.0 modal appears with "Star on GitHub" CTA → click CTA opens GitHub in default browser → modal stays open until Continue → relaunch does NOT re-show modal → About panel renders both `wrangleapp.dev` and `github.com/J-Krush/wrangle` links → Scratch Pad + Browser tab still work.
- **No Xcode test target** — Plan 02 shipped `WhatsNewManagerTests.swift` (4 tests) + `LicenseResidueCleanupTests.swift` (4 tests) but `Wrangle.xcodeproj` has only the `Wrangle` app target. `xcodebuild test` cannot run. Per user's `feedback_testing_priority` memory, recommend a follow-up plan (Phase 13.5 or carry-over) to wire up a unit-test target before v1.3 milestone closes.
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
- **Repo history secrets** — Phase 14 and Phase 15 audits may turn up committed secrets in old history (LemonSqueezy / wrangleapp.dev tokens, analytics keys). If found, the choice is `git filter-repo` history rewrite (clean, but rewrites tags) vs. rotate-and-document. Decision deferred to phase execution; see FLIP-01 / REPO-09 / LAND-05.
- **Landing-page deploy reversibility (SITE-09)** — production target is whatever currently serves `wrangleapp.dev`. Need to confirm the host (Vercel / Netlify / static) supports instant rollback before pushing the OSS-positioned build.
- **Multi-window NSEvent monitors** (v1.2 carry-over) — process-scoped, filtered by session ID. Not scoped into v1.3.

## Session Continuity

Last session: 2026-05-19T13:31:09.775Z
Stopped at: Phase 13 context gathered
Resume file: .planning/phases/13-app-de-commercialization/13-CONTEXT.md
