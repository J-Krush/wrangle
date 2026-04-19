# Phase 10: Unified Creation Pattern — Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 10 delivers a single, consistent creation surface shared across the app. After this phase:

1. **One menu model** drives every `+` button — sidebar bottom `+`, Project Overview header `+`, and the tab strip `+` all present the same items in the same order via a single `UnifiedAddMenu` view.
2. **Every per-section creation affordance is removed** — no `…`, `+`, or `Import…` buttons on any sidebar section header or Project Overview section card. Section headers are nav-only.
3. **The blue `New` pill** beside the project title in `ProjectOverviewView.header` is replaced with a `+` IconButton whose visual treatment matches the sidebar `+`.
4. **The File menu (macOS menubar) and browser toolbar star button are not changed** — they remain authoritative for keyboard shortcuts and the in-feature bookmark gesture respectively.

What this phase does NOT deliver (those are Phases 11–12):
- Hide-when-empty behavior for sections (Phase 11).
- Nesting browser bookmarks inside Browsers (Phase 11).
- Section-header visual normalization / Scratch Pad parity (Phase 12).

</domain>

<decisions>
## Implementation Decisions

### Menu architecture

- **D-01**: A single SwiftUI view `UnifiedAddMenu` lives in `wrangle/Components/` and encapsulates the complete item list. Three presenters render it: the sidebar bottom-bar `+` (in `SidebarView.sidebarBottomBar`), the Project Overview header `+` (replacing the `New` pill in `ProjectOverviewView.newButton`), and the tab strip `+` (in `TitleBarTabStrip`). No alternate item sets exist — the menu is identical across all three surfaces.
- **D-02**: Menu is grouped by creation-type with SwiftUI `Divider`s between groups. Final item list, top → bottom:

  Group 1 — quick create:
  1. Scratch Pad (icon `note.text`, yellow)
  2. Browser (icon `globe`, blue)
  3. Private Browser (icon `lock`, purple)
  4. Bookmark… (icon `star`, yellow)

  Group 2 — terminals (four distinct items, per user override of menu-preview's three-row terminal depiction):
  5. Terminal (icon `terminal`, mint)
  6. Claude Code (icon `brain.head.profile`, orange)
  7. Gemini Code (icon `sparkles`, blue)
  8. Claude (Skip Permissions) (icon `exclamationmark.triangle.fill`, yellow)

  Group 3 — files + folders:
  9. File… (icon `doc.badge.plus`, secondary)
  10. Location… (icon `folder.badge.plus`, gray)

  Group 4 — import:
  11. Import Bookmarks… (icon `square.and.arrow.down`, secondary)

- **D-03**: The tab strip `+` folds fully into `UnifiedAddMenu` — it does not retain a reduced item set. The existing `TitleBarTabStrip.swift:134-178` inline Menu is replaced by the shared presenter.

### Item behaviors

- **D-04** (Bookmark item): Selecting "Bookmark…" opens a small SwiftUI sheet with two fields — URL (text) and Title (text) — and a Save / Cancel pair. The sheet is **always enabled** (no disabled/focus-gated state). If a browser tab is currently active/focused when the menu is invoked, the sheet pre-fills URL and Title from that tab. Saving inserts a new `BrowserBookmark` row in SwiftData scoped to the active project (or Global if no project is selected), then dismisses. The sheet is a lightweight new view (not `BookmarkEditSheet`) — reuse small building blocks (TextField styling, footer button row) but keep the scope to URL + Title only. A "More options…" affordance inside the sheet can route to the full `BookmarkEditSheet` if the user wants to set folder/icon — optional, Claude's discretion.
- **D-05** (Terminal items): Each of the four terminal items opens the existing `TerminalDirectoryPicker` pre-configured with the appropriate launch flags — `launchClaude`, `launchGemini`, `dangerousMode` — matching the pattern already used in `TitleBarTabStrip.swift:146-177`. No changes to `TerminalDirectoryPicker` itself.
- **D-06** (Private Browser): Selecting "Private Browser" calls `appState.openBrowser(isPrivate: true)` — same path already wired for the File-menu shortcut at `wrangleApp.swift:228-232`.
- **D-07** (File, Location, Import Bookmarks): Each delegates to the existing AppState action or `addLocation()` helper already used today by the scattered popovers.

### Removals

- **D-08**: Remove the `...` Menu accessory on Locations section header — `SidebarView.swift:78-96`.
- **D-09**: Remove the `+` IconButton accessory on the Project Overview Locations section — `ProjectOverviewView.swift:549-562`.
- **D-10**: Remove the `Import…` Label accessory on the Project Overview Bookmarks section — `ProjectOverviewView.swift:383-394`.
- **D-11**: Remove any inline import/add rows inside `BookmarkSidebarSection` (see `wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift:69`). `SidebarSectionHeader`'s `accessory` ViewBuilder either becomes `EmptyView` at every call site OR the accessory parameter is dropped entirely from the component — Claude's discretion, based on whether any legitimate non-add accessories remain (if none, drop the param).
- **D-12**: Replace `ProjectOverviewView.newButton` (the blue "New" pill, `ProjectOverviewView.swift:140-178`) with a `+` IconButton whose visual treatment matches the sidebar `+` in `SidebarView.sidebarBottomBar` — `Image(systemName: "plus")` at `.font(.system(size: 16, weight: .medium))`, secondary foreground, subtle hover/press state. Position: still inline with the project title in the overview header.

### What stays untouched

- **D-13**: File menu (`wrangleApp.swift:198-305`) is unchanged. Every shortcut already wired (`Cmd+N`, `Cmd+Shift+N`, `Cmd+Option+B`, `Cmd+Shift+Option+B`, `Cmd+\``, etc.) continues to work via `focusedAppState`. The unified `+` menu does NOT define its own keyboard shortcuts.
- **D-14**: Browser toolbar star button (bookmark current page directly) stays — it's an in-feature gesture, not chrome. Per UIX-23 rationale.
- **D-15**: `BookmarkedDirectory` filesystem locations context menus (e.g., `BookmarkListView.swift:509`, `:590`) are out of scope for this phase. Context-menu "New Browser" / "Add Location…" items on file-tree rows can stay — they're contextual row actions, not section chrome. If the planner finds them visually redundant, they can be trimmed but aren't required deliverables.

### Claude's Discretion

- Exact `@State`/binding plumbing for the unified menu (e.g., whether each presenter owns its own `showMenu` state, whether the menu lives in a `Menu { }` vs a custom popover, whether hover-reveals are added).
- Whether to ship a single `UnifiedAddMenu` with an enum `Presenter` case or just duplicate the content in a helper function. Either is fine; pick whichever keeps the file under 150 lines.
- Whether the "Add Bookmark" sheet exposes a "More options…" link that defers to `BookmarkEditSheet`, or stays strictly URL+Title.
- Visual treatment of the `+` IconButton (padding, hover background, whether it lives in a capsule) — match sidebar `+` as closely as possible, but exact pixel decisions are yours.
- Whether the tab strip `+` label is the same `plus` glyph or gets a slight visual nudge (e.g., background) to disambiguate from the two other `+` buttons on screen simultaneously.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements
- `.planning/REQUIREMENTS.md` §UIX — UIX-01…UIX-05 are the requirement rows this phase must satisfy (1-to-1 with Phase 10).
- `.planning/ROADMAP.md` §Phase 10 — Goal, Success Criteria (5 rows), Plans.

### Code surfaces the phase must touch
- `wrangle/Sidebar/SidebarView.swift:222-243` — existing sidebar bottom `+` Menu (3 items). Replace content with `UnifiedAddMenu`.
- `wrangle/Sidebar/SidebarView.swift:78-96` — Locations section header `...` Menu accessory. Remove.
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:140-178` — blue `New` pill popover (`newButton` + `popoverButton` helper). Replace with `+` IconButton + `UnifiedAddMenu`.
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:549-562` — Locations overview `+` accessory. Remove.
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:383-394` — Bookmarks overview `Import…` accessory. Remove.
- `wrangle/Editor/TitleBarTabStrip.swift:134-178` — tab strip `+` Menu. Replace with `UnifiedAddMenu`.
- `wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift:69` — inline import row in bookmark sidebar section. Remove.
- `wrangle/Components/SidebarSectionHeader.swift` — `accessory` ViewBuilder param usage audit; drop the parameter if no non-add accessories survive.

### Code surfaces to read but NOT touch
- `wrangle/App/wrangleApp.swift:164-305` — `.commands { CommandGroup(replacing: .newItem) }` is the canonical keyboard-shortcut source. Confirm the unified menu does not duplicate these shortcut bindings.
- `wrangle/Terminal/TerminalDirectoryPicker.swift` — variant launch plumbing; reuse as-is.
- `wrangle/Browser/Bookmarks/BookmarkEditSheet.swift` — reference for the "Add Bookmark" sheet (patterns to follow, not to extend).
- `wrangle/App/AppState.swift` — action methods (`newDocument`, `newScratchPad`, `openBrowser(isPrivate:)`, `showBookmarkImport`). Possibly add `showAddBookmarkSheet: Bool` for the new sheet (or use local `@State` in `UnifiedAddMenu` — Claude's discretion).

### Out-of-scope references (for awareness, not action)
- No external specs, ADRs, or HIG references are required. macOS Notes / Mail / Xcode sidebar conventions are the informal design lineage; no formal doc to cite.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `popoverButton(_:icon:color:action:)` in `ProjectOverviewView.swift:181-196` — existing helper that renders one menu row with an icon + title + action. Extract or reuse when building `UnifiedAddMenu`.
- `SidebarSectionHeader` in `wrangle/Components/SidebarSectionHeader.swift` — already a shared component. The `accessory` ViewBuilder is what Phase 10 will empty out across all call sites (`BookmarkSidebarSection`, `BrowserSessionsSection`, `ScratchPadSection`, Locations Section in `SidebarView.swift:78-96`).
- `AppState` action methods in `wrangle/App/AppState.swift` — `newDocument`, `newScratchPad`, `openBrowser(url:isPrivate:)`, `openTerminal(...)`, `showBookmarkImport: Bool` binding, `showBrowserHistory: Bool` binding. All add actions already have an entry point on AppState; `UnifiedAddMenu` wires items to these, nothing new needed.
- `TerminalDirectoryPicker` — opens via `@State showTerminalPicker = true` + `.popover`, pre-configured with `pendingLaunchClaude` / `pendingLaunchGemini` / `pendingDangerousMode`. The four terminal items in the unified menu set these flags then present the picker.
- `CollapsibleVStackSection` — the overview's section wrapper; stays, but its `accessory` closure goes empty after this phase.

### Established Patterns
- **Popover-from-button** for all `+` menus today, with a local `@State showXxxMenu = false` and `.popover(isPresented:)`. Sidebar `+` uses the native `Menu { … }` modifier instead (simpler, handles dismiss for free). The `UnifiedAddMenu` should standardize on `Menu { … }` to align with macOS sidebar conventions.
- **Icon + tinted-color foreground** on menu rows (from `popoverButton`) — matches Xcode and Finder popover style. Keep.
- **Sheet for sub-flows** (e.g., bookmark import uses `appState.showBookmarkImport: Bool` + `.sheet`) — the new Add-Bookmark sheet should follow the same pattern for consistency (either a new AppState binding or a local `@State` on the menu presenter).
- **`@Bindable var appState = appState`** unwrapping at the top of every view that mutates AppState — standard in this codebase (see `SidebarView.swift:29`).

### Integration Points
- `SidebarView.sidebarBottomBar` (line ~221) — replace the inline `Menu { … }` block with `UnifiedAddMenu()` (presenter: sidebar).
- `ProjectOverviewView.newButton` (line 140) — replace the body with a `+` IconButton that presents `UnifiedAddMenu()` (presenter: overview).
- `TitleBarTabStrip.swift:134-178` — replace the inline `Menu { … }` with `UnifiedAddMenu()` (presenter: tabStrip).
- `SidebarSectionHeader` call sites — remove every `accessory: { … }` closure that contains an add/import/ellipsis control.
- If `UnifiedAddMenu` owns the Add-Bookmark sheet state locally, it needs access to the active browser tab (for pre-fill) via `appState.activeTab`.

### Code Hotspots / Complexity
- The tab-strip `+` menu carries per-variant state (`pendingLaunchClaude` / `pendingLaunchGemini` / `pendingDangerousMode`) that feeds into `TerminalDirectoryPicker`. Moving this to a shared `UnifiedAddMenu` requires either: (a) replicating that state per-presenter, (b) moving it onto `AppState`, or (c) each presenter owns its own terminal picker invocation. Planner decides — note that the three presenters may concurrently need independent picker state if they can all be visible at once (they can: tab strip + overview + sidebar are all on screen simultaneously).

</code_context>

<specifics>
## Specific Ideas

- The user's goal: "something to be more user intuitive than it is now and consistent across types of things." The unified menu is the primary vehicle for that consistency.
- The four terminal items choice (D-02, Group 2) contradicts the preview shown for the "Full menu" option which depicted three terminal rows. Reconciled in favor of the explicit Terminal-Variants answer: **four items, not three.** The Claude (Skip Permissions) row retains its warning-triangle icon to signal the `--dangerously-skip-permissions` behavior.
- The unified `+` menu must be visually a single, obvious affordance — one icon, no ambiguous pill/badge treatment. The blue `New` pill being removed is specifically about reducing the "what is this?" factor the user called out in their annotated screenshot.

</specifics>

<deferred>
## Deferred Ideas

- **Hide-when-empty for sidebar and overview sections** → Phase 11. Do not implement hide-when-empty during Phase 10 — removing per-section chrome (D-08…D-11) will expose the ugly always-show empty states briefly; Phase 11 fixes that.
- **Nesting browser bookmarks inside Browsers section** → Phase 11.
- **Section header visual normalization** (single `SidebarSectionHeader` treatment across all section types) → Phase 12.
- **Scratch Pad rename/delete parity** with Bookmarks rows → Phase 12.
- **Multi-type "Saved" bucket** (file bookmarks + browser bookmarks under one home) → out of scope for v1.2 entirely; noted in `.planning/REQUIREMENTS.md` as a future-milestone consideration.

</deferred>

---

*Phase: 10-unified-creation-pattern*
*Context gathered: 2026-04-19*
