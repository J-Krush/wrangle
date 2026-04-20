# Phase 11: Hide-When-Empty + Bookmarks Nested Under Browsers — Research

**Researched:** 2026-04-19
**Domain:** SwiftUI structural refactor (macOS 15+, native)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Sidebar hide-when-empty**
- **D-01**: Wrap the Locations `Section { … }` at `SidebarView.swift:66-83` in `if !projectLocations.isEmpty { … }`. Source the count via either a `@Query` filter on `BookmarkedDirectory` + active `selectedProjectID`, or an inlined helper mirroring `ProjectOverviewView.projectBookmarks`. (Scratch Pads at `:49-61`, Browsers at `:530-543`, and Other Sessions at `:548-566` already use this pattern — extend it to Locations for parity.)
- **D-02**: Remove the top-level `BookmarkSidebarSection()` call at `SidebarView.swift:63`. The file `Wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift` is either deleted or refactored into a small private helper view used inside `BrowserSessionsSection`. Planner picks deletion vs refactor; the Section-wrapper + bespoke header at `BookmarkSidebarSection.swift:29-61` is what gets torn out either way.

**Sidebar nesting structure**
- **D-03**: Inside `BrowserSessionsSection` (currently at `SidebarView.swift:526-544`), after the `ForEach(browsers) { LocationBrowserRow(session: $0) }`, render a nested Bookmarks sub-section: a chevron-button header row, then if expanded: unfiled bookmarks inline (no wrapper folder), then top-level `BookmarkFolderNode` rows. Reuse `BookmarkFolderNode` + `BookmarkRow` from `BookmarkSidebarSection.swift` unchanged.
- **D-04**: The Bookmarks sub-header shows the count **only when collapsed**. Expanded: `▾ Bookmarks`. Collapsed: `▸ Bookmarks (5)`. Count style: `.font(.system(size: 10))`, `.foregroundStyle(.tertiary)` (mirrors the current BookmarkSidebarSection header count styling at `BookmarkSidebarSection.swift:46-49`).
- **D-05**: Two independent `@AppStorage` keys:
  - `sidebar.browsers.expanded` — already exists at `SidebarView.swift:528`; controls the outer Browsers chevron.
  - `sidebar.browsers.bookmarks.expanded` — new; controls the nested Bookmarks chevron.
  User can collapse Bookmarks while keeping Browsers expanded and vice versa. Matches the `sidebar.<section>.expanded` naming convention locked for Phase 12 (UIX-22).
- **D-06**: Unfiled bookmarks render inline at the top of the Bookmarks sub-section — no synthetic "Unfiled" folder wrapper. Matches current ordering at `BookmarkSidebarSection.swift:72-93`.

**Sidebar Browsers section visibility (UIX-11)**
- **D-07**: Browsers section renders when `!browsers.isEmpty || !visibleBookmarks.isEmpty`. Header label stays `"Browsers"` in all cases — no dynamic relabeling.
- **D-08**: 0 tabs + ≥1 bookmark: Browsers header renders, no `LocationBrowserRow` rows, then the Bookmarks sub-section directly underneath.
- **D-09**: ≥1 tab + 0 bookmarks: Browsers header renders, tab rows render, the Bookmarks sub-section is NOT rendered at all (hide-when-empty applies recursively to the sub-section — consistent with UIX-23's no-empty-placeholders spirit).
- **D-10**: Both present: tab rows first, Bookmarks sub-section below. Tabs are ephemeral/live; bookmarks are persistent storage — reading order matches.

**Overview hide-when-empty + empty hero (UIX-14)**
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
- **D-13**: Hero treatment: centered VStack with an SF Symbol (Claude's discretion on glyph — the UI-SPEC resolves this to `square.grid.2x2`), headline (UI-SPEC locks "Nothing here yet"), subheadline copy from D-14. **No embedded `+` button inside the hero** — preserves Phase 10's "exactly two `+` menus" invariant.
- **D-14**: Hero subheadline copy (verbatim): **"Press + to add your first Scratch Pad, Browser, Bookmark, or Location."**
- **D-15**: Delete inline empty-state rows:
  - `ProjectOverviewView.swift:358-367` — "No bookmarks yet…" (migrates out with the whole `bookmarksContent` refactor).
  - `ProjectOverviewView.swift:509-518` — "No locations added yet…" Replace the empty branch of `locationsSection` with nothing — the whole section disappears when empty.
  No section ever renders with an empty-state placeholder row after Phase 11.

**Overview Browsers card nesting (UIX-15)**
- **D-16**: The standalone Bookmarks card is **deleted**; its content lives inside the Browsers `CollapsibleVStackSection` at `ProjectOverviewView.swift:432-458`. One card on the overview for browser-related content; two chevrons inside it.
- **D-17**: Inside the Browsers card content, render: (a) the existing `LazyVGrid` of browser tab cards **when tabs exist**, then (b) a nested `CollapsibleVStackSection` titled "Bookmarks" **when bookmarks exist**, containing the migrated bookmarks `LazyVGrid`. Either subsection can be absent.
- **D-18**: 0 tabs + ≥1 bookmark: Browsers card renders, no tab grid, Bookmarks sub-section directly. Header stays "Browsers". Mirrors sidebar D-08.
- **D-19**: ≥1 tab + 0 bookmarks: Browsers card renders with just the tab grid. No Bookmarks sub-header. Mirrors sidebar D-09.
- **D-20**: Browsers card visibility condition (new): `!browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty`. Replaces the current condition at `ProjectOverviewView.swift:82`.
- **D-21**: Nested Bookmarks sub-section expansion key: `overview.browsers.bookmarks.expanded.{projectID}` — matches the per-project pattern. The outer Browsers key `overview.browsers.expanded.{projectID}` is unchanged.

**Delete-last-item behavior (Success Criteria #4)**
- **D-22**: Section disappearance on delete-last-item is automatic via `@Query` reactivity + the `if !empty` guards from D-01/D-07/D-11/D-20. **No animated transition** — instant state swap per user preference (memory: `feedback_no_slide_transitions.md`). Explicitly do NOT wrap the appearance/disappearance in `withAnimation { }`; the existing chevron-toggle animations at `SidebarSectionHeader.swift:19` and `CollapsibleSection.swift:35` stay, but section show/hide is instant.

### Claude's Discretion

- Exact SF Symbol for the overview hero — the UI-SPEC resolves this to `square.grid.2x2` (mirrors the sidebar Overview row glyph at `SidebarView.swift:309`).
- Exact hero headline — UI-SPEC resolves to "Nothing here yet".
- Hero vertical spacing — UI-SPEC resolves to `VStack(spacing: 12)` + `.padding(.vertical, 48)`.
- Whether `BrowserSessionsSection` owns the `@Query<BrowserBookmark>` + `@Query<BrowserBookmarkFolder>` directly, or whether a small helper view (`NestedBookmarkSubSection`) is extracted. Either keeps `BrowserSessionsSection` under ~80 lines (per CLAUDE.md). **This research recommends extraction — see Architecture Patterns §Pattern 1.**
- Whether `BookmarkSidebarSection.swift` is deleted outright or renamed/relocated as a helper. **This research recommends rename-and-repurpose — see Architecture Patterns §Pattern 2.**
- Whether to use `CollapsibleVStackSection` for the nested overview Bookmarks, or a lighter inline chevron + VStack. **This research recommends reusing `CollapsibleVStackSection` unchanged — see Architecture Patterns §Pattern 3.**
- Indent for the nested Bookmarks sub-section inside Browsers on the overview — **UI-SPEC resolves to none (chevron signals hierarchy).**

### Deferred Ideas (OUT OF SCOPE)

- Canonical `SidebarSectionHeader` styling parity with count badges (UIX-20 → Phase 12). Phase 11's nested Bookmarks sub-header uses a bespoke inline structure; Phase 12 decides whether to promote it.
- Scratch Pad row rename (Return) / delete (Delete key) parity with Bookmarks rows (UIX-21 → Phase 12).
- Full `@AppStorage` expansion-state key audit (UIX-22 → Phase 12). Phase 11 introduces two new keys that already match the convention.
- Assert-no-residual-empty-state-rows across the codebase (UIX-23 → Phase 12). Phase 11 removes the two known ones (overview Bookmarks + Locations inline empty rows); Phase 12 verifies none remain.
- Drag-to-reorder browser bookmarks within the nested sub-section — out of scope for v1.2. Existing `BookmarkFolderDropDelegate` handles folder re-parenting and is preserved unchanged.
- Animated section appearance/disappearance — not in scope; conflicts with user preference (`feedback_no_slide_transitions`).
- Promoting the count-only-when-collapsed variant to `SidebarSectionHeader` — Phase 12 candidate.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UIX-10 | Sidebar Scratch Pads section renders only when the active project has ≥1 scratch pad. | Already implemented (`SidebarView.swift:49`). Research confirms the `if !xs.isEmpty { Section { … } }` pattern is the canonical approach. No change required in this phase — Scratch Pads is the template the other sidebar sections extend. |
| UIX-11 | Sidebar Browsers section renders only when the active project has ≥1 browser tab OR ≥1 bookmark. | Extends existing pattern at `SidebarView.swift:532`. D-07 guard: `!browsers.isEmpty \|\| !visibleBookmarks.isEmpty`. Research confirms `BrowserSessionsSection` can absorb a second `@Query` cleanly (see Pattern 1). |
| UIX-12 | Sidebar Locations section renders only when the active project has ≥1 location. | Currently always-renders at `SidebarView.swift:66-83`. Wrap in `if !projectLocations.isEmpty` guard, sourcing `projectLocations` either via a new in-view computed property (preferred — matches `ProjectOverviewView.projectBookmarks` pattern) or a dedicated `@Query(filter:)`. Research recommends the in-view computed property for consistency (see Architecture Patterns §Query Scoping). |
| UIX-13 | Top-level Bookmarks section removed; renders nested under Browsers only when ≥1 bookmark exists. | Delete call at `SidebarView.swift:63`. Absorb the bookmark-rendering logic into `BrowserSessionsSection` via a new `NestedBookmarkSubSection` helper view (recommended) that owns the `@Query<BrowserBookmark>` + `@Query<BrowserBookmarkFolder>` and renders the chevron sub-header + content when `!visibleBookmarks.isEmpty`. |
| UIX-14 | Project Overview hides empty section cards entirely; single overview-level empty state replaces per-section empty rows. | Wrap each section call in `if !xs.isEmpty`, delete inline empty rows at `:358-367` and `:509-518`, add empty hero branch in body after Todos. Hero trigger: exact boolean from D-12. Hero centered via `.frame(maxWidth: .infinity)` inside an `.alignment(.leading)` VStack (see Pattern 4). |
| UIX-15 | Project Overview Bookmarks card visually nested inside Browsers card. | Delete standalone `bookmarksSection` + `bookmarksContent`; migrate populated grid into `browsersSection` content block wrapped in a second `CollapsibleVStackSection`. Research confirms `CollapsibleVStackSection` nests cleanly (see Pattern 3). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Directives extracted from `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/CLAUDE.md`. Treat as locked — research recommendations never contradict these.

- **Swift version:** Swift 5.9+
- **Platform minimum:** macOS 15+ (Sequoia). (Also compatible with macOS 14 per "SwiftUI App lifecycle" doc note, but Phase 11 targets the already-locked 15+ baseline.)
- **UI framework:** SwiftUI only (no AppKit views for new work this phase).
- **Concurrency:** Use `async/await`, `@Observable`, `@MainActor`. Every `@Observable` class MUST have `@MainActor`.
- **State:** `@State` must be `private`. Use `@Environment(AppState.self)` for DI. Use `@Bindable` for two-way bindings.
- **Architecture:** MVVM with `@Observable` + `@MainActor`.
- **View composition:**
  - Use `Button` over `onTapGesture` — keyboard nav, a11y, press feedback for free.
  - Do NOT put `onTapGesture` on `DisclosureGroup` labels — conflicts with expand/collapse.
  - Use `.clipShape(RoundedRectangle(…))` over deprecated `.cornerRadius()`.
  - Keep views under ~80 lines — extract subviews beyond that.
- **Error handling:** `Result` or `throws` — never force unwrap except static regex `try!`.
- **Animations / concurrency gotchas:**
  - Never sync file I/O on main thread or in computed properties.
  - Task-based debouncing (not `DispatchWorkItem`).
  - `MainActor.run` / `Task { @MainActor in }` (not `DispatchQueue.main.async`).
- **Naming:** Name files after their primary type.
- **Comments:** Explain *why*, not *what*.
- **Testing targets:** Unit tests for logic-bearing types (MarkdownParser, TokenCounter, SecurityScopedBookmark patterns). UI rendering verified via preview providers + manual UAT.
- **Do NOT use document-based app template** — file management is manual.

All Phase 11 recommendations comply with these directives. No deviations proposed.

## Summary

Phase 11 is a **pure SwiftUI structural refactor**. No new dependencies, no new persistence primitives, no new concurrency surface. The work is: (a) wrap four existing sections in `if !empty` guards, (b) delete one top-level section and fold its guts into another, (c) delete two inline empty-state placeholders, (d) add one centered empty-hero view that fires on a compound boolean, (e) register two new `@AppStorage` keys that match the existing naming convention. Every building block needed — `@Query`, `@AppStorage`, `CollapsibleVStackSection`, `SidebarSectionHeader`, `Section`, `Button` — already exists in the codebase and is unchanged.

The interesting technical questions are all _organizational_, not _framework_ questions: where the nested bookmark logic lives (new helper struct vs inline), whether `BookmarkSidebarSection.swift` is deleted outright or renamed, and how to center a VStack horizontally in a top-leading `ScrollView` without disturbing Todos' alignment. Research resolves each with a codebase-consistent recommendation. One non-obvious SwiftUI detail surfaced: `@Query` updates inherit the current transaction's animation, so an implicit `.animation()` or enclosing `withAnimation` can animate section show/hide — D-22 forbids this, so the recommendation is to simply **not wrap anything** in an animation; SwiftUI's default transaction has `animation: nil` and state-change re-renders are instant by default.

**Primary recommendation:** Two plans — **11-01 sidebar** (extract `NestedBookmarkSubSection` helper inside `BrowserSessionsSection`, repurpose `BookmarkSidebarSection.swift` as that helper's new home, wrap Locations in hide-when-empty guard, delete top-level `BookmarkSidebarSection()` call) and **11-02 overview** (migrate populated bookmarks grid into `browsersSection` via nested `CollapsibleVStackSection`, delete standalone `bookmarksSection` + `bookmarksContent`, add compound-boolean empty-hero branch after Todos, delete inline empty rows).

## Architectural Responsibility Map

Phase 11 is single-tier. Every capability lives in the SwiftUI view tree; none of it crosses into persistence (SwiftData models are unchanged), networking, or platform APIs beyond `@AppStorage` (UserDefaults).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Section visibility decisions | SwiftUI View (presentation) | — | Pure rendering logic; `if !xs.isEmpty` guards sit inside `body`. SwiftData is unchanged; `@Query` already publishes reactive arrays. |
| Nested sub-section chrome (chevron + label + count) | SwiftUI View (presentation) | — | Inline `HStack(Button { … } )` — no shared component update needed. |
| Expansion state persistence | UserDefaults via `@AppStorage` | — | Two new keys follow existing `sidebar.<section>.expanded` / `overview.<section>.expanded.<projectID>` convention. Additive — no migration. |
| Bookmark rendering (favicon, row, context menu, drop target, delete-key) | SwiftUI View (presentation) | SwiftData (read/write) | Reuses `BookmarkRow`, `BookmarkFolderNode`, `BookmarkFolderDropDelegate` unchanged. Writes route through existing `BookmarkStore`. |
| Empty-hero rendering | SwiftUI View (presentation) | — | Static VStack with SF Symbol + text; no state, no interaction. |
| Delete-last-item section disappearance | SwiftUI View (presentation) | SwiftData (@Query reactivity) | `@Query` publishes updates on `modelContext.save()`; the `if !empty` guard re-evaluates on the next body pass. |

**Why this matters for the planner:** This phase is almost entirely view-layer work. No plan task should touch models, stores, or AppState. If a task description starts reaching into `AppState` or `BookmarkStore`, it's out-of-scope creep.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 15 SDK | Declarative view system | Locked by CLAUDE.md + shipped throughout project |
| SwiftData | macOS 15 SDK | `@Query` reactive data source for `BrowserBookmark`, `BrowserBookmarkFolder`, `BookmarkedDirectory` | Locked — all models and queries already use it |
| Foundation / AppKit | macOS 15 SDK | `UserDefaults` backing for `@AppStorage`, `NSPasteboard` for bookmark drop, `NSImage` for favicon | Already used across the app |

### Supporting

| Symbol | Purpose | When to Use |
|--------|---------|-------------|
| `@Query(sort:order:)` + in-view computed filter | Project-scoped bookmark list | Follow existing `BookmarkSidebarSection.swift:19-27` pattern — `@Query` on all rows, then filter by `$0.projectID == projectID \|\| $0.projectID == nil` in a computed property. Needed because Global bookmarks use `projectID == nil` and `#Predicate` OR logic is clunky across optional types |
| `@Query(filter: #Predicate<T>)` (via explicit init) | Single-project-scoped deterministic filter | Acceptable for `BookmarkedDirectory.projectID == projectID` (no Global case). Already used at `BookmarkListView.swift:33-38`. For **Locations `projectLocations` count** only, planner can pick either — recommend in-view computed to match `ProjectOverviewView.projectBookmarks:52-54` |
| `@AppStorage("key")` | Sidebar expansion state | New keys: `sidebar.browsers.bookmarks.expanded` (Bool, default `true`) and `overview.browsers.bookmarks.expanded.\(projectID)` (Bool, default `true`). Names already locked in D-05 / D-21 |
| `CollapsibleVStackSection(_:storageKey:content:)` | Overview collapsible card + nested sub-section | Reused unchanged; nests cleanly because each invocation holds its own `@AppStorage`. No new parameter needed |
| `SidebarSectionHeader(title:isExpanded:)` | Outer sidebar section headers | Unchanged — used by outer Browsers section. NOT used for the nested Bookmarks sub-header (the count-only-when-collapsed behavior isn't a generic variant — Phase 12 decides canonicalization) |
| SF Symbols | `square.grid.2x2`, `chevron.right`, `globe`, `folder.fill`, `star` | All Apple-signed system assets; the overview-hero glyph `square.grid.2x2` is already in use at `SidebarView.swift:309` (overview row icon) |

### Alternatives Considered

| Instead of | Could Use | Why Rejected |
|------------|-----------|--------------|
| `SidebarSectionHeader` for the nested Bookmarks sub-header | Inline `HStack` with chevron-Button + Text + conditional count | **REJECTED — use inline.** `SidebarSectionHeader` has no `showCountWhenCollapsed` parameter. Adding one would couple shared component to a per-caller feature during Phase 11 when Phase 12 owns canonicalization (UIX-20). Inline structure inside `BrowserSessionsSection` is the temporary-but-correct path |
| Deleting `BookmarkSidebarSection.swift` entirely | Repurpose file into `NestedBookmarkSubSection` | **REJECTED — keep and rename (or keep name, change contents).** The file already houses `BookmarkFolderNode`, `BookmarkFolderDropDelegate`, `BookmarkRow`, `DeleteKeyHandler` — four private helpers that are reused verbatim. Deleting means relocating all of them; repurposing keeps the co-location and preserves git history for those helpers. Lower churn, clearer diff |
| `@Query(filter: #Predicate<BrowserBookmark>)` for project scope | Current pattern: `@Query` all, filter in computed property | **NOT RECOMMENDED for BrowserBookmark.** Global bookmarks have `projectID == nil`; `#Predicate` expressing `$0.projectID == projectID \|\| $0.projectID == nil` with an optional comparison is verbose and has edge cases. The codebase consistently filters in-view for bookmarks — keep consistency |
| Wrapping empty-hero in `ContentUnavailableView` | Apple's built-in empty-state primitive | **REJECTED.** `ContentUnavailableView` on macOS 15+ is a valid choice, but the UI-SPEC locks exact copy ("Nothing here yet" + verbatim subheadline) and exact icon (`square.grid.2x2` at 48pt) and exact spacing (`VStack spacing: 12`, `.padding(.vertical, 48)`). A plain `VStack` gives pixel control; `ContentUnavailableView` imposes its own type/spacing defaults that would conflict with the locked spec |
| `withAnimation { … }` around delete-last-item state changes | No animation wrapper | **REJECTED — explicitly by D-22** and user memory `feedback_no_slide_transitions.md`. SwiftUI default transaction is `animation: nil`, so simply omitting `withAnimation` gives instant swaps |

**Installation:** None. All symbols ship in the macOS 15 SDK and are already imported.

**Version verification:** `xcodebuild -version` → Xcode 16+ targets macOS 15 SDK. `@AppStorage`, `@Query`, `Section { … } header:`, and `CollapsibleVStackSection` have shipped and compiled in this project since Phase 5 (per STATE.md). [VERIFIED: `Wrangle.xcodeproj` exists at `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/Wrangle.xcodeproj`; project compiled green per STATE.md `2026-04-20 Phase 10 Plan 10-02 complete (per-section chrome stripped), build green`.]

## Architecture Patterns

### System Architecture Diagram

Phase 11 is UI-only — the "data flow" is tiny. This diagram shows how an end-user's state change (e.g., deleting the last bookmark) propagates to a section disappearing.

```
┌────────────────────────────────────────────────────────────────────────┐
│                         User action: delete last bookmark              │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    BookmarkRow.delete() ──► BookmarkStore.remove(bookmark)
                                                     │
                                                     ▼
                                       modelContext.delete(bookmark)
                                       try? modelContext.save()
                                                     │
                                                     ▼
                   SwiftData emits change notification to subscribers
                                                     │
                    ┌────────────────────────────────┼──────────────────────┐
                    ▼                                ▼                      ▼
          @Query allBookmarks           @Query allBookmarks          @Query allBookmarks
          (in NestedBookmarkSubSection) (in ProjectOverviewView)     (in URLSuggestionPopover)
                    │                                │                      │
                    ▼                                ▼                      ▼
        visibleBookmarks.isEmpty==true    projectBrowserBookmarks       bookmarks refreshed
                    │                       .isEmpty==true
                    ▼                                │
      Parent body re-evaluates:                     ▼
      `if !visibleBookmarks.isEmpty`    Body re-evaluates:
         → false → sub-section not       `if !browserTabs.isEmpty
         rendered this pass                  \|\| !projectBrowserBookmarks
                                            .isEmpty`
                                         → (depends on browserTabs)
                                         Also: D-12 hero trigger re-checked
```

**Key properties:**
1. Reactivity is automatic — no manual subscription, no manual `objectWillChange.send()`.
2. Re-render happens in the next SwiftUI body pass (within one frame under normal load).
3. No `withAnimation` is called anywhere in the delete path → default transaction has `animation: nil` → instant visual swap. This matches D-22.
4. `@Query` instances in separate views update independently; all three views get notified by the same SwiftData save.

### Recommended Project Structure

Minimal — the phase reuses existing folders. Possible new file:

```
Wrangle/
├── Sidebar/
│   └── SidebarView.swift                       # edit (body + BrowserSessionsSection)
├── Browser/
│   └── Bookmarks/
│       ├── BookmarkSidebarSection.swift        # RENAME to NestedBookmarkSubSection.swift
│       │                                       # (or keep name, repurpose body — planner discretion)
│       ├── BookmarkStore.swift                 # no change
│       ├── BookmarkEditSheet.swift             # no change
│       └── NewBookmarkSheet.swift              # no change
├── Components/
│   ├── SidebarSectionHeader.swift              # no change
│   └── CollapsibleSection.swift                # no change
└── Features/
    └── Dashboard/
        └── ProjectOverviewView.swift           # edit (body + browsersSection; delete bookmarksSection + bookmarksContent; edit locationsSection)
```

**Recommendation:** Rename `BookmarkSidebarSection.swift` → `NestedBookmarkSubSection.swift` (or inline file-local name change — Xcode project file will need updating either way). The new type is `struct NestedBookmarkSubSection: View` and renders **without** a `Section { … }` wrapper (the wrapper lives in the parent `BrowserSessionsSection`). Keeps helpers (`BookmarkFolderNode`, `BookmarkFolderDropDelegate`, `BookmarkRow`, `DeleteKeyHandler`) co-located in the same file. Low churn; preserves git blame.

### Pattern 1: Extract `NestedBookmarkSubSection` as a private struct

**What:** Inside `BrowserSessionsSection`, don't inline the nested bookmarks logic. Extract a helper view that owns its `@Query`s, `@AppStorage`, and sub-header button.

**When to use:** Phase 11, plan 11-01. `BrowserSessionsSection` currently 19 lines (`SidebarView.swift:526-544`); inline would push it to ~55-70 lines — still under CLAUDE.md's 80-line soft cap but mixes two concerns (outer Browsers chrome + nested Bookmarks chrome). Extracting keeps responsibilities clean.

**Example:**

```swift
// Source: Phase 11 research — based on existing BookmarkSidebarSection.swift:19-93 and BrowserSessionsSection at SidebarView.swift:526-544

private struct BrowserSessionsSection: View {
    @Environment(AppState.self) private var appState
    @AppStorage("sidebar.browsers.expanded") private var isExpanded: Bool = true

    var body: some View {
        let browsers = appState.projectBrowserSessions
        // D-07: render when browsers OR bookmarks present.
        // Bookmarks presence is checked inside NestedBookmarkSubSection; here we
        // need a parallel check so the OUTER section hides when BOTH are empty.
        // Recommendation: NestedBookmarkSubSection exposes a static helper OR
        // the Query is lifted here. Simpler path: lift the visibleBookmarks
        // computation to a shared place. See "Query Scoping Gotcha" below.
        if !browsers.isEmpty || appState.hasVisibleBookmarks {
            Section {
                if isExpanded {
                    ForEach(browsers) { LocationBrowserRow(session: $0) }
                    NestedBookmarkSubSection()   // renders nothing if no bookmarks (D-09)
                }
            } header: {
                SidebarSectionHeader(title: "Browsers", isExpanded: $isExpanded)
            }
        }
    }
}

private struct NestedBookmarkSubSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrowserBookmark.dateAdded, order: .reverse) private var allBookmarks: [BrowserBookmark]
    @Query(sort: \BrowserBookmarkFolder.displayOrder) private var allFolders: [BrowserBookmarkFolder]
    @State private var editing: BrowserBookmark?
    @AppStorage("sidebar.browsers.bookmarks.expanded") private var isExpanded: Bool = true   // D-05

    private var visibleBookmarks: [BrowserBookmark] {
        let pid = appState.selectedProjectID
        return allBookmarks.filter { $0.projectID == pid || $0.projectID == nil }
    }
    private var visibleFolders: [BrowserBookmarkFolder] {
        let pid = appState.selectedProjectID
        return allFolders.filter { $0.projectID == pid || $0.projectID == nil }
    }

    var body: some View {
        if !visibleBookmarks.isEmpty {                                    // D-09 / UIX-13
            // Sub-header: inline chevron + label + count-only-when-collapsed (D-04)
            HStack(spacing: 4) {
                Button {
                    withAnimation(.snappy(duration: 0.15)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        Text("Bookmarks")
                        if !isExpanded {
                            Text("\(visibleBookmarks.count)")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .onDrop(of: [.text], delegate: BookmarkFolderDropDelegate(
                targetFolderID: nil, modelContext: modelContext
            ))

            if isExpanded {
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        // D-06: unfiled bookmarks inline, then top-level folders.
        // Identical logic to the current BookmarkSidebarSection.content at :67-93 — lift-and-shift.
        let bookmarksByFolder = Dictionary(grouping: visibleBookmarks) { $0.folderID }
        let childFoldersByParent = Dictionary(grouping: visibleFolders) { $0.parentFolderID }

        if let unfiled = bookmarksByFolder[nil], !unfiled.isEmpty {
            ForEach(unfiled, id: \.id) { BookmarkRow(bookmark: $0, edit: { editing = $0 }) }
        }

        let topLevelFolders = (childFoldersByParent[nil] ?? []).filter { folder in
            folderHasAnyBookmarks(folder,
                                  childFoldersByParent: childFoldersByParent,
                                  bookmarksByFolder: bookmarksByFolder)
        }
        ForEach(topLevelFolders, id: \.id) { folder in
            BookmarkFolderNode(
                folder: folder,
                childFoldersByParent: childFoldersByParent,
                bookmarksByFolder: bookmarksByFolder,
                onEdit: { editing = $0 }
            )
        }
    }
    // ... folderHasAnyBookmarks helper stays the same as BookmarkSidebarSection.swift:95-109
}
```

**Target line counts:**
- `BrowserSessionsSection`: ~20-25 lines (from 19, growth absorbed by the outer-guard compound check)
- `NestedBookmarkSubSection`: ~65-75 lines (under the 80-line cap)
- `BookmarkFolderNode`, `BookmarkRow`, `BookmarkFolderDropDelegate`, `DeleteKeyHandler`: unchanged, co-located in the same file

### Pattern 2: Repurpose `BookmarkSidebarSection.swift`

**What:** Keep the file; change its contents. Rename the primary struct `BookmarkSidebarSection` → `NestedBookmarkSubSection`. Delete the `Section { … }` wrapper (the `Section { … } header: { … }` at `:30-61`) since the parent `BrowserSessionsSection` owns the `Section`. Preserve every private helper (`BookmarkFolderNode`, `BookmarkFolderDropDelegate`, `BookmarkRow`, `DeleteKeyHandler`) verbatim.

**When to use:** Plan 11-01. Alternative is deleting the file and relocating helpers into `SidebarView.swift` — this would push `SidebarView.swift` over 600 lines (currently 566) and mix Location/browser chrome with bookmark-rendering internals. Keeping the dedicated file is cleaner.

**Example (file rename):**

```
mv Wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift \
   Wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift
# Then: update Xcode project (Wrangle.xcodeproj/project.pbxproj) to reflect rename.
# Swift compiler will find the new struct name as long as it's in the target.
```

**Alternative (keep file name):** Don't rename the file; just change `struct BookmarkSidebarSection` → `struct NestedBookmarkSubSection` inside. File name no longer matches primary type (mild CLAUDE.md violation: "Name files after their primary type"), but no Xcode project edit needed. **Planner picks.** Research prefers the rename for CLAUDE.md compliance.

### Pattern 3: Nested `CollapsibleVStackSection` on the overview

**What:** Use two `CollapsibleVStackSection` invocations — outer Browsers + inner Bookmarks — with independent `@AppStorage` keys. The inner one sits inside the outer's `content` closure.

**When to use:** Plan 11-02. Migrating `bookmarksContent` into `browsersSection`.

**Does nesting work?** YES. `CollapsibleVStackSection` is a plain `VStack`-returning SwiftUI view (`Components/CollapsibleSection.swift:10-59`). Each instance holds its own `@AppStorage` state (line 13, 28). Two instances with different `storageKey` values are fully independent — no re-entrance, no state collision. [VERIFIED: reading `Components/CollapsibleSection.swift:1-76` — no shared mutable state, no singletons; `@AppStorage` is inherently per-key.]

**Example:**

```swift
// Source: Phase 11 research — based on existing ProjectOverviewView.browsersSection at :432-458 and bookmarksContent at :355-428

private var browsersSection: some View {
    CollapsibleVStackSection(
        "Browsers",
        storageKey: "overview.browsers.expanded.\(projectID)"      // unchanged
    ) {
        VStack(alignment: .leading, spacing: 12) {
            // D-17(a) — existing tab grid, only when tabs exist
            if !browserTabs.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 12)], spacing: 12) {
                    ForEach(browserTabs) { tab in
                        // existing card body — unchanged from :435-456
                        browserCard(tab)
                    }
                }
            }
            // D-17(b) — nested Bookmarks sub-section, only when bookmarks exist
            if !projectBrowserBookmarks.isEmpty {
                CollapsibleVStackSection(
                    "Bookmarks",
                    storageKey: "overview.browsers.bookmarks.expanded.\(projectID)"    // D-21
                ) {
                    bookmarksGrid     // migrated from old :369-419 (see below)
                }
            }
        }
    }
}

// Migrated from the populated branch of old bookmarksContent (ProjectOverviewView.swift:369-419)
// The empty-branch HStack at :358-367 is DELETED (D-15).
@ViewBuilder
private var bookmarksGrid: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 12)], spacing: 12) {
        ForEach(projectBrowserBookmarks.prefix(12), id: \.id) { bookmark in
            bookmarkCard(bookmark)     // existing button + Label + CardStyle — unchanged
        }
    }
    if projectBrowserBookmarks.count > 12 {
        Text("Showing 12 of \(projectBrowserBookmarks.count). Use the sidebar for the full list.")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }
}
```

### Pattern 4: Centered empty hero inside a top-leading ScrollView

**What:** The overview's `ScrollView { VStack(alignment: .leading, spacing: 24) { … } .padding(32) }` has leading alignment so Todos, section cards, and headings all left-align. The empty hero must center horizontally. Solution: the hero is a `VStack` with `.frame(maxWidth: .infinity)` — that single modifier expands the frame to the scroll-view's content width, and because the hero's inner content has `alignment: .center`, text and icon center within the expanded frame. The parent VStack's `alignment: .leading` applies to the hero's frame position (fills width), not its content.

**Why this works:**
- Parent `VStack(alignment: .leading, …)` positions each child at its leading edge.
- Child with `.frame(maxWidth: .infinity)` fills the available width, so "leading edge" equals "left edge of full width".
- Inside the hero, `VStack(alignment: .center, spacing: 12)` centers icon, headline, and subheadline within the now-full-width frame.

**Example (matches UI-SPEC §Pattern C):**

```swift
// Source: Phase 11 research — UI-SPEC Pattern C at 11-UI-SPEC.md:226-243

// Trigger (D-12, verbatim):
private var shouldShowEmptyHero: Bool {
    terminalSessions.isEmpty
        && browserTabs.isEmpty
        && documentTabs.isEmpty
        && projectBrowserBookmarks.isEmpty
        && projectBookmarks.isEmpty
}

private var emptyHero: some View {
    VStack(alignment: .center, spacing: 12) {
        Image(systemName: "square.grid.2x2")
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
        Text("Nothing here yet")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
        Text("Press + to add your first Scratch Pad, Browser, Bookmark, or Location.")
            .font(.subheadline)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)           // ← the key modifier; expands frame to full scroll-view width
    .padding(.vertical, 48)
}

// Usage inside body (body re-structured to keep Todos always):
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            header
            todosSection                                       // ALWAYS renders (D-12: Todos exempt)
            if shouldShowEmptyHero {
                emptyHero                                       // below Todos
            } else {
                if !terminalSessions.isEmpty { sessionsSection }
                if !browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty { browsersSection }   // D-20
                if !documentTabs.isEmpty { documentsSection }
                if !projectBookmarks.isEmpty { locationsSection }                                 // D-15
                // bookmarksSection call at :84 is DELETED (D-11)
            }
        }
        .padding(32)
    }
    // ... rest unchanged
}
```

**Alternative rejected:** Wrapping hero in `HStack { Spacer(); hero; Spacer() }`. This works but adds two extra Spacer views. `.frame(maxWidth: .infinity)` is the single-modifier canonical approach for this exact layout. [CITED: SwiftUI frame semantics documented at https://developer.apple.com/documentation/swiftui/view/frame(maxwidth:alignment:).]

### Query Scoping Gotcha — the outer Browsers guard

**The problem:** D-07 says the outer Browsers section renders when `!browsers.isEmpty || !visibleBookmarks.isEmpty`. `browsers` is `appState.projectBrowserSessions` (lives on AppState). `visibleBookmarks` is derived from a `@Query<BrowserBookmark>` inside the child `NestedBookmarkSubSection`. The parent `BrowserSessionsSection` needs to know the count to decide whether to render at all.

**Three options:**

1. **Lift the `@Query` up to `BrowserSessionsSection`**, pass filtered arrays down as init parameters. Simple; no AppState touch. `BrowserSessionsSection` now owns two `@Query`s + one `@AppStorage` + the outer chrome — pushes it past 40 lines but still well under 80. **RECOMMENDED.**
2. **Compute-and-cache on AppState** (`appState.hasVisibleBookmarks`). Requires AppState change — scope creep. Not recommended.
3. **Always render the outer Browsers section** when `!browsers.isEmpty` OR always when bookmarks _might_ exist, and let the child gate itself. Breaks D-07 (outer must hide when both empty).

**Recommendation: Option 1.** `BrowserSessionsSection` hoists the `@Query`s, derives `visibleBookmarks` inline, checks both conditions in its `if` guard, then renders the outer `Section` with `LocationBrowserRow` children + passes the pre-filtered arrays to `NestedBookmarkSubSection`. Total ~45 lines.

```swift
// Source: Phase 11 research — Option 1 implementation

private struct BrowserSessionsSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrowserBookmark.dateAdded, order: .reverse) private var allBookmarks: [BrowserBookmark]
    @Query(sort: \BrowserBookmarkFolder.displayOrder) private var allFolders: [BrowserBookmarkFolder]
    @AppStorage("sidebar.browsers.expanded") private var isExpanded: Bool = true

    private var visibleBookmarks: [BrowserBookmark] {
        let pid = appState.selectedProjectID
        return allBookmarks.filter { $0.projectID == pid || $0.projectID == nil }
    }
    private var visibleFolders: [BrowserBookmarkFolder] {
        let pid = appState.selectedProjectID
        return allFolders.filter { $0.projectID == pid || $0.projectID == nil }
    }

    var body: some View {
        let browsers = appState.projectBrowserSessions
        if !browsers.isEmpty || !visibleBookmarks.isEmpty {              // D-07
            Section {
                if isExpanded {
                    ForEach(browsers) { LocationBrowserRow(session: $0) }
                    NestedBookmarkSubSection(                              // D-09: hides itself if empty
                        visibleBookmarks: visibleBookmarks,
                        visibleFolders: visibleFolders
                    )
                }
            } header: {
                SidebarSectionHeader(title: "Browsers", isExpanded: $isExpanded)
            }
        }
    }
}

private struct NestedBookmarkSubSection: View {
    let visibleBookmarks: [BrowserBookmark]
    let visibleFolders: [BrowserBookmarkFolder]
    @Environment(\.modelContext) private var modelContext
    @State private var editing: BrowserBookmark?
    @AppStorage("sidebar.browsers.bookmarks.expanded") private var isExpanded: Bool = true

    var body: some View {
        if !visibleBookmarks.isEmpty {                                   // D-09
            // sub-header button (D-04) + content (D-06) — same as Pattern 1 example
            // ...
        }
    }
}
```

**Trade-off:** Passing arrays down re-creates `NestedBookmarkSubSection` on every `BrowserSessionsSection` body evaluation. Acceptable — bookmarks counts are small (< ~200 per project realistically), arrays are Swift `Array` value types, SwiftUI's diffing handles it.

### Anti-Patterns to Avoid

- **Passing `isExpanded` binding down from parent to `NestedBookmarkSubSection`.** Each sub-section owns its own chevron state via `@AppStorage("sidebar.browsers.bookmarks.expanded")`. Don't create a parent-owned `@State` and bind it.
- **Wrapping the `if !empty` guard in `withAnimation { … }`.** Violates D-22. The existing chevron-rotation `withAnimation(.snappy(duration: 0.15))` stays — that's expand/collapse animation of mounted content, not section appearance/disappearance.
- **Adding `.transition(.slide)` or `.animation(…, value: count)` to the section branches.** Same as above.
- **Using `@Query(filter: #Predicate<BrowserBookmark> { $0.projectID == projectID || $0.projectID == nil })`.** The codebase uses in-view computed properties for BrowserBookmark project-scope filtering because the OR-with-nil case is awkward in Predicate. Stay consistent.
- **Deleting `bookmarksContent` without first migrating the populated-grid branch.** Must split carefully: the `if projectBrowserBookmarks.isEmpty { HStack … } else { LazyVGrid … }` at `ProjectOverviewView.swift:358-427` — delete the `if` branch (empty state, lines 358-367), migrate the `else` branch (LazyVGrid + overflow caption, lines 369-425) into the nested `CollapsibleVStackSection` inside `browsersSection`.
- **Putting the empty hero inside a conditional on Todos state.** D-12 is explicit — Todos are not factored in. Hero trigger boolean has exactly 5 terms (terminal / browser / document tabs + 2 bookmark types).
- **Using `onTapGesture` on the sub-header.** CLAUDE.md coding-patterns §4 explicitly forbids this in favor of `Button { … } .buttonStyle(.plain)`. Also required for keyboard focus + VoiceOver.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Collapsible section on overview (new nested Bookmarks) | Custom chevron + VStack + state | `CollapsibleVStackSection` (`Components/CollapsibleSection.swift`) | Handles `@AppStorage` + chevron animation + accessory slot. Already battle-tested in 6 call sites |
| Sidebar outer section header | Custom HStack + chevron | `SidebarSectionHeader` (`Components/SidebarSectionHeader.swift`) | Already canonical; Phase 12 further unifies it |
| Reactive bookmark count | Manual observation / `NotificationCenter` | `@Query<BrowserBookmark>` + computed filter | SwiftData publishes updates on save; re-render is automatic |
| Expansion-state persistence | Custom `UserDefaults` key read/write | `@AppStorage("sidebar.browsers.bookmarks.expanded")` | One-line declaration; survives relaunch; zero migration |
| Bookmark drag-to-reparent | New DropDelegate | Existing `BookmarkFolderDropDelegate` (relocated unchanged) | Handles reparent-to-nil (unfiled) and reparent-to-folder; already wired to `modelContext.save()` |
| Delete-key on bookmark row | Custom key event monitor | Existing `DeleteKeyHandler` ViewModifier (co-located with `BookmarkRow`) | Already respects `.focusable(enabled)` + hover state |
| Empty-state icon | Custom SVG or raster | SF Symbol `square.grid.2x2` | System-signed, free Dynamic Type, matches overview row icon already used |

**Key insight:** Phase 11 is almost entirely composition of existing verified components. Every novel piece (the count-only-when-collapsed sub-header, the compound empty-hero condition) is a ≤20-line custom HStack or boolean. Nothing to hand-roll at the algorithm or data-layer level.

## Runtime State Inventory

This phase is partly a refactor (deleting files / moving code / renaming structs). Applying the inventory discipline:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None.** SwiftData schema is unchanged. `BrowserBookmark`, `BrowserBookmarkFolder`, `BookmarkedDirectory`, `Project` models have no field changes. The two "Unfiled" bookmarks and project-scoped bookmarks all persist exactly as before. Verified by reading `Wrangle/Models/BrowserBookmark.swift` (not modified) and STATE.md decisions log (no schema bump). | None |
| Live service config | **None.** No external services, no webhooks, no workflows. | None |
| OS-registered state | **None.** No launchd plists, no Task Scheduler, no CLI tools. | None |
| Secrets / env vars | **None.** No secrets in this phase. No env var names change. | None |
| Build artifacts / installed packages | **Xcode project file (`Wrangle.xcodeproj/project.pbxproj`)** will need updating if `BookmarkSidebarSection.swift` is renamed to `NestedBookmarkSubSection.swift` (Pattern 2). File references in `pbxproj` are path-based. If the planner chooses to keep the file name and only rename the type, no pbxproj edit is needed. | If rename-file path chosen: update pbxproj via Xcode (open project, rename file; Xcode auto-updates references). No data migration |
| UserDefaults keys (orphaned) | **`sidebar.bookmarks.expanded`** (at `BookmarkSidebarSection.swift:17`) becomes orphaned when the top-level BookmarkSidebarSection is dissolved. **`overview.bookmarks.expanded.<projectID>`** (used at `ProjectOverviewView.swift:349`) becomes orphaned when the standalone Bookmarks card is deleted. Both keys are additive prefs — leaving them unread does not harm users (they just don't affect anything). | No action required for Phase 11. Phase 12's UIX-22 audit decides delete-on-migration or leave-alone |

**Canonical question answered:** After every source file is updated, the two orphaned `@AppStorage` keys remain in each user's `~/Library/Preferences/<bundle>.plist`. They do nothing. Phase 12 cleans them.

## Common Pitfalls

### Pitfall 1: Implicit animation on delete-last-item

**What goes wrong:** A section fades or slides out when the user deletes the last item, instead of instantly disappearing.

**Why it happens:** If any enclosing view calls `.animation(.smooth, value: someValue)` OR if the delete action is wrapped in `withAnimation { … }` — that transaction propagates through the `@Query`-driven body re-render, animating the `if !empty` branch's removal.

**How to avoid:**
1. Don't wrap `BookmarkStore.remove(bookmark)` in `withAnimation`. Current code doesn't; don't change that.
2. Don't add `.animation(…, value: visibleBookmarks.count)` anywhere in `BrowserSessionsSection` or `NestedBookmarkSubSection`.
3. Don't add `.transition(.opacity)` or similar to the `Section { … }` or the nested sub-section's body.
4. If later debugging reveals an unwanted animation: use `.transaction(value: visibleBookmarks.count) { $0.animation = nil }` on the outer section to force-disable. [CITED: https://developer.apple.com/documentation/swiftui/view/transaction(value:_:) — "transaction(value:_:) with $0.animation = nil disables animations for the matching state change"]

**Warning signs:** Deletion produces a visible fade, slide, or height-shrink transition. Chevron-rotation animations on expand/collapse are still expected and correct — those are animating content that stays mounted.

### Pitfall 2: `NestedBookmarkSubSection` rendered but empty (no content)

**What goes wrong:** The Browsers section shows but the nested Bookmarks sub-header is visible with no rows below it.

**Why it happens:** Double-guarding mistake — the outer `BrowserSessionsSection` checks `!browsers.isEmpty || !visibleBookmarks.isEmpty` (D-07), which lets the section render when only bookmarks exist. Inside, `NestedBookmarkSubSection` must ALSO check `!visibleBookmarks.isEmpty` (D-09) before rendering its sub-header, otherwise when `!browsers.isEmpty && visibleBookmarks.isEmpty` it renders an empty sub-header.

**How to avoid:** Pattern 1 example has the correct guard at both levels. Both guards must pass for the sub-header to render.

**Warning signs:** A `Bookmarks` label with no chevron content underneath. Equivalent to the old empty-state row, which UIX-23 forbids.

### Pitfall 3: The outer overview Browsers card renders empty with a "Bookmarks" chevron but no bookmarks grid

**What goes wrong:** `browserTabs.isEmpty && !projectBrowserBookmarks.isEmpty` case (D-18): card renders, tab grid is hidden (correct), but the nested `CollapsibleVStackSection("Bookmarks")` is expanded and shows only the "Showing N" caption or an empty LazyVGrid.

**Why it happens:** Migrating the `bookmarksGrid` helper must NOT carry over the old empty-state HStack at `ProjectOverviewView.swift:358-367`. If left in place, the inner card would render an empty state row even when `projectBrowserBookmarks.isEmpty` — but the OUTER guard at D-20 would prevent that. Still, the empty-state HStack must be DELETED during migration.

**How to avoid:** When migrating the populated branch of `bookmarksContent` (lines 369-425), strip the enclosing `if projectBrowserBookmarks.isEmpty { … } else { … }` — only the `else` branch survives. The outer guard at `browsersSection` visibility (D-20) + the inner `if !projectBrowserBookmarks.isEmpty` wrap around the nested `CollapsibleVStackSection` is the new two-layer guard.

**Warning signs:** An inline "No bookmarks yet. Star a page…" HStack surviving in git diff output.

### Pitfall 4: Empty hero fires even when Todos exist

**What goes wrong:** User adds only a Todo; empty hero still renders because Todos aren't in the D-12 boolean.

**Why it happens:** This is actually CORRECT per D-12. Todos are explicitly not factored in — Todos stays at top, hero sits below it. If the user has only a Todo, the user sees: project header → Todos section with the todo row → empty hero below.

**How to avoid:** Document this to the user in the UAT script. Expected behavior, not a bug. The hero is not a "truly empty" signal — it's a "no content to display beyond Todos" signal.

**Warning signs:** User feedback "I added a todo, why am I still seeing the hero?". Expected; re-confirm D-12 rationale.

### Pitfall 5: Rename of `BookmarkSidebarSection.swift` breaks Xcode build

**What goes wrong:** After renaming the file on disk without updating the Xcode project, the build fails with "file not found".

**Why it happens:** `Wrangle.xcodeproj/project.pbxproj` uses absolute path references — a plain `mv` on the command line doesn't update them.

**How to avoid:** Rename the file inside Xcode (File Inspector → rename) OR use Finder, then open Xcode and let it detect and offer to relocate. Alternatively, run `sed`/scripted edit on `project.pbxproj` — risky; prefer Xcode's UI.

**Warning signs:** Build error `Build input file cannot be found: '…/BookmarkSidebarSection.swift'`.

### Pitfall 6: `@Query` on `BrowserBookmark` with projectID filter returns zero results for Global bookmarks

**What goes wrong:** Using `@Query(filter: #Predicate<BrowserBookmark> { $0.projectID == projectID })` returns only project-scoped bookmarks, not Global (`projectID == nil`) bookmarks. The old `BookmarkSidebarSection.visibleBookmarks` (at `:19-22`) handled this with an OR — `$0.projectID == pid || $0.projectID == nil`.

**Why it happens:** `#Predicate` with OR-to-nil on optional-String is verbose; the project uses in-view filtering.

**How to avoid:** Keep the existing pattern — `@Query` all rows, filter in a computed property. Shown in Pattern 1 example.

**Warning signs:** Nested Bookmarks sub-section missing Global bookmarks after migration.

## Code Examples

Verified patterns from existing Wrangle source. Each example is a minimal demonstration of a technique Phase 11 uses.

### Example 1: Hide-when-empty section wrapper (existing pattern, extended to Locations)

```swift
// Source: Wrangle/Sidebar/SidebarView.swift:49-61 (Scratch Pads — existing)
if !appState.scratchPadManager.scratchPads(forProject: projectID).isEmpty {
    Section {
        if isScratchPadsExpanded {
            ScratchPadSection()
        }
    } header: {
        SidebarSectionHeader(
            title: "Scratch Pads",
            isExpanded: $isScratchPadsExpanded
        )
    }
    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
}

// Phase 11 D-01: same pattern applied to Locations at :66-83.
// Compute-in-view pattern for projectLocations (matches ProjectOverviewView.projectBookmarks:52-54):
private var projectLocations: [BookmarkedDirectory] {
    bookmarks.filter { $0.projectID == projectID && !$0.isFile }
}

// Then wrap:
if !projectLocations.isEmpty {
    Section {
        if isLocationsExpanded {
            ProjectBookmarkListView(
                projectID: projectID,
                scrollProxy: scrollProxy,
                filterText: appState.sidebarFilterText,
                activeFileTypeFilters: activeFileTypeFilters,
                isFinderDragActive: dropState == .hovering,
                showActiveSessionsOnly: appState.showActiveSessionsOnly,
                onAddLocation: addLocation
            )
        }
    } header: {
        SidebarSectionHeader(
            title: "Locations",
            isExpanded: $isLocationsExpanded
        )
    }
    .id(projectID)
    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
}
```

### Example 2: Nested CollapsibleVStackSection with independent state

```swift
// Source: Phase 11 research, composed from Components/CollapsibleSection.swift + ProjectOverviewView.swift:432-458

CollapsibleVStackSection("Browsers", storageKey: "overview.browsers.expanded.\(projectID)") {
    VStack(alignment: .leading, spacing: 12) {
        if !browserTabs.isEmpty {
            // existing tab grid
        }
        if !projectBrowserBookmarks.isEmpty {
            CollapsibleVStackSection("Bookmarks", storageKey: "overview.browsers.bookmarks.expanded.\(projectID)") {
                // migrated bookmarks grid
            }
        }
    }
}
```

### Example 3: Count-only-when-collapsed inline sub-header (locked by D-04)

```swift
// Source: Adapted from BookmarkSidebarSection.swift:34-55 (existing count-badge header)
// Reused verbatim inside NestedBookmarkSubSection — see Pattern 1 for full context.

HStack(spacing: 4) {
    Button {
        withAnimation(.snappy(duration: 0.15)) { isExpanded.toggle() }
    } label: {
        HStack(spacing: 4) {
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
            Text("Bookmarks")
            if !isExpanded {                                  // D-04: count ONLY when collapsed
                Text("\(visibleBookmarks.count)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    Spacer()
}
```

### Example 4: Force-disable animation on a specific state change (Pitfall 1 mitigation)

```swift
// Source: https://developer.apple.com/documentation/swiftui/view/transaction(value:_:)
// Use only if the default behavior doesn't give instant swap — e.g., if an upstream
// view adds an implicit animation that can't be removed.

if !visibleBookmarks.isEmpty {
    // ... sub-section content ...
}
// Only add this if debugging reveals an unwanted animation:
// .transaction(value: visibleBookmarks.count) { $0.animation = nil }
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Always-render empty-state row inside a Section | Hide-when-empty via `if !xs.isEmpty { Section { … } }` | Phase 11 | Cleaner blank slate; relies on empty-hero for global "nothing here" signal |
| Top-level sidebar `BookmarkSidebarSection` as peer of Browsers | Nested sub-section inside `BrowserSessionsSection` | Phase 11 | One less top-level section; bookmarks visually tied to Browsers |
| Standalone overview Bookmarks card | Nested inside Browsers card via `CollapsibleVStackSection` | Phase 11 | One card with two chevrons; mirrors sidebar hierarchy |
| `ContentUnavailableView` (Apple's empty-state primitive, macOS 14+) | Custom VStack with SF Symbol + text | Phase 11 | Pixel control over copy, icon, spacing — per UI-SPEC |
| `.animation(…, value: count)` on section branches | No animation — rely on default `animation: nil` transaction | Phase 11 | Instant state swaps per user preference `feedback_no_slide_transitions` |

**Deprecated / outdated approaches (do NOT use in Phase 11):**
- `.cornerRadius(…)` — use `.clipShape(RoundedRectangle(cornerRadius: …))`. [CLAUDE.md coding-patterns §4]
- `onTapGesture` on interactive labels — use `Button { … }`. [CLAUDE.md coding-patterns §4]
- `DispatchQueue.main.async` — use `Task { @MainActor in … }`. [CLAUDE.md coding-patterns §2] — N/A to this phase (no async in view code)
- `@Observable` class without `@MainActor` — every `@Observable` must be `@MainActor`. N/A to this phase (no new `@Observable` classes)

## Assumptions Log

All critical claims in this research were verified against existing source code or cited to official Apple docs. No unverified assumptions block planning.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| *(none)* | — | — | — |

**This table is empty:** All claims in this research were verified via file reads, git-tracked codebase state, or cited to Apple developer documentation. No user confirmation needed before planning.

## Open Questions

1. **Rename `BookmarkSidebarSection.swift` or keep the file name?**
   - What we know: CLAUDE.md says "Name files after their primary type." After Phase 11, the primary type is `NestedBookmarkSubSection`, so the file _should_ be renamed to `NestedBookmarkSubSection.swift`.
   - What's unclear: Xcode project (pbxproj) needs the rename reflected. Either planner's task includes an Xcode rename step, or the planner picks the "keep file name, change type name" path (small CLAUDE.md violation, no pbxproj edit).
   - Recommendation: Rename in Xcode (simple one-step operation). Include it as an explicit task step in plan 11-01.

2. **Should the outer `BrowserSessionsSection` check for `!visibleBookmarks.isEmpty` by hoisting the Query, or should `NestedBookmarkSubSection` expose an `@escaping` `onVisibilityChange` callback?**
   - What we know: Pattern 1 (hoist Queries to parent) is simpler and keeps the guard where it needs to fire (parent).
   - What's unclear: Whether SwiftUI's body-diffing plus passing `Array<T>` down as init params causes measurable re-renders for large bookmark sets (>1000). Unlikely in practice.
   - Recommendation: Hoist Queries to `BrowserSessionsSection` (Pattern 1 / "Query Scoping Gotcha" — Option 1). If perf becomes a concern post-ship, revisit.

3. **Does `projectLocations` need a dedicated `@Query(filter:)` or an in-view computed property?**
   - What we know: `ProjectOverviewView.projectBookmarks:52-54` uses a computed property — consistent. `BookmarkListView.swift:33-38` uses `@Query(filter: #Predicate<BookmarkedDirectory>)` — also valid for this exact use case.
   - What's unclear: Mild tradeoff — `@Query(filter:)` is slightly more efficient for SwiftData (filter happens at query time); in-view computed recomputes on every body pass. Both are fine for ≤100 locations.
   - Recommendation: In-view computed property for visual consistency with `ProjectOverviewView.projectBookmarks`. Either choice is acceptable; planner picks.

4. **Which SF Symbol for the empty hero — confirmed `square.grid.2x2`?**
   - What we know: UI-SPEC resolves to `square.grid.2x2` with rationale (mirrors the sidebar Overview row icon at `SidebarView.swift:309`).
   - What's unclear: Nothing. Locked in UI-SPEC §Copywriting Contract.
   - Recommendation: Use `square.grid.2x2`. No further decision needed.

## Environment Availability

This phase touches only the existing SwiftUI codebase and Xcode toolchain. No new external dependencies.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | Build | ✓ | Xcode 16+ (targeting macOS 15 SDK) | — |
| Swift compiler | Build | ✓ | Swift 5.9+ | — |
| SwiftUI framework | All views | ✓ | macOS 15 SDK | — |
| SwiftData framework | @Query | ✓ | macOS 15 SDK | — |
| `swift-testing` (@Suite) | Unit tests | ✓ | Bundled with Xcode 16 | XCTest (not recommended — inconsistent with existing test files) |
| macOS | Runtime | ✓ | 15+ (Sequoia) per CLAUDE.md | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Validation Architecture

*(nyquist_validation presumed enabled — no `.planning/config.json` file found to disable it.)*

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `swift-testing` (`@Suite` / `@Test`) — bundled with Xcode 16; confirmed by inspection of `WrangleTests/*.swift` (all 4 test files use `@Suite`/`@Test`) |
| Config file | `Wrangle.xcodeproj` — test target `WrangleTests` |
| Quick run command | `xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS' -only-testing:WrangleTests/<SuiteName>` |
| Full suite command | `xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS'` |

**Reality check:** Wrangle's existing tests (`EditorDocumentTests`, `FileTypeTests`, `MarkdownParserTests`, `TokenCounterTests`) cover **logic-bearing types** — parsers, detectors, counters. There are **no SwiftUI view tests** in the project currently. This is consistent with the community state of the art: SwiftUI view tests without a snapshot library (swift-snapshot-testing) don't meaningfully verify rendering; and Wrangle does not ship SnapshotTesting. User memory `feedback_testing_priority.md` says "Prioritize test coverage" — for view work this realistically means **Preview providers + manual UAT**, not unit tests of the view tree.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UIX-10 | Scratch Pads hides when empty | manual-only (visual) | Preview: `#Preview { SidebarView().environment(AppState()) /* zero pads */ }` + UAT | ❌ no preview exists for SidebarView today; adding one is Wave 0 |
| UIX-11 | Browsers hides when both empty; renders if either present | manual-only (visual) | Preview + UAT across 4 states: empty / tabs-only / bookmarks-only / both | ❌ Wave 0 |
| UIX-12 | Locations hides when empty | manual-only (visual) | Preview + UAT | ❌ Wave 0 |
| UIX-13 | Top-level Bookmarks absent; nested sub-section appears when ≥1 bookmark | manual-only (visual) + **build regression test** | Build: `xcodebuild build …` — removing the top-level call must compile. Preview + UAT | ❌ Wave 0 (preview) / ✓ (build) |
| UIX-14 | Empty hero appears when all 5 conditions empty; hides when any becomes non-empty | manual-only (visual) | Preview of `ProjectOverviewView` in empty state + UAT | ❌ Wave 0 |
| UIX-15 | Overview Bookmarks card nested inside Browsers | manual-only (visual) | Preview + UAT | ❌ Wave 0 |

**Unit-testable logic (tangential):** None of the locked decisions introduce logic-bearing types. `shouldShowEmptyHero` is a one-line computed property — testable as `@MainActor func testEmptyHeroTrigger()`, but the cost to set up `ProjectOverviewView` test fixtures (full SwiftData + AppState stack) outweighs the value of a 5-boolean test. Recommendation: **do not add unit tests for Phase 11 view logic.** Document manual UAT steps instead.

### Sampling Rate

- **Per task commit:** `xcodebuild build -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS' 2>&1 | tail -50` — build-only verifies compilation. < 30 seconds.
- **Per wave merge:** `xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS'` — runs the 4 existing test suites; none depend on view logic, so all should pass. Phase 11 must not regress them.
- **Phase gate:** Full build + full test suite green + manual UAT checklist complete before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] Preview providers for the new empty-hero trigger — add a `#Preview("Empty — shows hero")` in `ProjectOverviewView.swift` showing the D-12 all-empty state.
- [ ] Preview providers for `BrowserSessionsSection` with four bookmark/tab combinations (empty / tabs-only / bookmarks-only / both). These can live in `SidebarView.swift` or a new `SidebarView+Previews.swift`. [Lightweight gap — nice-to-have.]
- [ ] Manual UAT checklist document — new file at `.planning/phases/11-hide-when-empty-bookmarks-nested-under-browsers/11-UAT.md` with the 5 Success Criteria from ROADMAP §Phase 11 as a checkable list. Created by executor during plan 11-02.
- *(If no gaps: "None — existing test infrastructure covers all phase requirements")*

**Recommendation:** Don't block Phase 11 on new unit tests. View-tree refactors without logic changes are correctly tested via build-green + manual UAT. Document this reasoning in STATE.md after Phase 11 wraps so the testing-priority expectation is clearly satisfied for view-only phases.

## Sources

### Primary (HIGH confidence)

- `Wrangle/Sidebar/SidebarView.swift` [VERIFIED: read in full, 566 lines] — current sidebar layout; line anchors used throughout this research
- `Wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift` [VERIFIED: read in full, 343 lines] — source for bookmark rendering helpers
- `Wrangle/Components/SidebarSectionHeader.swift` [VERIFIED: read in full, 35 lines] — unchanged this phase
- `Wrangle/Components/CollapsibleSection.swift` [VERIFIED: read in full, 76 lines] — confirms `@AppStorage`-based state; nests cleanly
- `Wrangle/Features/Dashboard/ProjectOverviewView.swift` [VERIFIED: read in full, 733 lines] — current overview layout; line anchors used throughout
- `Wrangle/Sidebar/ScratchPadSection.swift` [VERIFIED: read in full, 93 lines] — existing hide-when-empty pattern precedent
- `Wrangle/App/AppState.swift:700-727` [VERIFIED: read, confirmed `projectBrowserSessions` at :724]
- `.planning/phases/11-hide-when-empty-bookmarks-nested-under-browsers/11-CONTEXT.md` [VERIFIED: read in full, 189 lines] — all decisions D-01 through D-22
- `.planning/phases/11-hide-when-empty-bookmarks-nested-under-browsers/11-UI-SPEC.md` [VERIFIED: read in full, 326 lines] — visual contract
- `.planning/phases/10-unified-creation-pattern/10-CONTEXT.md` [VERIFIED: read in full, 164 lines] — prior-phase decisions that flow through
- `.planning/REQUIREMENTS.md` [VERIFIED: read in full] — UIX-10 through UIX-15 definitions + traceability
- `.planning/ROADMAP.md` [VERIFIED: read in full] — Phase 11 Success Criteria
- `.planning/STATE.md` [VERIFIED: read in full] — confirms Phase 10 complete, Phase 11 ready
- `CLAUDE.md` [VERIFIED: read in full] — coding conventions
- `docs/coding-patterns.md` [VERIFIED: read pages 1-361] — `Button`-over-`onTapGesture`, `.clipShape`-over-`.cornerRadius`, no-`onTapGesture`-on-DisclosureGroup, `@MainActor` + `@Observable`, `@State private`, enum-based state consolidation
- Apple Developer Docs via Context7 CLI — `/websites/developer_apple_swiftui` [CITED: https://developer.apple.com/documentation/swiftui/view/transaction(value:_:) and https://developer.apple.com/documentation/swiftui/transaction/disablesanimations] — verified `.transaction(value:_:) { $0.animation = nil }` as the canonical anti-animation escape hatch
- `/Users/krush/.claude/projects/-Users-krush-Projects-Krush-Dev-Wrangle-Wrangle/memory/feedback_no_slide_transitions.md` [VERIFIED: read] — user preference against slide transitions
- `/Users/krush/.claude/projects/-Users-krush-Projects-Krush-Dev-Wrangle-Wrangle/memory/feedback_testing_priority.md` [VERIFIED: read] — testing priority framing applied to view-only work

### Secondary (MEDIUM confidence)

- None. All claims sourced from primary materials.

### Tertiary (LOW confidence)

- None. All claims verified.

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — every symbol is already in the project and compiling green as of STATE.md `2026-04-20`.
- Architecture: **HIGH** — every pattern is a minor extension of an existing pattern in the same file or sibling file; verified by reading the affected files in full.
- Pitfalls: **HIGH** — the five main pitfalls are grounded in either (a) the user's explicit locked decisions (D-22 animation rule) or (b) documented SwiftUI behavior (Apple docs on `.transaction`).
- Testing strategy: **MEDIUM** — view-tree testing without a snapshot library is inherently a manual-UAT-first practice; this research recommends that and accepts the trade-off vs. `feedback_testing_priority.md`.

**Research date:** 2026-04-19
**Valid until:** 2026-05-19 (30 days — Phase 11 targets a stable SwiftUI/SwiftData API surface; only new Swift/Xcode minor releases between now and then could change anything, and none are expected to touch `@Query` / `@AppStorage` / `Section { … }`)
