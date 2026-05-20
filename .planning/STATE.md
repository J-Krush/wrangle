---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Open Source Release
status: executing
stopped_at: Phase 13 shipped to origin/main (private remote) — no PR per "flip public at milestone end" plan; manual GUI smoke + verify-phase still pending
last_updated: "2026-05-20T18:58:00Z"
last_activity: 2026-05-20 -- Phase 13 pushed to origin/main (28 commits, c1c4c95)
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 17
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-19)

**Core value:** Every surface — editor, terminal, file tree, browser — serves a developer driving AI agents. Speed, density, and AI-file awareness win over breadth of consumer features.
**Current focus:** v1.3 roadmap defined — Phase 13 (App De-Commercialization) is next.

## Current Position

Phase: 13 executed + shipped (App De-Commercialization) — pushed to origin/main (private), no PR
Plan: 13-03 complete (WrangleTests target wired up)
Status: All plans complete; test infrastructure operational (106 tests green); manual GUI smoke confirmed by user 2026-05-20; verify-phase still optional before next phase
Last activity: 2026-05-20 -- Phase 13 pushed to origin/main (28 commits, c1c4c95)

**Progress:** `[==        ] 1/6 phases (17%)`

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
