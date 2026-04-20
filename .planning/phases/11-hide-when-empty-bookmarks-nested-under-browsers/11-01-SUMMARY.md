---
phase: 11-hide-when-empty-bookmarks-nested-under-browsers
plan: 01
subsystem: ui
tags: [swiftui, sidebar, swiftdata, appstorage, macos]

requires:
  - phase: 10-unified-creation-pattern
    provides: Unified +-menu surface; SidebarSectionHeader simplified to nav-only; per-section chrome already stripped
provides:
  - Sidebar Locations section hides when the active project has 0 locations (UIX-12 / D-01)
  - Sidebar Browsers section hides only when there are 0 tabs AND 0 visible bookmarks (UIX-11 / D-07)
  - Top-level BookmarkSidebarSection removed — bookmarks now render as a nested sub-section inside Browsers (UIX-13 / D-02/D-03)
  - NestedBookmarkSubSection with inline chevron sub-header that shows "Bookmarks" expanded and "Bookmarks (N)" collapsed (D-04)
  - New @AppStorage key sidebar.browsers.bookmarks.expanded — independent from sidebar.browsers.expanded (D-05)
  - Delete-last-item causes instant section disappearance with no animated transition (D-22, user memory feedback_no_slide_transitions)
affects: [phase-11-02 overview, phase-12 section-parity]

tech-stack:
  added: []
  patterns:
    - Hide-when-empty section guard via in-view @Query filter (matches existing ProjectOverviewView.projectBookmarks pattern)
    - Nested sub-section inside parent Section via helper View (self-hides on empty) — sidesteps Section-in-Section grouping issues
    - Duplicate @Query<BrowserBookmark> across parent + child view for outer-guard bookmark presence test (accepted trade-off, T-11-03)

key-files:
  created:
    - wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift
  modified:
    - wrangle/Sidebar/SidebarView.swift
  deleted:
    - wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift (renamed via git mv → NestedBookmarkSubSection.swift)

key-decisions:
  - "Renamed BookmarkSidebarSection.swift → NestedBookmarkSubSection.swift via git mv (preserves blame for BookmarkFolderNode, BookmarkFolderDropDelegate, BookmarkRow, DeleteKeyHandler helpers)"
  - "No pbxproj edits required — Xcode project uses fileSystemSynchronizedRootGroup, so files auto-compile based on filesystem presence (deviation from plan's Task 1 action step 3)"
  - "Sheet presentation wrapped around the whole sub-section body via Group{}.sheet(item:) so BookmarkEditSheet stays mounted whenever the sub-section renders; avoids attaching sheet to a conditionally-rendered Button"
  - "BrowserSessionsSection duplicates @Query<BrowserBookmark> with NestedBookmarkSubSection so the outer Browsers Section guard (D-07) can test bookmark presence without prop-drilling or AppState hoisting — documented in threat register T-11-03"

patterns-established:
  - "Pattern: nested sub-section inside parent Section — child view self-hides when its query is empty; parent passes the child as a plain sibling inside its Section { } body (not Section-in-Section)"
  - "Pattern: count-only-when-collapsed sub-header — inline HStack(Button{...}) rather than SidebarSectionHeader variant (Phase 12 decides canonicalization)"

requirements-completed: [UIX-10, UIX-11, UIX-12, UIX-13]

duration: 4min 20s
completed: 2026-04-20
---

# Phase 11 Plan 01: Sidebar Hide-When-Empty + Nested Bookmarks Summary

**Locations now hides when empty; top-level Bookmarks folded into Browsers as a nested collapsible sub-section with count-only-when-collapsed sub-header.**

## Performance

- **Duration:** 4 min 20 s
- **Started:** 2026-04-20T03:20:59Z
- **Completed:** 2026-04-20T03:25:19Z
- **Tasks:** 3 (two with file edits, one build verification)
- **Files modified:** 2 (1 rename+rewrite, 1 edit)

## Accomplishments

- `BookmarkSidebarSection.swift` renamed (via `git mv`) to `NestedBookmarkSubSection.swift` and rewritten — the top-level `Section { } header: { }` wrapper is gone; the new struct is a sibling View that renders inside `BrowserSessionsSection`'s Section body.
- `NestedBookmarkSubSection` self-hides when `visibleBookmarks.isEmpty` (D-02/D-09/UIX-13). Its sub-header shows chevron + "Bookmarks" when expanded, chevron + "Bookmarks (N)" when collapsed (D-04).
- New `@AppStorage("sidebar.browsers.bookmarks.expanded")` key (default true), independent from the outer `sidebar.browsers.expanded` key (D-05).
- `BookmarkFolderNode`, `BookmarkFolderDropDelegate`, `BookmarkRow`, `DeleteKeyHandler` preserved verbatim inside the renamed file — zero behavior change; `.sheet(item: $editing) { BookmarkEditSheet(bookmark:) }` continues to present the edit sheet.
- `SidebarView.body`: Locations Section wrapped in `if !projectLocations.isEmpty { Section { … } }` via a new in-view computed property `projectLocations` (mirrors `ProjectOverviewView.projectBookmarks`).
- `SidebarView.body`: top-level `BookmarkSidebarSection()` call removed.
- `BrowserSessionsSection` body: outer guard widened to `!browsers.isEmpty || !visibleBookmarks.isEmpty` (D-07); body renders `ForEach(browsers) { LocationBrowserRow(...) }` followed by `NestedBookmarkSubSection()` inside the existing `isExpanded` guard (D-03/D-10). A second `@Query<BrowserBookmark>` + matching `visibleBookmarks` filter is added at `BrowserSessionsSection` scope for the outer-guard test.
- `xcodebuild -scheme Wrangle -destination 'platform=macOS,arch=arm64' -configuration Debug build` → **BUILD SUCCEEDED**.

## Task Commits

1. **Task 1: Rename + repurpose BookmarkSidebarSection.swift → NestedBookmarkSubSection.swift** — `2f0a6e6` (refactor)
2. **Task 2: Wire SidebarView — Locations hide-when-empty, delete top-level call, extend BrowserSessionsSection** — `fab8568` (refactor)
3. **Task 3: xcodebuild verification** — no commit (no file edits; verification-only task)

## Files Created/Modified

- `wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift` (created via `git mv` from `BookmarkSidebarSection.swift`) — sub-section view, owns `@Query<BrowserBookmark>` and `@Query<BrowserBookmarkFolder>`, renders inline chevron sub-header + unfiled bookmarks + top-level folders when non-empty.
- `wrangle/Sidebar/SidebarView.swift` — Locations wrapped in `if !projectLocations.isEmpty`, top-level `BookmarkSidebarSection()` call removed, `BrowserSessionsSection` extended to own a parallel `@Query<BrowserBookmark>` and render `NestedBookmarkSubSection()` after the browser-rows `ForEach` inside its `isExpanded` block.

## Decisions Made

- **File rename approach:** Used `git mv wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift`. Git preserves the rename relationship at 89% similarity, so `git blame` follows the four preserved helper structs through the rename. Case-insensitive macOS filesystem aliased `Wrangle/` and `wrangle/` paths — git tracks the lowercase form, and the command worked as expected once invoked with the correct case.
- **Sheet attachment:** Attached `.sheet(item: $editing) { BookmarkEditSheet(bookmark: $0) }` to the outer `Group { … }` wrapping the conditional body so the sheet is available whenever the sub-section is rendered. Attaching to the `Button` (the sub-header row) would have been equivalent, but attaching to the `Group` is clearer about lifetime — the sheet lives with the sub-section, not with its header row.
- **Outer-guard bookmark presence:** Duplicated the `@Query<BrowserBookmark>` + `visibleBookmarks` filter at `BrowserSessionsSection` scope rather than prop-drilling or hoisting state to AppState. Threat register T-11-03 accepts this: SwiftData `@Query` is cheap/memoized, and the alternatives couple two views or violate the view-layer-only scope of Phase 11.
- **No pbxproj edits:** Xcode project uses `fileSystemSynchronizedRootGroup` (introduced in Xcode 16); files auto-compile based on filesystem presence. Plan Task 1 Action step 3 described editing `PBXFileReference` / `PBXBuildFile` entries that do not exist in this project. Skipped the step; verified with `grep BookmarkSidebarSection Wrangle.xcodeproj/project.pbxproj` → zero matches both before and after the rename.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] pbxproj file-reference edits described in Task 1 action step 3 do not apply to this project**
- **Found during:** Task 1 (file rename)
- **Issue:** Plan Task 1 Action step 3 instructed editing `PBXFileReference` and `PBXBuildFile` entries for `BookmarkSidebarSection.swift` inside `Wrangle.xcodeproj/project.pbxproj`. Verified with `Grep` that no such entries exist — the project uses `fileSystemSynchronizedRootGroup` (Xcode 16 FileSystem-synchronized groups), which auto-compiles every `.swift` file in the target's root directory based on filesystem presence. Individual file references are not tracked in the pbxproj.
- **Fix:** Skipped the pbxproj edit step. The `git mv` alone is sufficient — Xcode's filesystem-sync picks up the rename on next build.
- **Files modified:** None (explicitly no pbxproj edit).
- **Verification:** `grep -c "BookmarkSidebarSection" Wrangle.xcodeproj/project.pbxproj` → 0 both before and after. `xcodebuild ... build` → BUILD SUCCEEDED. No "Build input file cannot be found" error.
- **Committed in:** n/a (skipped work, not added work).

---

**Total deviations:** 1 (Rule 3 — blocking work that turned out to be unnecessary due to Xcode 16 project structure).
**Impact on plan:** No scope creep; the plan's intent (rename the file and keep Xcode compiling against the new name) is fully satisfied. The skipped pbxproj step was anticipatory protection for an older project-file format that this project does not use.

## Issues Encountered

- **Case-insensitive filesystem vs git tracking:** macOS filesystem treats `Wrangle/` and `wrangle/` as the same path, but git tracks exactly what was committed — in this repo, the lowercase `wrangle/` form. First `git mv Wrangle/...` attempt failed with "not under version control"; retried with `git mv wrangle/...` and succeeded. No code change required; noting for any future renames in this repo.
- **Transient mid-plan build failure after Task 1:** Expected and documented in the plan — Task 1 renames the struct, leaving `SidebarView.swift:63` referencing the old name. Task 2 wires the new type and restores the green build in the same plan. Not a deviation; the plan explicitly states Task 1 `done` criteria: "File is NOT yet referenced by SidebarView — that happens in Task 2."

## User Setup Required

None — no external service configuration, no `@AppStorage` migration required. The two orphaned keys from the previous structure (`sidebar.bookmarks.expanded` from the deleted top-level section) will simply stop being read; defaults values for the new `sidebar.browsers.bookmarks.expanded` key land on first launch. Phase 12's `@AppStorage` audit (UIX-22) can choose to delete the orphan or leave it.

## Next Phase Readiness

- **Plan 11-02 (overview) ready to start.** SidebarView is done and green; the Project Overview still has the standalone Bookmarks card + "No X yet" inline rows. Plan 11-02 will fold Bookmarks into the Browsers `CollapsibleVStackSection` and introduce the centered empty-hero per D-11 through D-20.
- **No blockers.** `xcodebuild` clean; all acceptance criteria satisfied for 11-01.
- **Manual UAT deferred:** Behavioral smoke check (delete-last-bookmark causes sub-section to vanish instantly; 0 tabs + 1 bookmark shows `Browsers > Bookmarks (1)`; etc.) remains to be performed against a running app. Matches the project's established testing cadence (unit tests for logic, manual UAT for rendering).

## Self-Check: PASSED

- `[x]` `wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift` exists — confirmed via `test -f`.
- `[x]` `wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift` does NOT exist — confirmed via `test ! -f`.
- `[x]` `grep struct NestedBookmarkSubSection` → 1 match in NestedBookmarkSubSection.swift.
- `[x]` `grep sidebar.browsers.bookmarks.expanded` → 1 match in NestedBookmarkSubSection.swift; 0 elsewhere.
- `[x]` `grep sidebar.bookmarks.expanded` (old key) → 0 matches in Wrangle/.
- `[x]` `grep BookmarkSidebarSection` → 0 matches in both Wrangle/ source and Wrangle.xcodeproj/project.pbxproj.
- `[x]` `grep NestedBookmarkSubSection()` in SidebarView.swift → 1 match (inside BrowserSessionsSection body).
- `[x]` `grep if !projectLocations.isEmpty` in SidebarView.swift → 1 match.
- `[x]` `grep private var projectLocations` in SidebarView.swift → 1 match.
- `[x]` `grep !browsers.isEmpty || !visibleBookmarks.isEmpty` in SidebarView.swift → 1 match.
- `[x]` `git log --oneline -3` → `fab8568` and `2f0a6e6` both present, both on main branch.
- `[x]` `xcodebuild -scheme Wrangle -destination 'platform=macOS,arch=arm64' -configuration Debug build` → **BUILD SUCCEEDED** (final tail line).
- `[x]` No new `withAnimation` wrapping section show/hide — only two `withAnimation` calls in NestedBookmarkSubSection.swift, both on chevron toggle Buttons (lines 40 and 156), preserved verbatim from the pre-rename file. Honors D-22 and user memory `feedback_no_slide_transitions`.

---
*Phase: 11-hide-when-empty-bookmarks-nested-under-browsers*
*Completed: 2026-04-20*
