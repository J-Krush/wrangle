# Phase 12: Section Parity & Polish — Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 12 is a normalization + audit pass over the sidebar and Project Overview sections
that settled in Phases 10–11. No new surfaces, no new features. Four narrow deliverables:

1. **Canonical section-header treatment (UIX-20)** — `SidebarSectionHeader` gains an optional
   `count: Int?` param so every collapsible sidebar section renders the same chevron + title +
   count-when-collapsed. The bespoke inline sub-header inside `NestedBookmarkSubSection` is
   retired. `CollapsibleVStackSection` on the overview gets the same optional count treatment
   for full sidebar ↔ overview parity.

2. **Scratch Pad keyboard parity with Bookmarks (UIX-21)** — Selection-driven keyboard model:
   SwiftUI `List(selection:)` binding. Return on a selected row renames (inline TextField for
   Scratch Pads, BookmarkEditSheet for Bookmarks). Delete on a selected row deletes after an
   `.alert()` confirmation. Context-menu delete stays immediate. BookmarkRow's current
   hover-based DeleteKeyHandler is replaced with the same selection-driven model (upgrade
   comes along for the ride — the phase is explicitly about parity).

3. **`@AppStorage` key audit (UIX-22)** — Source is already compliant; all 11 keys follow
   `sidebar.<section>.expanded` / `overview.<section>.expanded.<projectID>`. Phase 12 extracts
   these literals into constants (`SidebarStorageKeys` / `OverviewStorageKeys`) so future
   additions can't drift silently. No UserDefaults orphan migration — v1.2 hasn't shipped, so
   the only stale values exist on the developer's dev machine and are harmless.

4. **UIX-23 regression guard** — No header + inline empty-row violations exist today
   (Phase 11 swept them). Phase 12 documents the invariant in CLAUDE.md so future phases
   don't reintroduce it. No code enforcement.

What Phase 12 does NOT deliver:

- No new sections, no new rows, no new creation surfaces.
- No animation changes to section show/hide (instant per `feedback_no_slide_transitions`).
- No schema changes. No file-layout churn beyond the storage-keys constants file.
- No overview-card count badges on sections that don't already collapse (Todos hero,
  header stat badges, etc. stay untouched).

</domain>

<decisions>
## Implementation Decisions

### Header canonicalization (UIX-20)

- **D-01**: Extend `SidebarSectionHeader` (`wrangle/Components/SidebarSectionHeader.swift`)
  with an optional `count: Int?` parameter (default `nil`). When `count != nil` AND
  `!isExpanded`, render the count after the title as `.font(.system(size: 10))` +
  `.foregroundStyle(.tertiary)` — exact styling mirrors the current bespoke sub-header in
  `NestedBookmarkSubSection.swift:50-54`. When expanded, count is hidden.

- **D-02**: Every collapsible sidebar section passes a count:
  - Scratch Pads: `visiblePads.count` (computed in SidebarView from scratchPadManager).
  - Browsers: `browsers.count` (tab count only — nested Bookmarks shows its own count).
  - Locations: `projectLocations.count`.
  - Other Sessions: `orphaned.count`.
  - Nested Bookmarks sub-header: `visibleBookmarks.count`.

- **D-03**: `NestedBookmarkSubSection`'s bespoke inline header (the `Button { … }` block at
  `:39-59`) is deleted and replaced with `SidebarSectionHeader(title: "Bookmarks",
  isExpanded: $isExpanded, count: visibleBookmarks.count)`. The `.onDrop(of: [.text], …)`
  modifier currently attached to that Button must be preserved — attach it to the
  `SidebarSectionHeader` invocation.

- **D-04**: Extend `CollapsibleVStackSection` (`wrangle/Components/CollapsibleSection.swift`)
  with the same optional `count: Int?` param. Apply to: Terminal Sessions
  (`terminalSessions.count`), outer Browsers (`browserTabs.count`), nested Bookmarks
  (`projectBrowserBookmarks.count`), Open Files (`documentTabs.count`), Locations
  (`projectBookmarks.count`). Todos section does NOT show a count (primary capture surface,
  count lives in the stat badges already).

- **D-05**: Chevron animation — keep the current `withAnimation(.snappy(duration: 0.15))`
  on toggle in both `SidebarSectionHeader.swift:19` and `CollapsibleSection.swift:35`.
  `feedback_no_slide_transitions` applies to section show/hide, not to chevron rotation.

### Scratch Pad + Bookmark keyboard parity (UIX-21)

- **D-06**: Selection model — SwiftUI `List(selection:)` binding. Add a shared selection
  `@State` in `SidebarView` (likely an enum over `ScratchPadRowID` / `BookmarkRowID` cases,
  or a typed `Hashable` ID wrapper). Rows declare `.tag(…)` so List selection picks them up.
  **Planning risk:** SwiftUI `List(selection:)` with multiple heterogeneous `Section`s can be
  janky on macOS. If the selection binding causes visual glitches (unexpected row highlights,
  selection not clearing across sections), fall back to per-section `@State` scoped to
  ScratchPadSection and NestedBookmarkSubSection — the keyboard contract stays the same.

- **D-07**: Return on a selected row = rename.
  - ScratchPadRow: enter inline rename mode (existing flow at `ScratchPadSection.swift:17-23`
    already handles this — trigger via `renamingURL = pad.url` on keypress instead of via
    context menu).
  - BookmarkRow: open `BookmarkEditSheet` (same surface as the current "Edit..." context-menu
    item — sets `editing = bookmark`).

- **D-08**: Delete on a selected row = delete with a `.alert()` confirmation.
  - Scratch Pad alert copy: `"Move '\(pad.name)' to Trash?"` with destructive "Move to Trash"
    + "Cancel" buttons.
  - Bookmark alert copy: `"Delete bookmark '\(displayName)'?"` with destructive "Delete" +
    "Cancel" buttons.

- **D-09**: Context-menu "Delete" stays **immediate** on both row types (no confirmation).
  Deliberate click = no friction. Keyboard Delete = confirm. Hybrid protects accidental
  key-presses without nagging on deliberate menu use.

- **D-10**: Scratch Pad file delete moves to Trash via `NSWorkspace.shared.recycle([url])`,
  replacing the current unlink in `scratchPadManager.deleteScratchPad`. User can recover
  from Finder Trash. Matches macOS convention.

- **D-11**: BookmarkRow's current hover-based `DeleteKeyHandler` struct at
  `NestedBookmarkSubSection.swift:336-349` is **removed entirely**. Delete-key handling moves
  to the selection-driven model. Don't extract DeleteKeyHandler to a shared file — it's
  going away, not being reused.

- **D-12**: Rename-commit behavior on Scratch Pads stays as-is: `onCommit` fires on Return
  inside the TextField; Esc cancels via `onExitCommand` (already wired at
  `ScratchPadSection.swift:59-66`). Selection must clear after rename commits so subsequent
  Return doesn't re-enter rename.

### `@AppStorage` key audit (UIX-22)

- **D-13**: No UserDefaults migration. v1.2 hasn't shipped to end users. Only the developer's
  local plist contains stale keys (e.g., `overview.bookmarks.expanded.<projectID>` from
  pre-Phase-11 builds). These values are inert — no source code reads them — and occupy a
  handful of bytes each. Not worth a migration.

- **D-14**: Extract all 11 existing `@AppStorage` literals into two constants files:
  - `wrangle/Components/SidebarStorageKeys.swift` — enum with static lets for every
    `sidebar.*` key. Five entries: `locationsExpanded`, `scratchPadsExpanded`,
    `browsersExpanded`, `otherSessionsExpanded`, `browserBookmarksExpanded`.
  - `wrangle/Components/OverviewStorageKeys.swift` — enum with static funcs taking
    `projectID` and returning the per-project key string. Six entries: `todosExpanded(_:)`,
    `sessionsExpanded(_:)`, `browsersExpanded(_:)`, `browserBookmarksExpanded(_:)`,
    `documentsExpanded(_:)`, `locationsExpanded(_:)`.
  - All 11 `@AppStorage("...")` call sites rewire to reference the constants.
  - No runtime behavior change; this is a refactor for drift prevention.

- **D-15**: Document the naming convention in `CLAUDE.md`:
  - Sidebar section expansion: `sidebar.<section>.expanded` (global, not per-project).
  - Overview section expansion: `overview.<section>.expanded.<projectID>` (per-project,
    template-substituted at runtime).
  - Nested sub-sections: append sub-segment (e.g., `sidebar.browsers.bookmarks.expanded`).
  - Any new `@AppStorage` key covering sidebar/overview expansion state MUST go through
    `SidebarStorageKeys` / `OverviewStorageKeys`.

### UIX-23 regression guard

- **D-16**: No runtime assertion, no unit test, no wrapper view. Phase 11 swept existing
  violations; Phase 12 verifies by manual grep sweep (`Text("No \w+ yet"` / `"Nothing "` /
  `"Empty "` patterns inside Section / CollapsibleVStackSection bodies) and documents the
  invariant in CLAUDE.md.

- **D-17**: CLAUDE.md rule to add (exact wording for planner/writer to adapt): **"Sidebar
  and Project Overview sections must hide when empty. Never render a section header with an
  inline empty-state row ('No X yet', 'Nothing here', etc.) inside its body. If a global
  empty-state message is needed, use the overview's centered empty-hero (Phase 11 pattern) —
  never per-section placeholder rows."**

### Claude's Discretion

- Exact placement of `SidebarStorageKeys.swift` / `OverviewStorageKeys.swift` — the
  `Components/` directory is a reasonable default but planner may route them to a dedicated
  `Storage/` or `Constants/` directory if that aligns better.
- Whether `OverviewStorageKeys` uses static funcs (`browsersExpanded(_ projectID: String)
  -> String`) or a namespace-style `String` formatter — either is fine.
- Whether `SidebarSectionHeader.count` defaults to nil and uses `if let count`, or uses
  `count: Int = 0` + `if count > 0` — either ergonomics works; pick what reads cleanest.
- Whether to extract a shared `ConfirmDeleteAlert` view modifier for Scratch Pad + Bookmark
  alerts, or duplicate the `.alert()` calls inline at each row — two call sites is borderline
  for abstraction; pick what keeps each file under the 80-line budget.
- The exact selection-binding type (enum over row IDs vs `AnyHashable`) — planner's call. If
  `List(selection:)` proves unstable across multiple Sections, fall back to per-section
  `@State` and note the deviation in SUMMARY.
- Rename text field selection on entry — whether to select-all on entry (Finder convention)
  or place cursor at end. Suggest select-all to match Finder.
- Whether `NestedBookmarkSubSection`'s `Group` scope wrapper needs adjustment once the
  header is replaced by the shared component — likely no change needed, but verify the
  `.onDrop` modifier still attaches correctly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements
- `.planning/REQUIREMENTS.md` §UIX-20 through §UIX-23 — the four requirements this phase must
  satisfy (1-to-1 with Phase 12).
- `.planning/ROADMAP.md` §Phase 12 — Goal, Success Criteria (4 rows), Plans (1 plan expected).

### Prior-phase decisions that flow through
- `.planning/phases/10-unified-creation-pattern/10-CONTEXT.md` — Phase 10 established that
  `SidebarSectionHeader` is navigation-only; the `accessory` ViewBuilder param has already
  been dropped. Phase 12 extends the component further but stays within the nav-only contract
  (adding a count display is not an action affordance).
- `.planning/phases/11-hide-when-empty-bookmarks-nested-under-browsers/11-CONTEXT.md` —
  Phase 11 established the `sidebar.browsers.bookmarks.expanded` /
  `overview.browsers.bookmarks.expanded.<projectID>` nested-key pattern and deferred the
  count-when-collapsed unification explicitly to this phase (Deferred Ideas, bullet 1).

### Code surfaces the phase must touch

**Shared components**
- `wrangle/Components/SidebarSectionHeader.swift` — add optional `count: Int?` param;
  render count when collapsed with `.font(.system(size: 10))` + `.foregroundStyle(.tertiary)`.
- `wrangle/Components/CollapsibleSection.swift` — add optional `count: Int?` param to
  `CollapsibleVStackSection` init(s); render count when collapsed with the same styling.

**Sidebar sections**
- `wrangle/Sidebar/SidebarView.swift:49-60` — Scratch Pads Section. Compute `visiblePads.count`
  at this scope; pass to `SidebarSectionHeader(count:)`. May require a `visiblePads` computed
  property on SidebarView or lifting from ScratchPadSection.
- `wrangle/Sidebar/SidebarView.swift:72-92` — Locations Section. Pass
  `projectLocations.count` to `SidebarSectionHeader(count:)`.
- `wrangle/Sidebar/SidebarView.swift:534-565` — `BrowserSessionsSection`. Pass
  `browsers.count` (tabs only, NOT including bookmarks) to `SidebarSectionHeader(count:)`.
- `wrangle/Sidebar/SidebarView.swift:569-587` — `OrphanedSessionsSection`. Pass
  `orphaned.count` to `SidebarSectionHeader(count:)`.
- `wrangle/Sidebar/ScratchPadSection.swift` — add Return-to-rename via selection. Likely
  needs a new selection `@Binding` or `@State` plumbed from SidebarView via `List(selection:)`.
  Existing inline rename flow (`renamingURL`, `renameText`, `commitRename`, `onExitCommand`)
  is reused; only the **trigger** changes (selection + Return, not context-menu click).

**Nested Bookmarks sub-section**
- `wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift:33-73` — replace the bespoke
  inline header Button (`:39-59`) with `SidebarSectionHeader(title: "Bookmarks",
  isExpanded: $isExpanded, count: visibleBookmarks.count)`. Preserve the `.onDrop(of: [.text],
  delegate: BookmarkFolderDropDelegate(…))` modifier — attach it to the shared header call
  site.
- `wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift:255-332` — `BookmarkRow`. Replace
  hover-based Delete-key handling with selection-driven Delete + `.alert()` confirmation.
  Add Return-to-open-BookmarkEditSheet when the row is selected.
- `wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift:336-349` — delete the private
  `DeleteKeyHandler` struct; the new selection-driven flow replaces it.

**Project Overview**
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:207-265` — Todos section. Do NOT add
  a count (primary capture surface; stat badges cover it).
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:278-286` — Terminal Sessions card.
  Pass `terminalSessions.count` to `CollapsibleVStackSection(count:)`.
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:381-474` — Browsers card (outer).
  Pass `browserTabs.count` to the outer `CollapsibleVStackSection(count:)`. Pass
  `projectBrowserBookmarks.count` to the nested `CollapsibleVStackSection("Bookmarks", count:)`.
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:478-516` — Open Files card. Pass
  `documentTabs.count` to `CollapsibleVStackSection(count:)`.
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:520-533` — Locations card. Pass
  `projectBookmarks.count` to `CollapsibleVStackSection(count:)`.

**Storage keys refactor**
- `wrangle/Sidebar/SidebarView.swift:18-19, 537, 571` — four sidebar `@AppStorage` literals;
  rewire to `SidebarStorageKeys.*`.
- `wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift:21` — one sidebar `@AppStorage`
  literal; rewire to `SidebarStorageKeys.browserBookmarksExpanded`.
- `wrangle/Features/Dashboard/ProjectOverviewView.swift:208, 279, 382, 413, 479, 525` — six
  overview `@AppStorage` calls via `CollapsibleVStackSection(storageKey:)`; rewire to
  `OverviewStorageKeys.*(projectID)`.
- New file: `wrangle/Components/SidebarStorageKeys.swift` — enum with 5 static lets.
- New file: `wrangle/Components/OverviewStorageKeys.swift` — enum with 6 static funcs taking
  `projectID: String`.

**Scratch Pad delete → Trash**
- `wrangle/` somewhere under Scratch Pad plumbing — the `scratchPadManager.deleteScratchPad(at:)`
  implementation. Planner greps for the definition and switches from `FileManager.removeItem`
  to `NSWorkspace.shared.recycle([url])` (or equivalent). Callers don't change.

**CLAUDE.md**
- Add the UIX-22 convention note (D-15) and the UIX-23 invariant rule (D-17) under a
  "Sidebar / Overview section conventions" subheading.

### Code surfaces to read but NOT touch
- `wrangle/App/AppState.swift` — no new state needed; selection lives in SidebarView.
- `wrangle/Browser/Bookmarks/BookmarkEditSheet.swift` — Return-to-rename on Bookmarks opens
  this sheet unchanged. No modifications.
- `wrangle/Browser/Bookmarks/BookmarkStore.swift` — delete path unchanged; only the
  **trigger** changes.
- `wrangle/Browser/Bookmarks/BookmarkFolderDropDelegate` (private struct in
  NestedBookmarkSubSection.swift) — drop target re-attaches to the shared header; the
  delegate logic is unchanged.
- `wrangle/Components/UnifiedAddMenu.swift` — Phase 10 surface; untouched.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SidebarSectionHeader` — gains the `count:` param; all 4 existing sidebar call sites
  (Scratch Pads, Locations, Browsers, Other Sessions) pass their section count.
- `CollapsibleVStackSection` — parallel expansion with the same `count:` param for the
  overview cards. Shares the exact same count styling (`.system(size: 10)` + `.tertiary`).
- Existing ScratchPad rename flow (`renamingURL` / `renameText` / inline TextField +
  `onCommit` / `onExitCommand`) — fully reusable; only the trigger changes.
- `BookmarkEditSheet` — the target for Return-to-rename on Bookmarks; reused as-is.
- `NSWorkspace.shared.recycle([url])` — standard macOS "move to Trash" API. Replaces
  `FileManager.removeItem` in `scratchPadManager.deleteScratchPad`.

### Established Patterns
- **Shared Components/**: new storage-keys constants files (`SidebarStorageKeys.swift`,
  `OverviewStorageKeys.swift`) slot into `wrangle/Components/` next to the existing
  `SidebarSectionHeader.swift` and `CollapsibleSection.swift`.
- **`@AppStorage` + constant literals**: the current convention is inline literals (matches
  the 11 existing call sites). The refactor to constants is the new convention for this
  codebase; document it in CLAUDE.md.
- **`.alert(…, isPresented:)`** — SwiftUI-native destructive confirmation; consistent with
  the codebase's existing alert usage (no inline `NSAlert.runModal` calls in the hot paths).
- **Hide-when-empty** guards at the body level (Phase 11 D-01/D-07/D-11/D-20) — Phase 12
  adds no new guards; it only adds counts inside the already-gated section headers.

### Integration Points
- SidebarView owns the List selection binding; Scratch Pads + nested Bookmarks rows
  participate via `.tag(…)`. Other sections (Browser tabs, Locations, Other Sessions,
  Overview row) do NOT gain selection — keeps the blast radius small.
- The count-when-collapsed display on all section headers is read-only; it does not change
  section-show-hide logic — that's still gated by the body-level `if !xs.isEmpty` guards
  from Phase 11.

### Code Hotspots / Complexity
- **SwiftUI `List(selection:)` across heterogeneous Sections** is the main risk. macOS List
  can render visual glitches when two Sections contribute selectable rows with different ID
  types, or when selection is cleared programmatically. If this proves flaky during
  implementation, the fallback (per-section `@State`) is straightforward — the keyboard
  contract stays identical to the user; only the internal plumbing changes. Planner should
  budget a small spike at the start of the plan to validate.
- `scratchPadManager.deleteScratchPad` switching from unlink to `NSWorkspace.recycle` is a
  semantic change (soft-delete vs hard-delete). If any callers assume the file is
  immediately gone (e.g., reuse the same filename right after delete), they may hit
  "file exists in Trash with this name" name-collision behavior. Planner verifies all call
  sites of `deleteScratchPad` during the plan.

</code_context>

<specifics>
## Specific Ideas

- **macOS-native selection model for keyboard affordances** — the user specifically asked
  for "the best pattern" and "most common for macOS apps," and accepted Finder/Mail/Xcode
  selection-based rename/delete as the right endpoint. Don't regress to the hover-based
  pattern for shipping code; fall back only if `List(selection:)` proves unworkable.
- **Count-when-collapsed styling exactly mirrors Phase 11's bespoke bookmark header** —
  `.font(.system(size: 10))` + `.foregroundStyle(.tertiary)`. Do NOT switch to `.caption2`
  or other system scales; match the existing pixels.
- **Browsers count = tab count only** — do not sum tabs + bookmarks. The nested Bookmarks
  sub-header carries its own count independently. Each collapsible level shows only what
  belongs to that level.
- **No overview count on Todos** — Todos is the primary capture surface and already has a
  stat badge in the header. Adding a count to its `CollapsibleVStackSection` header is
  redundant.
- **Confirm only on keyboard Delete, not on context-menu Delete** — context-menu click is
  deliberate (no friction); keyboard Delete is easy to mispress (confirm). Hybrid applies
  identically to Scratch Pads and Bookmarks.
- **Scratch Pad moves to Trash; Bookmark is a model delete** — the alert copy differs to
  match the actual operation ("Move to Trash" for files, "Delete bookmark" for SwiftData
  rows).

</specifics>

<deferred>
## Deferred Ideas

- **Overview count badges on Todos** — redundant with the existing stat badge in the
  overview header; not proposed for this phase or later.
- **Shared `ConfirmDeleteAlert` view modifier** — two call sites is borderline for
  abstraction. If later phases add a third row type with keyboard delete (e.g., history
  entries), promote it then.
- **Unit test for `@AppStorage` naming convention** — considered and rejected in favor of
  the constants file (structural enforcement) + CLAUDE.md note. Revisit if a future phase
  introduces a non-expansion-state `@AppStorage` that also needs drift prevention.
- **Helper wrapper view for hide-when-empty sections** (`HideWhenEmptySection<Body>`) —
  considered for UIX-23 regression guard, rejected in favor of the CLAUDE.md rule. Revisit
  if a drift incident happens.
- **Runtime debug assertion against empty Section bodies** — considered for UIX-23, rejected
  as over-engineering.
- **Dev-only menu item "Reset sidebar/overview expansion state"** — considered for dev QA,
  deferred. Can be added to a future debug menu without affecting the phase scope.
- **Promoting selection to all sidebar sections** (Browsers rows, Locations, Other Sessions,
  Overview row) — only Scratch Pads + Bookmarks need keyboard affordances for Phase 12.
  Other sections don't have rename-worthy content or per-row delete semantics today.
- **Per-site `UserDefaults` migration for orphan pre-Phase-11 keys** — v1.2 hasn't shipped;
  no real users affected. Dev-local orphans are harmless.

</deferred>

---

*Phase: 12-section-parity-polish*
*Context gathered: 2026-04-20*
