---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Browser Support
status: executing
stopped_at: Phase 11 complete (both plans shipped); ready for Phase 12
last_updated: "2026-04-20T03:33:32Z"
last_activity: 2026-04-20 -- Phase 11 Plan 11-02 complete (overview hide-when-empty + empty-hero + nested Bookmarks card)
progress:
  total_phases: 12
  completed_phases: 2
  total_plans: 4
  completed_plans: 4
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-19)

**Core value:** Every surface — editor, terminal, file tree, browser — serves a developer driving AI agents. Speed, density, and AI-file awareness win over breadth of consumer features.
**Current focus:** Phase 11 — Hide-When-Empty + Bookmarks Nested Under Browsers

## Current Position

Phase: 11 (Hide-When-Empty + Bookmarks Nested Under Browsers) — COMPLETE
Plan: 2 of 2 (11-01 complete; 11-02 complete)
Status: Ready for Phase 12 (Section Parity & Polish)
Last activity: 2026-04-20 -- Phase 11 Plan 11-02 complete (overview hide-when-empty + empty-hero + nested Bookmarks card)

Progress: [██████████] 100% of Phase 11 plans shipped; build passing

## Performance Metrics

**Velocity:**

- Total plans completed: 9 (one plan per phase, executed as a single session)
- Build verification: passes after every phase

**By Phase:**

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

## Accumulated Context

### Decisions (shipped this milestone)

- Browser was reactivated via uncommenting + additive edits; no core Browser/ files needed rewriting.
- Bookmark import is one-way + re-runnable; Safari requires Full Disk Access (user-chosen direct plist path).
- SwiftData schema bumped 2→3 with four new @Models (BrowserBookmark, BrowserBookmarkFolder, BrowsingHistoryEntry, BrowserDownloadRecord). Migration is additive/lightweight.
- Keyboard shortcuts installed via NSEvent local monitor inside BrowserTabContentView, gated by `isActive`. Private mode plumbed via `isPrivate` on BrowserSession, used for WKWebsiteDataStore.nonPersistent() + history suppression.
- Find-in-page uses WKWebView.find(_:configuration:) (no native macOS find bar API — built in `BrowserFindBar.swift`).
- Dev tools shortcuts (Cmd+Opt+I/J/C) toggle the in-app DevToolsPanel; right-click Inspect Element uses WebKit's default menu which routes to Safari Web Inspector (`isInspectable=true` already on).
- **Plan 10-01 (UnifiedAddMenu):** single shared SwiftUI view renders the 11-item `+` menu across sidebar / tab strip / Project Overview; per-instance @State chosen over AppState centralization to avoid cross-presenter collisions. `addLocation()` inlined verbatim (not `appState.pendingLocationAdd` — that shortcut silently no-ops at top level). `NewBookmarkSheet` extended with optional URL/Title prefill so Bookmark… pre-fills from the focused browser tab.
- **Plan 10-02 (per-section chrome removal):** stripped per-section add controls — Locations sidebar `...`, Bookmarks sidebar `...`, Project Overview Bookmarks `Import…` and Locations `+`. `SidebarSectionHeader` simplified (preferred path): generic `Accessory: View` parameter + `@ViewBuilder accessory` closure dropped entirely. All four call sites (Scratch Pads, Locations, Browsers, Other Sessions) compile against the simplified signature. `BookmarkSidebarSection` keeps its bespoke header (count badge is bookmark-specific); Phase 12 may unify. `addLocation()` helpers in both `SidebarView` and `ProjectOverviewView` retained — the former has a surviving empty-state caller, the latter is kept for Phase 11's empty-state hero. `New Folder…` path has no UI affordance post-Phase-10 — accepted gap; users can assign existing folder via `BookmarkEditSheet`.
- **Plan 11-01 (sidebar hide-when-empty + nested bookmarks):** Renamed `BookmarkSidebarSection.swift` → `NestedBookmarkSubSection.swift` via `git mv` (89% similarity; blame preserved for the four helper structs). Dropped the top-level `Section { } header: { }` wrapper — the new struct is a sibling inside `BrowserSessionsSection`'s existing Section. New `@AppStorage("sidebar.browsers.bookmarks.expanded")` key (default true), independent from `sidebar.browsers.expanded` (D-05). Outer `BrowserSessionsSection` guard widened to `!browsers.isEmpty || !visibleBookmarks.isEmpty` via a duplicated `@Query<BrowserBookmark>` at that scope — accepted trade-off (T-11-03) vs. prop-drilling or AppState hoisting. `SidebarView` gains `private var projectLocations` computed property mirroring `ProjectOverviewView.projectBookmarks`; Locations Section wrapped in `if !projectLocations.isEmpty`. No `withAnimation` wraps section show/hide — instant swap per D-22 / user memory `feedback_no_slide_transitions`. Xcode 16 `fileSystemSynchronizedRootGroup` meant no `pbxproj` edits were required (plan's Task 1 action step 3 skipped as non-applicable — documented as Rule 3 deviation). Build green; UIX-10/11/12/13 satisfied.
- **Plan 11-02 (overview hide-when-empty + empty-hero + nested bookmarks card):** Deleted standalone `bookmarksSection` + `bookmarksContent` from `ProjectOverviewView`; migrated the populated bookmarks `LazyVGrid` verbatim into `browsersSection` as a nested `CollapsibleVStackSection("Bookmarks", …)` — one card, two chevrons (UIX-15). New inner `@AppStorage("overview.browsers.bookmarks.expanded.\(projectID)")` key (D-21), independent from the outer `overview.browsers.expanded.\(projectID)`. Broadened body guard for browsers to `if !browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty { browsersSection }` (D-20). Added `isProjectContentEmpty` computed property (D-12 compound boolean, Todos excluded) and a centered `emptyHero` view — `square.grid.2x2` at 48pt + headline "Nothing here yet" + verbatim D-14 subheadline — rendered below `todosSection` when the compound boolean fires. No `+` button in hero (Phase 10 invariant). `locationsSection` collapsed to grid-only; body wraps it in `if !projectBookmarks.isEmpty { locationsSection }`. Inline "No bookmarks yet…" and "No locations added yet…" rows deleted entirely (D-15). Zero `withAnimation`/`.transition` on show/hide (D-22). One cosmetic deviation (Rule 3 — explanatory comment rewritten to avoid the forbidden literal "No locations added yet" string). Orphan `@AppStorage` key `overview.bookmarks.expanded.{projectID}` left for Phase 12 UIX-22 audit. Build green; UIX-14/15 satisfied. **Phase 11 complete.**

### Pending Todos

- Manual UAT per requirement checklist in REQUIREMENTS.md / ROADMAP.md.
- Optional: add download location picker in Preferences → Browser (currently hardcoded to ~/Downloads with override via `browser.defaultDownloadsDirectory` UserDefault).
- Optional: convert Safari import to also accept HTML exports (user chose direct-read-only, so skipped).
- Optional: wire right-click "Inspect Element" directly to our in-app element picker (currently routes to Safari Web Inspector via WebKit's default context menu).

### Blockers/Concerns

- **Keyboard shortcut scoping (BH-04)** — Cmd+[/] still works globally for workspace tab nav; inside a focused browser tab the NSEvent monitor hijacks them for browser history navigation. Requires manual smoke test to confirm no cross-feature regression.
- **Multi-window handling** — NSEvent local monitors are process-scoped. If two windows both have a browser tab active, both monitors fire. Filtered by session ID comparison, which is unique across windows, so behavior is correct but fires more monitors than necessary.
- **SwiftData schema version** — bump 2→3 wipes the store on first launch of v1.2 (existing behavior of `wrangleSchemaVersion` check). Users will lose previously-stored data (bookmarks, recent files, projects, intents, todos). This is the project's established migration strategy — pre-existing and outside this milestone's scope.

## Session Continuity

Last session: 2026-04-20T03:33:32Z
Stopped at: Phase 11 complete (both plans shipped); ready for Phase 12 (Section Parity & Polish)
Resume file: None — Phase 12 planning to be initiated next session
