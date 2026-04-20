---
phase: 10-unified-creation-pattern
plan: 02
subsystem: ui
tags: [swiftui, macos, cleanup, ux-polish, chrome-removal]

# Dependency graph
requires:
  - phase: 10-unified-creation-pattern
    plan: 01
    provides: "UnifiedAddMenu (sidebar bottom `+`, overview header `+`, tab strip `+`) — the single entry point every removed per-section action now routes through."
provides:
  - "Per-section creation affordances removed from sidebar and Project Overview: Locations `...`, Bookmarks `...`, Bookmarks card `Import…`, Locations card `+` are all gone."
  - "Simplified SidebarSectionHeader — generic `Accessory: View` parameter + ViewBuilder closure dropped; component is now a nav-only chevron/title/spacer."
affects:
  - "11 (hide-when-empty + bookmarks nested under browsers) — unblocked: sidebar + overview chrome is now nav-only, so Phase 11 can add hide-when-empty logic without first unwinding stale per-section controls."
  - "12 (section parity & polish) — simpler `SidebarSectionHeader` signature; all four call sites are identical shape, making canonical visual normalization a drop-in."

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Nav-only section headers. Section headers (`SidebarSectionHeader`, `BookmarkSidebarSection` inline header, `CollapsibleVStackSection`) render chevron + title (+ optional count badge) only. Creation is centralized in `UnifiedAddMenu` and never duplicated on section chrome."

key-files:
  modified:
    - "wrangle/Sidebar/SidebarView.swift"
    - "wrangle/Features/Dashboard/ProjectOverviewView.swift"
    - "wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift"
    - "wrangle/Components/SidebarSectionHeader.swift"

key-decisions:
  - "SidebarSectionHeader generic parameter dropped entirely (preferred path per D-11 / Task 4). All four call sites (Scratch Pads, Locations, Browsers, Other Sessions) passed the EmptyView default post-Task-1, so the `@ViewBuilder accessory` closure became dead weight. New signature: `struct SidebarSectionHeader: View` with `let title` + `@Binding var isExpanded`."
  - "BookmarkSidebarSection inline header kept its custom HStack (chevron + title + count badge + drop delegate) rather than being converted to `SidebarSectionHeader`. Reason: the count badge `(N)` is bookmark-specific and `SidebarSectionHeader` is intentionally nav-only (no trailing UI). A Phase 12 canonical-header normalization pass may revisit this; out of scope here per phase boundaries."
  - "`addLocation()` private methods in both `SidebarView.swift` and `ProjectOverviewView.swift` retained even though each has one fewer caller post-plan. `SidebarView.addLocation()` is still called by `ProjectBookmarkListView(... onAddLocation: addLocation)` (sidebar empty-state CTA). `ProjectOverviewView.addLocation()` is unreferenced after this plan, but Phase 11's empty-state hero will want it back; leaving it in place with the existing code shape keeps Phase 11's diff smaller. Compiler does not warn on unused private methods in Swift, so no noise."
  - "`@State editing: BrowserBookmark?` + `.sheet(item: $editing)` retained in `BookmarkSidebarSection`. Row-level context-menu `Edit...` fires the sheet; dropping it would be a regression. Only the dead `@State showingNewBookmarkSheet`, `@State showingNewFolderAlert`, `@State newFolderName`, the corresponding `.alert`, `.sheet`, and `private func createFolder()` were removed."
  - "`New Folder...` action is accepted dead for Phase 10. Users can still assign an existing folder via `BookmarkEditSheet`. `UnifiedAddMenu` intentionally does not expose `New Folder...` (per plan 10-01 decisions). If UAT rejects this in Phase 10, fold a `New Folder...` item into `UnifiedAddMenu` as a follow-up; do not reopen 10-02."

patterns-established:
  - "After Phase 10, the only `+` / creation controls in the main workspace chrome are the sidebar bottom `+` and the Project Overview header `+`. The tab strip `+` (from 10-01) is the third presenter, but it is chrome of the tab strip not a section header. Per-section chrome is strictly navigation."

requirements-completed: [UIX-03, UIX-04]

# Metrics
duration: ~3min
completed: 2026-04-20
---

# Phase 10 Plan 02: Remove Per-Section Creation Chrome Summary

**Per-section `+` / `…` / `Import…` controls stripped from sidebar and Project Overview; `SidebarSectionHeader` generic `accessory` ViewBuilder dropped entirely.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-20T00:06:31Z
- **Completed:** 2026-04-20T00:09:26Z
- **Tasks:** 5 (4 code tasks + 1 checkpoint auto-approved in sequential-mode)
- **Files modified:** 4

## Accomplishments

- Sidebar Locations section header is now a plain `SidebarSectionHeader(title: "Locations", isExpanded: …)` — no `…` Menu accessory, no ellipsis glyph.
- Sidebar Bookmarks section header (in `BookmarkSidebarSection`) is now chevron + title + count badge + drop-to-unfile gesture only — the trailing `Menu { New Bookmark... / New Folder... / Import Bookmarks... }` is gone.
- Project Overview Bookmarks card has no `Import…` Label accessory.
- Project Overview Locations card has no `+` Image accessory.
- `SidebarSectionHeader` is no longer generic: `struct SidebarSectionHeader: View` replaces `struct SidebarSectionHeader<Accessory: View>: View`. The `@ViewBuilder let accessory: () -> Accessory` stored property and custom `init` are dropped. All four call sites (Scratch Pads, Locations, Browsers, Other Sessions) are source-compatible because they already passed no accessory closure.
- Dead state + helpers removed from `BookmarkSidebarSection`: `@State newFolderName`, `@State showingNewFolderAlert`, `@State showingNewBookmarkSheet`, `.alert("New Bookmark Folder")`, `.sheet(isPresented: $showingNewBookmarkSheet)`, and `private func createFolder()`.
- Row-level context-menu "Edit…" path preserved (`@State editing` + `.sheet(item: $editing)` still mounted).
- Drag-and-drop of bookmarks onto the Bookmarks section header to reparent them to unfiled preserved (`BookmarkFolderDropDelegate` still wired on `.onDrop`).
- Xcode build passes `** BUILD SUCCEEDED **` after each of the four task commits (macOS arm64 Debug).

## Task Commits

Each task was committed atomically on the main branch:

1. **Task 1: Remove Locations sidebar `...` accessory** — `9e8e96a` (refactor)
2. **Task 2: Remove Project Overview per-card accessories (Bookmarks Import, Locations +)** — `72838bf` (refactor)
3. **Task 3: Remove inline `...` Menu from BookmarkSidebarSection header** — `16829d4` (refactor)
4. **Task 4: Simplify SidebarSectionHeader — drop `accessory` ViewBuilder** — `118b973` (refactor)
5. **Task 5: Human verification checkpoint** — auto-approved (sequential-mode executor); manual UAT deferred to user.

## Files Created/Modified

- `wrangle/Sidebar/SidebarView.swift` — **modified.** Locations `Section header` closure went from `SidebarSectionHeader(title: "Locations", isExpanded: …) { Menu { Button("Add Location...") { addLocation() } } label: { Image(systemName: "ellipsis") … } … .help("Location actions") }` to a plain `SidebarSectionHeader(title: "Locations", isExpanded: $isLocationsExpanded)`. Net change: -13 lines. Private `addLocation()` method is retained (empty-state callback at `ProjectBookmarkListView(… onAddLocation: addLocation)` still uses it).
- `wrangle/Features/Dashboard/ProjectOverviewView.swift` — **modified.** `bookmarksSection` and `locationsSection` each drop their `accessory:` argument to `CollapsibleVStackSection`. `CollapsibleVStackSection` itself is untouched (its `accessory` parameter remains for other consumers outside Phase 10 scope). Net change: -19 lines. `addLocation()` private helper, `popoverButton()` helper, and the terminal-picker state are all retained for the per-row `locationCard` popover (out of Phase 10 scope per D-15).
- `wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift` — **modified.** Inline header HStack stripped of its trailing `Menu { … }` (three Button rows + ellipsis label) and three dependent `@State` properties. `.alert("New Bookmark Folder")`, `.sheet(isPresented: $showingNewBookmarkSheet)`, and `private func createFolder()` deleted. Net change: -43 lines. Row-level `.sheet(item: $editing)` + `BookmarkFolderDropDelegate` survive unchanged.
- `wrangle/Components/SidebarSectionHeader.swift` — **modified.** Struct is no longer generic (`struct SidebarSectionHeader: View` replaces `struct SidebarSectionHeader<Accessory: View>: View`). `@ViewBuilder let accessory` stored property removed. Custom init removed — synthesized memberwise init via `let` + `@Binding` suffices. Body drops the `accessory()` call. Net change: -11 lines.

## Decisions Made

- **Preferred path for SidebarSectionHeader simplification.** The grep pre-check (Task 4 `read_first`) confirmed exactly four call sites, all passing no accessory post-Task-1. The alt-branch (keep generic) was only for the unexpected fifth-call-site case, which did not materialize. Dropping the generic parameter is a net simplification: four fewer lines in the component + zero ceremony at every call site.
- **Do not canonicalize `BookmarkSidebarSection` to use `SidebarSectionHeader`.** That header has a bookmark-count badge `(N)` in its title area that `SidebarSectionHeader` does not support (and intentionally should not, post-D-11). Forcing consistency here would either re-add a parameter to `SidebarSectionHeader` (undoing Task 4) or drop the badge (UX regression). Phase 12 may revisit with a dedicated count-badge variant; out of scope for 10-02.
- **Retain both `addLocation()` private methods.** `SidebarView.addLocation()` has a surviving caller (`ProjectBookmarkListView(… onAddLocation: addLocation)`). `ProjectOverviewView.addLocation()` is unreferenced post-plan, but Phase 11 will want it back for the project-level empty-state hero; deleting + re-adding churns the diff for no gain. Swift does not warn on unused private methods so there is no lint noise.
- **Accept `New Folder…` having no UI entry point.** Plan 10-01 deliberately did not include `New Folder…` in `UnifiedAddMenu`, and 10-02 strips the old inline trigger. Users can still assign an existing folder via `BookmarkEditSheet` on any bookmark. The phase boundary explicitly defers new bookmark-folder creation affordances; a follow-up ticket can fold it into `UnifiedAddMenu` if UAT demands.

## Deviations from Plan

None — plan executed exactly as written.

- No Rule 1 bugs found (no broken behavior discovered during execution).
- No Rule 2 missing-critical-functionality (no security / validation gaps introduced by pure removals).
- No Rule 3 blockers (build stayed green after every task commit; no missing imports, types, or dependencies).
- No Rule 4 architectural decisions required.
- Task order followed the plan's numbering 1 → 2 → 3 → 4 → 5. The plan's pre-check for Task 4 flagged the "unexpected 5th call site" alt path as possible; it was not triggered — all four SidebarSectionHeader call sites passed no accessory post-Task-1 as expected.

## Issues Encountered

- **macOS case-insensitive vs. git case-sensitive path (again).** Initial `git add Wrangle/Sidebar/SidebarView.swift` (capital W) silently staged nothing. Resolved by using lowercase `wrangle/…` in every `git add` — same workaround documented in 10-01-SUMMARY.md. No files renamed; repo-level path case is a pre-existing condition outside Phase 10 scope.

## Known Stubs

None. All removed code paths had equivalent surfaces reachable through `UnifiedAddMenu` from 10-01:

| Removed control | Replacement path |
|-----------------|------------------|
| Sidebar Locations `...` → `Add Location…` | Sidebar `+` → `Location…` |
| Overview Bookmarks card `Import…` | Sidebar `+` / Overview `+` → `Import Bookmarks…` |
| Overview Locations card `+` | Sidebar `+` / Overview `+` → `Location…` |
| BookmarkSidebarSection `...` → `New Bookmark…` | Sidebar `+` / Overview `+` → `Bookmark…` |
| BookmarkSidebarSection `...` → `Import Bookmarks…` | Sidebar `+` / Overview `+` → `Import Bookmarks…` |
| BookmarkSidebarSection `...` → `New Folder…` | (Accepted gap — Phase 11/12 or follow-up may add to UnifiedAddMenu if UAT demands) |

`New Folder…` is the one accepted gap and is documented as such in Task 3 `<action>` and in Decisions Made above.

## Residual State (documented per plan output spec)

- `CollapsibleVStackSection` `accessory` parameter is unused after this plan but retained in the component signature. Every Phase 10 call site now omits it; any future surface that wants a card-level accessory still has the hook available. Not a dead parameter in API terms — only unused at the current call sites.
- `ProjectOverviewView.addLocation()` has zero call sites after this plan but is retained for Phase 11. If Phase 11 ships a different hero mechanism and does not need it, a later polish pass can remove it.
- `BookmarkSidebarSection` still imports `UniformTypeIdentifiers` and `AppKit`. `UniformTypeIdentifiers` is used by `.onDrop(of: [.text])`. `AppKit` is used by `NSPasteboard` (`BookmarkRow.copyURL`), `NSImage` (favicon rendering). Both remain necessary.

## Self-Check Matrix

Automated acceptance grep + build matrix (ran after every commit; final state shown below):

| Check | Expected | Actual |
|-------|----------|--------|
| `grep -c '"Add Location..."' SidebarView.swift` | 0 | 0 ✓ |
| `grep -c 'Image(systemName: "ellipsis")' SidebarView.swift` | 0 | 0 ✓ |
| `grep -c 'title: "Locations"' SidebarView.swift` | 1 | 1 ✓ |
| `grep -c 'onAddLocation: addLocation' SidebarView.swift` | ≥1 | 1 ✓ |
| `grep -c 'Label("Import...", systemImage:' ProjectOverviewView.swift` | 0 | 0 ✓ |
| `grep -c 'appState.showBookmarkImport = true' ProjectOverviewView.swift` | 0 | 0 ✓ |
| `grep -c 'accessory: {' ProjectOverviewView.swift` | 0 | 0 ✓ |
| `grep -c '"Bookmarks"' ProjectOverviewView.swift` | ≥1 | ✓ (line 348) |
| `grep -c '"Locations"' ProjectOverviewView.swift` | ≥1 | ✓ (line 506) |
| `grep -c 'func locationCard' ProjectOverviewView.swift` | 1 | 1 ✓ |
| `grep -c 'Button("New Bookmark...")' BookmarkSidebarSection.swift` | 0 | 0 ✓ |
| `grep -c 'Button("New Folder...")' BookmarkSidebarSection.swift` | 0 | 0 ✓ |
| `grep -c 'Button("Import Bookmarks...")' BookmarkSidebarSection.swift` | 0 | 0 ✓ |
| `grep -c 'showingNewBookmarkSheet' BookmarkSidebarSection.swift` | 0 | 0 ✓ |
| `grep -c 'newFolderName' BookmarkSidebarSection.swift` | 0 | 0 ✓ |
| `grep -c 'systemName: "ellipsis"' BookmarkSidebarSection.swift` | 0 | 0 ✓ |
| `grep -c 'private func createFolder' BookmarkSidebarSection.swift` | 0 | 0 ✓ |
| `grep -c '.sheet(item: \$editing)' BookmarkSidebarSection.swift` | 1 | 1 ✓ |
| `grep -c 'BookmarkFolderDropDelegate' BookmarkSidebarSection.swift` | ≥1 | 3 ✓ |
| `grep -rn 'SidebarSectionHeader(' Wrangle/ --include='*.swift' \| wc -l` | 4 | 4 ✓ |
| `grep -c '@ViewBuilder.*accessory' SidebarSectionHeader.swift` | 0 | 0 ✓ |
| `grep -c 'let accessory' SidebarSectionHeader.swift` | 0 | 0 ✓ |
| `grep -c 'struct SidebarSectionHeader: View' SidebarSectionHeader.swift` | 1 | 1 ✓ |
| awk trailing-`{` on any `SidebarSectionHeader(...)` call | 0 | 0 ✓ |
| `xcodebuild … build` (after each commit) | BUILD SUCCEEDED | ✓ (all 4) |

## User Setup Required

None — no external service configuration, no data migration, no schema change.

## Next Phase Readiness

- **Phase 11 unblocked.** Sidebar + Project Overview chrome is now navigation-only. Phase 11's hide-when-empty and bookmarks-nested-under-browsers plans can modify section visibility without first unwinding stale per-section chrome.
- **Phase 12 easier.** `SidebarSectionHeader`'s simpler signature (no generic, no ViewBuilder) makes canonical visual normalization trivial — the only four call sites are literally identical shape. `BookmarkSidebarSection`'s bookmark-specific count badge is the one surface that still needs parity work; Phase 12 will decide whether to generalize `SidebarSectionHeader` (with a count badge param) or leave `BookmarkSidebarSection` with its bespoke header.
- **Manual UAT still owed.** Checkpoint Task 5 was auto-approved in sequential mode. Steps 1-13 in `10-02-PLAN.md §Task 5` are the acceptance rubric the user can walk through when ready.

## Self-Check: PASSED

- `test -f .planning/phases/10-unified-creation-pattern/10-02-SUMMARY.md` → FOUND (this file)
- `git log --oneline | grep 9e8e96a` → FOUND (Task 1 commit)
- `git log --oneline | grep 72838bf` → FOUND (Task 2 commit)
- `git log --oneline | grep 16829d4` → FOUND (Task 3 commit)
- `git log --oneline | grep 118b973` → FOUND (Task 4 commit)
- `xcodebuild … build` → `** BUILD SUCCEEDED **` (macOS arm64 Debug)
- Full acceptance grep matrix above — 25/25 PASS

---
*Phase: 10-unified-creation-pattern*
*Completed: 2026-04-20*
