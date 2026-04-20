---
phase: 10-unified-creation-pattern
plan: 01
subsystem: ui
tags: [swiftui, macos, menu, navigation, ux-polish]

# Dependency graph
requires:
  - phase: 09-private-incognito-mode
    provides: "openBrowser(isPrivate:) AppState entry point — reused by the unified menu's Private Browser item."
  - phase: 05-bookmark-foundations
    provides: "NewBookmarkSheet + BookmarkStore — the sheet that the unified menu's Bookmark… item presents."
provides:
  - "UnifiedAddMenu — single SwiftUI view owning the 11-item creation menu rendered by every `+` button in app chrome."
  - "NewBookmarkSheet optional URL/Title prefill initializer — lets callers pre-populate from a focused browser tab."
  - "Consolidated `+` affordance across sidebar bottom bar, tab strip, and Project Overview header (blue `New` pill replaced)."
affects:
  - "10-02 (per-section chrome removal) — now has a single entry point in place so the `...` / `+` / `Import…` accessories on section headers can be stripped without losing discoverability."
  - "11 (hide-when-empty) — relies on the unified `+` to surface creation actions that previously lived in inline section empty-states."

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared SwiftUI `Menu { }` view (UnifiedAddMenu) used by three sibling presenters; each presenter instantiates its own copy, so per-instance @State (terminal picker flags, bookmark prefill) does not collide when all three are on-screen simultaneously."
    - "Optional prefill init parameters on existing sheets (NewBookmarkSheet) with default values preserve API compatibility for single-argument call sites."

key-files:
  created:
    - "wrangle/Components/UnifiedAddMenu.swift"
  modified:
    - "wrangle/Browser/Bookmarks/NewBookmarkSheet.swift"
    - "wrangle/Sidebar/SidebarView.swift"
    - "wrangle/Editor/TitleBarTabStrip.swift"
    - "wrangle/Features/Dashboard/ProjectOverviewView.swift"

key-decisions:
  - "Each presenter (sidebar / tab strip / overview) instantiates its own UnifiedAddMenu, so per-instance @State for the terminal picker and bookmark sheet is isolated. Chosen over moving picker state onto AppState — keeps the hotspot localized and mirrors the existing pattern already in ProjectOverviewView for the per-location popover."
  - "addLocation() is inlined verbatim from SidebarView.swift:368-418 (including the no-project branch that auto-creates a Project). The appState.pendingLocationAdd shortcut is gated on selectedProjectID != nil in ContentView.swift:245-249 and would silently no-op at the top level — regression vs. today's sidebar `+` behavior."
  - "Extended NewBookmarkSheet with optional prefill rather than creating a separate Add-Bookmark sheet view. Single existing call site at BookmarkSidebarSection.swift:91 continues to compile unchanged via default-empty-string parameters."
  - "Task execution order swapped (Task 2 → Task 1 → Task 3) to let each commit independently build. Task 1's UnifiedAddMenu references the new prefill init that Task 2 adds. Documented as Rule 3 deviation."

patterns-established:
  - "When a shared SwiftUI view needs per-instance local state (popovers, sheets, pending flags), instantiate-per-presenter is preferred over lifting state to AppState. Keeps blast radius small and matches the existing per-location popover pattern in ProjectOverviewView."
  - "Inline-verbatim when the action includes logic the shortcut path omits (like the no-project auto-Project creation in addLocation)."

requirements-completed: [UIX-01, UIX-02, UIX-05]

# Metrics
duration: ~45min
completed: 2026-04-19
---

# Phase 10 Plan 01: Unified Creation Pattern (Shared +) Summary

**Single shared `UnifiedAddMenu` view replaces three divergent `+` menus (sidebar, tab strip, overview) with an identical 11-item creation menu; blue `New` pill retired in favor of a `+` IconButton.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-19
- **Completed:** 2026-04-19
- **Tasks:** 4 (3 code tasks + 1 checkpoint auto-approved in sequential-mode)
- **Files modified:** 4 (+1 created)

## Accomplishments

- `UnifiedAddMenu` (new SwiftUI View, ~220 lines) is now the single source of truth for the 11-item creation menu: 4 quick-create items, 4 terminal variants, 2 file/folder items, 1 import item, with three group dividers — identical across every `+` presenter in app chrome.
- All four terminal variants (Terminal / Claude Code / Gemini Code / Claude (Skip Permissions)) route through `TerminalDirectoryPicker` with the correct `launchClaude` / `launchGemini` / `dangerousMode` flags.
- `Bookmark…` pre-fills URL + Title from the focused browser tab (`appState.activeTab?.browserSession?.activeTab`) when present, falling back to blank fields with title focus otherwise.
- `addLocation()` handles both the project-selected and no-project cases (auto-creates a `Project` for the bookmark when none is selected) — no regression vs. today's sidebar `+`.
- Blue `New` pill in Project Overview header is gone; replaced by a `+` IconButton whose glyph/frame/foreground exactly match the sidebar `+` (16pt medium, secondary, 28×28).
- Tab strip `+` now presents the full 11-item menu (was previously 7 items with a different grouping).
- `NewBookmarkSheet` extended with optional `prefillURL` / `prefillTitle` init parameters. Existing single-argument call site at `BookmarkSidebarSection.swift:91` compiles unchanged via default-empty defaults; new caller in `UnifiedAddMenu` passes prefill values.
- File-menu keyboard shortcuts in `wrangleApp.swift` (Cmd+N, Cmd+Shift+N, Cmd+Option+B, Cmd+Shift+Option+B, Cmd+Option+N) are untouched and remain the canonical shortcut source (D-13).
- Xcode build passes after every task commit (`BUILD SUCCEEDED` on macOS arm64 Debug).

## Task Commits

Each task was committed atomically:

1. **Task 2: Extend NewBookmarkSheet with optional prefill** — `b6f7521` (feat) — executed first per Rule 3 reorder so Task 1's new file would build in isolation.
2. **Task 1: Create UnifiedAddMenu.swift** — `97487cf` (feat)
3. **Task 3: Wire UnifiedAddMenu into sidebar, tab strip, overview** — `bf6bf2d` (refactor)
4. **Task 4: Human verification checkpoint** — auto-approved (sequential-mode executor); manual UAT deferred to user.

## Files Created/Modified

- `wrangle/Components/UnifiedAddMenu.swift` — **created.** Shared `UnifiedAddMenu` view with 11-item Menu content, per-instance `@State` for terminal picker + bookmark sheet, verbatim `addLocation()` helper, and a `Menu`-styled `+` label matching the sidebar treatment.
- `wrangle/Browser/Bookmarks/NewBookmarkSheet.swift` — **modified.** Added `prefillURL` / `prefillTitle` let-properties and an explicit `init(projectID:prefillURL:prefillTitle:)` with defaults; seeds `@State` title/urlString from the prefills; added `urlFocused` `@FocusState` so the cursor lands in the URL field when a title was pre-populated.
- `wrangle/Sidebar/SidebarView.swift` — **modified.** `sidebarBottomBar` now renders `UnifiedAddMenu()` in place of the previous inline 3-item Menu (New Scratch Pad / New Browser / Add Location). The rest of the bottom bar (search, filter popover, active-sessions toggle) is unchanged. The Locations section-header `...` accessory remains — that's plan 10-02's scope.
- `wrangle/Editor/TitleBarTabStrip.swift` — **modified.** Replaced the inline 7-item Menu + trailing `TerminalDirectoryPicker` popover with `UnifiedAddMenu().padding(.horizontal, 6)`. Removed four now-unused `@State` vars (`showTerminalPicker`, `pendingLaunchClaude`, `pendingLaunchGemini`, `pendingDangerousMode`). Drag-drop state (`draggingTabID`, `dropTargetTabID`, `isEndDropTargeted`) was kept — still used by the tab reordering drop targets.
- `wrangle/Features/Dashboard/ProjectOverviewView.swift` — **modified.** `newButton` body replaced with `UnifiedAddMenu()`; the blue "New" pill (`Text("New")` + `RoundedRectangle(cornerRadius: 6)`) is gone. Removed the unused `showNewMenu` `@State`. Retained `showTerminalPicker` / `pendingLaunchClaude` / `pendingLaunchGemini` / `pendingDangerousMode` — still referenced by `launchInProject(...)` and the header-level `TerminalDirectoryPicker` `.popover` attached to the view root. Retained the `popoverButton(_:icon:color:action:)` helper — it is still used by the `locationCard` per-location popover, which is out of Phase 10 scope per D-15.

## Decisions Made

- **Per-instance state over centralized state.** Three on-screen `UnifiedAddMenu` instances (sidebar, tab strip, overview) each own their own `showTerminalPicker` / `pendingLaunch*` / `showAddBookmarkSheet`. Adding these bindings to AppState would have been centrally clean but invites cross-presenter state collisions (e.g., opening the picker from sidebar while overview is also rendered). The duplication cost is minimal because the state is all local `Bool` / `String`.
- **Verbatim `addLocation()` inlining.** The plan explicitly called out that `appState.pendingLocationAdd` silently no-ops at the top level (`ContentView.swift:245-249` gates on `selectedProjectID != nil`), so reusing that shortcut would be a regression. Inlining the full ~50-line helper — including the no-project branch that auto-creates a `Project` — preserves parity.
- **Extend, don't duplicate, `NewBookmarkSheet`.** Adding optional prefill parameters with default values keeps the existing single-argument call site at `BookmarkSidebarSection.swift:91` compiling unchanged and avoids a second sheet type for the same purpose.

## Deviations from Plan

### Rule 3 – Blocking (task order reorder)

**1. [Rule 3 – Blocking] Executed Task 2 before Task 1 so each task commit would build standalone.**
- **Found during:** Task 1 (first attempt)
- **Issue:** The plan's Task 1 body for `UnifiedAddMenu` references `NewBookmarkSheet(projectID:, prefillURL:, prefillTitle:)`, which is a new initializer introduced by Task 2. Writing `UnifiedAddMenu.swift` before extending the sheet would leave the repo in a non-building state between the Task 1 and Task 2 commits. The plan's own acceptance criteria for Task 1 require `BUILD SUCCEEDED`, which is mutually exclusive with the stated task order.
- **Fix:** Swapped execution order: Task 2 (sheet prefill) → Task 1 (UnifiedAddMenu) → Task 3 (presenter wiring). Each of the three task commits builds cleanly on its own predecessor.
- **Files affected:** none beyond the already-planned ones. No code shape changed.
- **Verification:** `xcodebuild … build` passes after each of the three commits (`b6f7521`, `97487cf`, `bf6bf2d`).
- **Committed in:** reflected in commit order in git log; no additional commits.

No other deviations — code, action bodies, and file boundaries match the plan exactly.

---

**Total deviations:** 1 auto-fixed (1 blocking/reorder).
**Impact on plan:** Cosmetic (ordering only). No scope creep, no semantic change.

## Issues Encountered

- **macOS case-insensitive vs. git case-sensitive path.** The on-disk directory is `Wrangle/` but git tracks it as `wrangle/` (legacy from the original commit). Initial `git add Wrangle/Browser/...` silently staged nothing. Resolved by using lowercase `wrangle/...` in `git add` commands. Did not modify any files or rename the tracked path — out of scope, and renaming has multi-commit history implications.

## Residual State (documented per plan output spec)

- **`popoverButton(_:icon:color:action:)` helper retained in `ProjectOverviewView.swift`** — still used by `locationCard` (the per-row popover showing Open Terminal / Launch Claude Code / Launch Gemini Code / Claude (Skip Permissions) / Reveal in Finder). That popover is out of Phase 10 scope per D-15 (contextual row actions, not section chrome). Removing it would be a no-op compiler win and is plan 10-02's / a later plan's call.
- **`showTerminalPicker`, `pendingLaunchClaude`, `pendingLaunchGemini`, `pendingDangerousMode` `@State` retained in `ProjectOverviewView.swift`** — still referenced by the view-level `TerminalDirectoryPicker` `.popover` (line ~97 in pre-refactor file) and by `launchInProject(claude:gemini:)` (line ~702). `launchInProject` itself appears to be dead code (not called anywhere) but removing it is out of this plan's declared file modification list.
- **`draggingTabID`, `dropTargetTabID`, `isEndDropTargeted` `@State` retained in `TitleBarTabStrip.swift`** — tab drag-and-drop reordering still uses these; unrelated to the `+` menu.
- **Locations section-header `...` accessory in `SidebarView.swift:78-96`, `bookmarksSection` `Import…` accessory (`ProjectOverviewView.swift:382-398`), and `locationsSection` `+` accessory (`ProjectOverviewView.swift:549-562`) all left in place** — these are plan 10-02's removal scope per the phase context. The user will see duplicate affordances mid-state, which is the expected intermediate state.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 10-02 can now strip every per-section `+` / `…` / `Import…` accessory without losing discoverability — the `UnifiedAddMenu` exposes every removed action.
- The `SidebarSectionHeader.accessory` ViewBuilder audit (plan 10-02) will find that, once the Locations `...` is removed, no legitimate non-add accessories survive — the `accessory` param can likely be dropped entirely.
- Manual UAT (Task 4 checkpoint steps 1-11) is deferred to the user. The automated acceptance (grep + build) passes; visual parity and per-item behavior (pre-fill, terminal variants, no-project Location add) are best confirmed by clicking through the menus in a running app. See `10-01-PLAN.md` §Task 4 for the UAT steps.

## Self-Check: PASSED

- `test -f wrangle/Components/UnifiedAddMenu.swift` → FOUND
- `git log --oneline | grep b6f7521` → FOUND (Task 2 commit)
- `git log --oneline | grep 97487cf` → FOUND (Task 1 commit)
- `git log --oneline | grep bf6bf2d` → FOUND (Task 3 commit)
- `xcodebuild … build` → `** BUILD SUCCEEDED **` (macOS arm64 Debug)
- Acceptance grep matrix: all 11 Label strings present exactly once, 3 Dividers, 0 keyboardShortcut, 0 pendingLocationAdd, SecurityScopedBookmark.create + Project(name:) both present, isPrivate:true + dangerousMode wired, activeTab?.browserSession?.activeTab prefill plumbing present.

---
*Phase: 10-unified-creation-pattern*
*Completed: 2026-04-19*
