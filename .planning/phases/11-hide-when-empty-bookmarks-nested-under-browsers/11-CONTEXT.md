# Phase 11: Hide-When-Empty + Bookmarks Nested Under Browsers — Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 11 delivers two reinforcing changes to the sidebar and Project Overview:

1. **Hide-when-empty** — Scratch Pads, Browsers, Locations, and (new) Bookmarks sub-section only render when they have content. Overview section cards hide entirely when empty. A single overview-level hero replaces every per-card "No X yet…" placeholder row.
2. **Bookmarks nested under Browsers** — The top-level `BookmarkSidebarSection` call is removed from `SidebarView`; its content folds into `BrowserSessionsSection` as a nested collapsible sub-section. On the overview, the standalone `bookmarksSection` card is removed; its content nests inside the existing Browsers `CollapsibleVStackSection`. One card, two chevrons.

What Phase 11 does NOT deliver (deferred to Phase 12):

- Canonical `SidebarSectionHeader` visual parity across all section types (UIX-20).
- Scratch Pad rename/delete parity with Bookmarks rows (UIX-21).
- Full `@AppStorage` expansion-state key audit (UIX-22).
- Assert-no-residual-empty-state-rows sweep (UIX-23).

Phase 11 covers UIX-10 through UIX-15 only.

</domain>

<decisions>
## Implementation Decisions

### Sidebar hide-when-empty

- **D-01**: Wrap the Locations `Section { … }` at `SidebarView.swift:66-83` in `if !projectLocations.isEmpty { … }`. Source the count via either a `@Query` filter on `BookmarkedDirectory` + active `selectedProjectID`, or an inlined helper mirroring `ProjectOverviewView.projectBookmarks`. (Scratch Pads at `:49-61`, Browsers at `:530-543`, and Other Sessions at `:548-566` already use this pattern — extend it to Locations for parity.)
- **D-02**: Remove the top-level `BookmarkSidebarSection()` call at `SidebarView.swift:63`. The file `wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift` is either deleted or refactored into a small private helper view used inside `BrowserSessionsSection`. Planner picks deletion vs refactor; the Section-wrapper + bespoke header at `BookmarkSidebarSection.swift:29-61` is what gets torn out either way.

### Sidebar nesting structure

- **D-03**: Inside `BrowserSessionsSection` (currently at `SidebarView.swift:526-544`), after the `ForEach(browsers) { LocationBrowserRow(session: $0) }`, render a nested Bookmarks sub-section: a chevron-button header row, then if expanded: unfiled bookmarks inline (no wrapper folder), then top-level `BookmarkFolderNode` rows. Reuse `BookmarkFolderNode` + `BookmarkRow` from `BookmarkSidebarSection.swift` unchanged.
- **D-04**: The Bookmarks sub-header shows the count **only when collapsed**. Expanded: `▾ Bookmarks`. Collapsed: `▸ Bookmarks (5)`. Count style: `.font(.system(size: 10))`, `.foregroundStyle(.tertiary)` (mirrors the current BookmarkSidebarSection header count styling at `BookmarkSidebarSection.swift:46-49`).
- **D-05**: Two independent `@AppStorage` keys:
  - `sidebar.browsers.expanded` — already exists at `SidebarView.swift:528`; controls the outer Browsers chevron.
  - `sidebar.browsers.bookmarks.expanded` — new; controls the nested Bookmarks chevron.
  User can collapse Bookmarks while keeping Browsers expanded and vice versa. Matches the `sidebar.<section>.expanded` naming convention locked for Phase 12 (UIX-22).
- **D-06**: Unfiled bookmarks render inline at the top of the Bookmarks sub-section — no synthetic "Unfiled" folder wrapper. Matches current ordering at `BookmarkSidebarSection.swift:72-93`.

### Sidebar Browsers section visibility (UIX-11)

- **D-07**: Browsers section renders when `!browsers.isEmpty || !visibleBookmarks.isEmpty`. Header label stays `"Browsers"` in all cases — no dynamic relabeling.
- **D-08**: 0 tabs + ≥1 bookmark: Browsers header renders, no `LocationBrowserRow` rows, then the Bookmarks sub-section directly underneath.
- **D-09**: ≥1 tab + 0 bookmarks: Browsers header renders, tab rows render, the Bookmarks sub-section is NOT rendered at all (hide-when-empty applies recursively to the sub-section — consistent with UIX-23's no-empty-placeholders spirit).
- **D-10**: Both present: tab rows first, Bookmarks sub-section below. Tabs are ephemeral/live; bookmarks are persistent storage — reading order matches.

### Overview hide-when-empty + empty hero (UIX-14)

- **D-11**: `ProjectOverviewView.bookmarksSection` (at `:346-353`) and `bookmarksContent` (`:355-428`) are deleted as a top-level section. Their content migrates into the Browsers card's content block. The body call to `bookmarksSection` at `:84` is removed.
- **D-12**: Overview hero appears when **every non-Todos source is empty**:
  ```
  terminalSessions.isEmpty
  && browserTabs.isEmpty
  && documentTabs.isEmpty
  && projectBrowserBookmarks.isEmpty
  && projectBookmarks.isEmpty
  ```
  Todos are **not** factored in — the Todos section always renders at top (primary capture surface), even in the "truly empty" state. The hero sits below Todos when triggered.
- **D-13**: Hero treatment: centered VStack with an SF Symbol (Claude's discretion on glyph — suggest `square.grid.2x2` or `plus.circle`), headline ("No content yet" or similar — Claude's discretion), subheadline copy from D-14. **No embedded `+` button inside the hero** — preserves Phase 10's "exactly two `+` menus" invariant (sidebar bottom + overview header). The existing overview-header `+` (`UnifiedAddMenu` in `ProjectOverviewView.newButton`) is the user's action surface.
- **D-14**: Hero subheadline copy (verbatim): **"Press + to add your first Scratch Pad, Browser, Bookmark, or Location."**
- **D-15**: Delete inline empty-state rows:
  - `ProjectOverviewView.swift:358-367` — "No bookmarks yet. Star a page or import from another browser." (migrates out with the whole `bookmarksContent` refactor).
  - `ProjectOverviewView.swift:509-518` — "No locations added yet. Add a folder to get started." Replace the empty branch of `locationsSection` with nothing — the whole section disappears when empty.
  No section ever renders with an empty-state placeholder row after Phase 11.

### Overview Browsers card nesting (UIX-15)

- **D-16**: The standalone Bookmarks card is **deleted**; its content lives inside the Browsers `CollapsibleVStackSection` at `ProjectOverviewView.swift:432-458`. One card on the overview for browser-related content; two chevrons inside it. "Truly nested" visual — not stacked-with-indent, not adjacent-equal-weight.
- **D-17**: Inside the Browsers card content, render: (a) the existing `LazyVGrid` of browser tab cards **when tabs exist**, then (b) a nested `CollapsibleVStackSection` (or equivalent chevron + content block) titled "Bookmarks" **when bookmarks exist**, containing the migrated bookmarks `LazyVGrid` (from old `bookmarksContent`). Either subsection can be absent.
- **D-18**: 0 tabs + ≥1 bookmark: Browsers card renders, no tab grid, Bookmarks sub-section directly. Header stays "Browsers". Mirrors sidebar D-08.
- **D-19**: ≥1 tab + 0 bookmarks: Browsers card renders with just the tab grid. No Bookmarks sub-header. Mirrors sidebar D-09.
- **D-20**: Browsers card visibility condition (new): `!browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty`. Replaces the current condition at `ProjectOverviewView.swift:82` (`if !browserTabs.isEmpty { browsersSection }`).
- **D-21**: Nested Bookmarks sub-section expansion key: `overview.browsers.bookmarks.expanded.{projectID}` — matches the per-project pattern used by `overview.bookmarks.expanded.{projectID}`, but lives nested under browsers. The outer Browsers key `overview.browsers.expanded.{projectID}` is unchanged.

### Delete-last-item behavior (Success Criteria #4)

- **D-22**: Section disappearance on delete-last-item is automatic via `@Query` reactivity + the `if !empty` guards from D-01/D-07/D-11/D-20. **No animated transition** — instant state swap per user preference (memory: `feedback_no_slide_transitions.md`). Explicitly do NOT wrap the appearance/disappearance in `withAnimation { }`; the existing chevron-toggle animations at `SidebarSectionHeader.swift:19` and `CollapsibleSection.swift:35` stay, but section show/hide is instant.

### Claude's Discretion

- Exact SF Symbol for the overview hero (options: `square.grid.2x2`, `plus.circle`, `tray`, `square.dashed`).
- Exact hero copy for the headline above the subheadline (e.g., "No content yet", "Nothing here yet", or omit headline entirely — just subheadline + icon).
- Hero vertical spacing above/below, icon size, and font weights — match the rest of the overview's dense-utility voice.
- Whether `BrowserSessionsSection` owns the `@Query<BrowserBookmark>` + `@Query<BrowserBookmarkFolder>` directly, or whether a small helper view (`NestedBookmarkSubSection`) is extracted. Either keeps `BrowserSessionsSection` under ~80 lines (per CLAUDE.md).
- Whether `BookmarkSidebarSection.swift` is deleted outright or renamed/relocated as a helper — if the helper view ends up in `wrangle/Browser/Bookmarks/`, that's fine.
- Whether to use `CollapsibleVStackSection` (the existing overview component) for the nested overview Bookmarks, or a lighter inline chevron + VStack — existing component is recommended for consistency but planner can lighten it.
- Indent (if any) for the nested Bookmarks sub-section inside Browsers on the overview — suggest none; the chevron alone signals hierarchy.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements
- `.planning/REQUIREMENTS.md` §UIX — UIX-10 through UIX-15 are the six requirements this phase must satisfy.
- `.planning/ROADMAP.md` §Phase 11 — Goal, Success Criteria (5 rows), Plans (2 plans expected: 11-01 sidebar, 11-02 overview).

### Prior-phase decisions that flow through
- `.planning/phases/10-unified-creation-pattern/10-CONTEXT.md` — Phase 10 established `UnifiedAddMenu` as the sole creation surface (two `+` menus only) and stripped per-section chrome; `SidebarSectionHeader` is already nav-only with the `accessory` param dropped.

### Code surfaces the phase must touch

**Sidebar**
- `Wrangle/Sidebar/SidebarView.swift:46-47` — current `BrowserSessionsSection()` rendering site. This section absorbs the nested Bookmarks sub-section.
- `Wrangle/Sidebar/SidebarView.swift:63` — current top-level `BookmarkSidebarSection()` call. Remove.
- `Wrangle/Sidebar/SidebarView.swift:66-83` — current Locations `Section { … }` (always renders). Wrap in `if !projectLocations.isEmpty`.
- `Wrangle/Sidebar/SidebarView.swift:526-544` — `BrowserSessionsSection` implementation. Extend to render nested Bookmarks sub-section under the existing browser-rows ForEach.
- `Wrangle/Sidebar/SidebarView.swift:528` — existing `@AppStorage("sidebar.browsers.expanded")`. Unchanged.
- `Wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift` — source of all bookmark-rendering logic (`BookmarkFolderNode`, `BookmarkRow`, `visibleBookmarks`/`visibleFolders` filters, `BookmarkFolderDropDelegate`). Extract what's needed into the nested sub-section; delete the top-level `Section { … }` wrapper + bespoke header at `:29-61`.

**Project Overview**
- `Wrangle/Features/Dashboard/ProjectOverviewView.swift:76-88` — `body` ScrollView VStack. Add the empty-hero branch (D-12, D-13). Update the `browsersSection` visibility condition (D-20). Remove the `bookmarksSection` call at `:84`.
- `Wrangle/Features/Dashboard/ProjectOverviewView.swift:82` — `if !browserTabs.isEmpty { browsersSection }` — replace with `if !browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty { browsersSection }`.
- `Wrangle/Features/Dashboard/ProjectOverviewView.swift:346-428` — `bookmarksSection` + `bookmarksContent`. Content (`LazyVGrid` + card rendering) migrates into `browsersSection`; everything else deletes.
- `Wrangle/Features/Dashboard/ProjectOverviewView.swift:432-458` — `browsersSection`. Restructure content block: existing tab grid (wrap in `if !browserTabs.isEmpty`), then nested Bookmarks sub-section (wrap in `if !projectBrowserBookmarks.isEmpty`).
- `Wrangle/Features/Dashboard/ProjectOverviewView.swift:504-527` — `locationsSection`. Delete the `if projectBookmarks.isEmpty { inline empty row }` branch at `:509-518`; keep only the populated-grid branch. Wrap the section call at body `:85` in `if !projectBookmarks.isEmpty`.

### Code surfaces to read but NOT touch
- `Wrangle/Components/SidebarSectionHeader.swift` — already nav-only after Phase 10. Reusable for the nested Bookmarks sub-header (D-04 requires a custom header to get the count-only-when-collapsed behavior; `SidebarSectionHeader` as-is doesn't express that variant, so the sub-header may need to be a small inline chevron + label — or a variant of `SidebarSectionHeader` if it's cleaner). Decision: planner keeps `SidebarSectionHeader` unchanged (Phase 12 handles canonicalization); the count-when-collapsed sub-header is an inline structure local to `BrowserSessionsSection`.
- `Wrangle/Components/CollapsibleSection.swift` — `CollapsibleVStackSection`. Reused for the overview nested Bookmarks sub-section. No changes expected.
- `Wrangle/Browser/Bookmarks/BookmarkEditSheet.swift` — unchanged; the nested sub-section preserves the existing `sheet(item: $editing)` flow.
- `Wrangle/Browser/Bookmarks/BookmarkStore.swift` — unchanged.
- `Wrangle/App/AppState.swift:724` — `projectBrowserSessions` computed property. Used as-is.
- `Wrangle/Components/CollapsibleSection.swift` — `CollapsibleVStackSection`. Stays; used for both Browsers outer and nested Bookmarks on overview.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BrowserSessionsSection` (`SidebarView.swift:526-544`) — already has the hide-when-empty pattern (`if !browsers.isEmpty { Section { … } }`). Extends cleanly: add `@Query<BrowserBookmark>` + visibleBookmarks filter + a nested chevron-button row + if-expanded ForEach of unfiled bookmarks then `BookmarkFolderNode`s.
- `BookmarkFolderNode` (`BookmarkSidebarSection.swift:114-214`) — recursive folder rendering, already handles context-menu + drop delegate. Reusable unchanged inside the nested sub-section.
- `BookmarkRow` (`BookmarkSidebarSection.swift:248-325`) — single-bookmark row with favicon, context menu, delete-key handler. Reusable unchanged.
- `BookmarkFolderDropDelegate` (`BookmarkSidebarSection.swift:220-244`) — drag-to-reparent support. Move with the nested sub-section; keep same behavior.
- `CollapsibleVStackSection` (`Components/CollapsibleSection.swift`) — overview's section wrapper. Reused for the outer Browsers card and the nested Bookmarks sub-section inside it. Works with nested calls (no re-entrance issues; each has its own `@AppStorage` key).
- `visibleBookmarks` / `visibleFolders` computed properties (`BookmarkSidebarSection.swift:19-27`) — project-scope filter. Lift-and-shift into `BrowserSessionsSection` or a shared helper.

### Established Patterns
- **Hide-when-empty**: `if !xs.isEmpty { Section { … } header: { … } }` — applied to Browsers (`:532`), Other Sessions (`:554`), Scratch Pads (`:49`). Extend to Locations (new).
- **`@AppStorage("sidebar.<section>.expanded")`** — already the convention (`sidebar.locations.expanded` at `:18`, `sidebar.scratchPads.expanded` at `:19`, `sidebar.browsers.expanded` at `:528`, `sidebar.otherSessions.expanded` at `:550`, `sidebar.bookmarks.expanded` at `BookmarkSidebarSection.swift:17`). New key: `sidebar.browsers.bookmarks.expanded`.
- **`overview.<section>.expanded.{projectID}`** — already the convention for overview (`:193, :264, :347, :433, :463, :507`). New key: `overview.browsers.bookmarks.expanded.{projectID}`.
- **`@Query` + in-view filtering** for project-scoped collections — the app does `@Query` then filters by `projectID` in a computed property, rather than `@Query(filter:)`. Follow this pattern for the nested Bookmarks sub-section to stay consistent.

### Integration Points
- `BrowserSessionsSection` becomes the home for both browser tabs (existing) and nested browser bookmarks (new). Currently 19 lines; adding the nested sub-section brings it to ~40-50 lines — still under CLAUDE.md's 80-line budget.
- The overview `browsersSection` currently just renders tab cards; gains a nested Bookmarks block. Combined view stays under 80 lines if the bookmarks grid is factored into a small `private var bookmarksGrid` helper.
- `ProjectOverviewView.body` gets one new branch (empty hero) and one deleted call (`bookmarksSection`). Net: same size.

### Code Hotspots / Complexity
- `BookmarkSidebarSection.swift` is 343 lines covering: Section wrapper, custom header with count badge, content dispatcher (unfiled + folders), `BookmarkFolderNode`, `BookmarkFolderDropDelegate`, `BookmarkRow`, `DeleteKeyHandler`. Phase 11 removes the Section-wrapper + custom-header portion (`:29-61`) and relocates the content-rendering helpers. Planner decides whether to delete the file entirely (moving all helpers into `BrowserSessionsSection` or a new `NestedBookmarkSection.swift`) or keep the file and just change what the exposed `body` returns. Recommend: rename-and-repurpose into a private struct used inside `BrowserSessionsSection` — keeps helpers co-located without polluting SidebarView.swift.
- The `@Query(sort: \BrowserBookmark.dateAdded, order: .reverse)` at `BookmarkSidebarSection.swift:14` materializes all bookmarks project-wide then filters. If `BrowserSessionsSection` takes it over, the query moves with it. Alternative: hoist to SidebarView and pass down — but that adds prop-drilling. Keep the query local to the nested component.

</code_context>

<specifics>
## Specific Ideas

- **Count-only-when-collapsed** for the nested Bookmarks sub-header is a specific user design touch: `▸ Bookmarks (5)` when collapsed, `▾ Bookmarks` when expanded. This is non-standard; preserve exactly. Not a generic `SidebarSectionHeader` variant — implement inline inside `BrowserSessionsSection`. Phase 12's canonicalization pass can later decide if this belongs on the shared component.
- **Todos stays at top even when the hero fires** — user explicitly re-confirmed this. The Todos VStack is the primary capture surface for a brand-new project; the empty-hero sits below it. Keep the current `todosSection` call at `ProjectOverviewView.swift:80`.
- **No embedded `+` in the hero** — the overview-header `+` (UnifiedAddMenu) is the user's action surface. Keeps the "exactly two `+` menus" invariant locked in Phase 10 (D-01 of `10-CONTEXT.md`).
- **"Truly nested" not "stacked adjacent"** for the overview Bookmarks card — the bookmarks content goes INSIDE the Browsers `CollapsibleVStackSection` content block, not after it. One card, two chevrons.
- **Instant state swap on delete-last-item** — user preference memory `feedback_no_slide_transitions`. Do not add `.animation(.smooth, value: xs.count)` or `withAnimation { … }` to the show/hide branches.

</specifics>

<deferred>
## Deferred Ideas

- **Canonical `SidebarSectionHeader` styling parity across all section types** (including count badges) → Phase 12 (UIX-20). Phase 11's nested Bookmarks sub-header uses a bespoke inline structure; Phase 12 decides whether to promote it.
- **Scratch Pad row rename (Return) / delete (Delete key) parity with Bookmarks rows** → Phase 12 (UIX-21).
- **Full `@AppStorage` expansion-state key audit** (asserting every collapsible section follows `sidebar.<section>.expanded` / `overview.<section>.expanded.<projectID>`) → Phase 12 (UIX-22). Phase 11 introduces two new keys that already match the convention.
- **Assert-no-residual-empty-state-rows across the codebase** → Phase 12 (UIX-23). Phase 11 removes the two known ones (overview Bookmarks + Locations inline empty rows); Phase 12 verifies none remain.
- **Drag-to-reorder browser bookmarks within the nested sub-section** → out of scope for v1.2. Existing `BookmarkFolderDropDelegate` handles folder re-parenting and is preserved unchanged.
- **Animated section appearance/disappearance** → not in scope; conflicts with user preference (`feedback_no_slide_transitions`).
- **Promoting the count-only-when-collapsed variant to `SidebarSectionHeader`** → Phase 12 candidate if the team wants count badges on other sections.

</deferred>

---

*Phase: 11-hide-when-empty-bookmarks-nested-under-browsers*
*Context gathered: 2026-04-19*
