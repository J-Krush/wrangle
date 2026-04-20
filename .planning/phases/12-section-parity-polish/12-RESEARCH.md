# Phase 12: Section Parity & Polish — Research

**Researched:** 2026-04-20
**Domain:** Native macOS SwiftUI — shared component extension, List selection plumbing, keyboard affordance parity, AppStorage constants
**Confidence:** HIGH (for codebase claims, SwiftUI APIs, and locked decisions); MEDIUM (for the `List(selection:)`-across-heterogeneous-Sections risk — risk is real per Apple Developer Forum reports but not codified in official docs)

---

<user_constraints>
## User Constraints (from 12-CONTEXT.md)

### Locked Decisions

**Header canonicalization (UIX-20)**

- **D-01**: Extend `SidebarSectionHeader` (`wrangle/Components/SidebarSectionHeader.swift`) with an optional `count: Int?` parameter (default `nil`). When `count != nil` AND `!isExpanded`, render the count after the title as `.font(.system(size: 10))` + `.foregroundStyle(.tertiary)` — exact styling mirrors the current bespoke sub-header in `NestedBookmarkSubSection.swift:50-54`. When expanded, count is hidden.
- **D-02**: Every collapsible sidebar section passes a count:
  - Scratch Pads: `visiblePads.count` (computed in SidebarView from scratchPadManager).
  - Browsers: `browsers.count` (tab count only — nested Bookmarks shows its own count).
  - Locations: `projectLocations.count`.
  - Other Sessions: `orphaned.count`.
  - Nested Bookmarks sub-header: `visibleBookmarks.count`.
- **D-03**: `NestedBookmarkSubSection`'s bespoke inline header (the `Button { … }` block at `:39-59`) is deleted and replaced with `SidebarSectionHeader(title: "Bookmarks", isExpanded: $isExpanded, count: visibleBookmarks.count)`. The `.onDrop(of: [.text], …)` modifier currently attached to that Button must be preserved — attach it to the `SidebarSectionHeader` invocation.
- **D-04**: Extend `CollapsibleVStackSection` (`wrangle/Components/CollapsibleSection.swift`) with the same optional `count: Int?` param. Apply to: Terminal Sessions (`terminalSessions.count`), outer Browsers (`browserTabs.count`), nested Bookmarks (`projectBrowserBookmarks.count`), Open Files (`documentTabs.count`), Locations (`projectBookmarks.count`). Todos section does NOT show a count.
- **D-05**: Chevron animation — keep `withAnimation(.snappy(duration: 0.15))` in `SidebarSectionHeader` and `withAnimation(.snappy(duration: 0.18))` in `CollapsibleSection` (existing values).

**Scratch Pad + Bookmark keyboard parity (UIX-21)**

- **D-06**: Selection model — SwiftUI `List(selection:)` binding. Add a shared selection `@State` in `SidebarView` (enum over `ScratchPadRowID` / `BookmarkRowID` cases, or typed `Hashable` ID wrapper). Rows declare `.tag(…)`. **Fallback:** if `List(selection:)` across multiple `Section`s proves flaky, fall back to per-section `@State` scoped to ScratchPadSection and NestedBookmarkSubSection — keyboard contract stays identical.
- **D-07**: Return on a selected row = rename.
  - ScratchPadRow: enter inline rename mode (`renamingURL = pad.url`).
  - BookmarkRow: open `BookmarkEditSheet` (sets `editing = bookmark`).
- **D-08**: Delete on a selected row = delete with `.alert()` confirmation.
  - Scratch Pad: `"Move '\(pad.name)' to Trash?"` + destructive "Move to Trash" + "Cancel".
  - Bookmark: `"Delete bookmark '\(displayName)'?"` + destructive "Delete" + "Cancel".
- **D-09**: Context-menu "Delete" stays **immediate** on both row types (no confirmation).
- **D-10**: Scratch Pad file delete moves to Trash via `NSWorkspace.shared.recycle([url])` (or equivalent Trash API). User can recover from Finder Trash.
- **D-11**: BookmarkRow's hover-based `DeleteKeyHandler` struct at `NestedBookmarkSubSection.swift:336-349` is **removed entirely**. Don't extract — it's going away.
- **D-12**: Rename-commit behavior on Scratch Pads stays as-is. Selection must clear after rename commits.

**`@AppStorage` key audit (UIX-22)**

- **D-13**: No UserDefaults migration — v1.2 hasn't shipped, dev-local orphans are harmless.
- **D-14**: Extract all 11 existing `@AppStorage` literals into two constants files:
  - `wrangle/Components/SidebarStorageKeys.swift` — enum with static lets (5 entries).
  - `wrangle/Components/OverviewStorageKeys.swift` — enum with static funcs taking `projectID` (6 entries).
  - All 11 call sites rewire to reference the constants.
- **D-15**: Document the naming convention in `CLAUDE.md`:
  - Sidebar section expansion: `sidebar.<section>.expanded` (global, not per-project).
  - Overview section expansion: `overview.<section>.expanded.<projectID>` (per-project).
  - Nested sub-sections: append sub-segment (e.g., `sidebar.browsers.bookmarks.expanded`).

**UIX-23 regression guard**

- **D-16**: No runtime assertion, no unit test, no wrapper view. Phase 11 swept existing violations; Phase 12 verifies by manual grep sweep.
- **D-17**: CLAUDE.md rule: **"Sidebar and Project Overview sections must hide when empty. Never render a section header with an inline empty-state row ('No X yet', 'Nothing here', etc.) inside its body."**

### Claude's Discretion

- Exact placement of `SidebarStorageKeys.swift` / `OverviewStorageKeys.swift` (`Components/` default; `Storage/` or `Constants/` acceptable).
- Whether `OverviewStorageKeys` uses static funcs or a namespace-style formatter.
- Whether `SidebarSectionHeader.count` defaults to nil with `if let count`, or uses `count: Int = 0` + `if count > 0`.
- Whether to extract a shared `ConfirmDeleteAlert` view modifier or duplicate `.alert()` inline.
- Selection-binding type (enum over row IDs vs `AnyHashable`).
- Rename text field selection on entry — select-all on entry (Finder convention) suggested.
- Whether `NestedBookmarkSubSection`'s `Group` scope needs adjustment after header swap (likely no change).

### Deferred Ideas (OUT OF SCOPE)

- Overview count badge on Todos card.
- Shared `ConfirmDeleteAlert` view modifier (two sites is borderline).
- Unit test for `@AppStorage` naming convention.
- Helper wrapper view for hide-when-empty (`HideWhenEmptySection<Body>`).
- Runtime debug assertion against empty Section bodies.
- Dev-only menu "Reset sidebar/overview expansion state".
- Promoting selection to all sidebar sections (Browsers rows, Locations, Other Sessions, Overview row).
- Per-site UserDefaults migration for orphan pre-Phase-11 keys.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UIX-20 | All sidebar section headers use a single `SidebarSectionHeader` treatment (font size, foreground color, chevron size, row height, horizontal insets) — no per-section visual overrides remain. | Patterns A + B below: extend `SidebarSectionHeader` with `count: Int?`; extend `CollapsibleVStackSection` with the same; replace bespoke `NestedBookmarkSubSection` inline header (`:39-59`). Exact pixel parity values verified in codebase audit (section "Existing SidebarSectionHeader call sites"). |
| UIX-21 | Scratch Pads rows support the same rename (Return) and delete (Delete / context-menu) affordances already available on Bookmarks rows. | Pattern C below: `List(selection:)` at SidebarView scope with enum-based typed row ID; Return → rename (ScratchPad inline TextField or BookmarkEditSheet); Delete → `.alert()` confirm → actual delete. Existing `renamingURL` + `renameText` + `commitRename` pipeline at `ScratchPadSection.swift:59-83` is reusable as-is. |
| UIX-22 | Expansion state for every collapsible sidebar section is persisted via `@AppStorage` using the `sidebar.<section>.expanded` key convention. | Audit verified: all 11 keys already compliant. Create `SidebarStorageKeys.swift` + `OverviewStorageKeys.swift` to extract literals; rewire all 11 call sites (enumerated in "Existing `@AppStorage` Inventory" section). |
| UIX-23 | No section renders both a header row and an inline empty-state row. | Audit verified: zero matches for `Text("No \w+ yet"` / `"Nothing "` / `"Empty "` inside section bodies. Single approved usage is `ProjectOverviewView.emptyHero`. Land CLAUDE.md rule (D-17 wording). |

</phase_requirements>

## Summary

Phase 12 is a normalization + audit pass over shared UI components that Phases 10-11 stabilized. Four targeted deliverables:

1. Extend two shared SwiftUI components (`SidebarSectionHeader`, `CollapsibleVStackSection`) with an optional `count: Int?` parameter, then rewire ~10 call sites. Zero visual drift risk — count styling is `.font(.system(size: 10))` + `.foregroundStyle(.tertiary)`, verbatim from the existing bespoke bookmark sub-header.
2. Replace the hover-based keyboard delete pattern (`DeleteKeyHandler` + `.focusable(onHover)`) with selection-driven affordances (`List(selection:)` + `.onKeyPress(.return)`/`.onKeyPress(.delete)` or `.onDeleteCommand`) for both Scratch Pad rows and Bookmark rows. Scratch Pad already has an inline rename flow; BookmarkEditSheet already exists for bookmarks — only the **trigger** changes.
3. Extract all 11 existing `@AppStorage` expansion-key literals into two constants files for drift prevention. No runtime behavior change.
4. Document two invariants in CLAUDE.md (storage-key naming + hide-when-empty). No code enforcement.

**The one real technical risk** is the single research gap the CONTEXT flagged: SwiftUI `List(selection:)` across multiple `Section`s on macOS has a history of quirky behavior (visual glitches when selection state transitions between sections, programmatic-clear flicker). The Apple Developer Forums and community reports confirm this is real, not folklore. Phase 11 shipped no `List(selection:)` code in this app — this is the first phase adding a selection binding to the sidebar List. Mitigation: enum-based typed row ID (canonical pattern), Wave 0 spike to validate the binding works, documented fallback to per-section `@State` if it doesn't.

**Primary recommendation:** Extend the two shared components first (low-risk, pure additions with `Int? = nil` defaults), rewire all 11 call sites, then introduce the selection binding in a Wave 0 spike before wiring Return/Delete handlers. Land the CLAUDE.md invariants last so the Phase 12 SUMMARY references the finalized storage-key convention.

## Architectural Responsibility Map

Single-tier app (native macOS SwiftUI). The "tier" column below maps each phase capability to the layer of the codebase that owns it.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical section header (count-when-collapsed) | Shared SwiftUI components (`wrangle/Components/`) | — | `SidebarSectionHeader` + `CollapsibleVStackSection` are the two shared view primitives; Phase 12 is strictly additive to both. Not a view-level concern — belongs at the component level. |
| Selection-driven keyboard affordances | Sidebar / View layer (`wrangle/Sidebar/SidebarView.swift` owns the List, `ScratchPadSection` + `NestedBookmarkSubSection` own rows) | — | SwiftUI `List(selection:)` is a List-scope binding. Selection state lives in SidebarView (the List's owner). Row-level keyboard handlers attach to the rows. Not a model-layer concern (no business logic changes). |
| Scratch Pad Trash move | Model layer (`wrangle/Models/ScratchPadManager.swift`) | — | File-system mutation is a data-layer concern. `ScratchPadManager.deleteScratchPad(at:)` already owns this; Phase 12 only changes the underlying API (`FileManager.trashItem` → `NSWorkspace.shared.recycle`). No callers change. |
| Bookmark delete | Model layer (`wrangle/Browser/Bookmarks/BookmarkStore.swift`) | — | SwiftData delete via `BookmarkStore.remove(_:)` is already the data-layer primitive. No changes to the store; only the trigger path (keyboard + `.alert()` confirm) changes at the view layer. |
| `@AppStorage` key constants | Shared components (`wrangle/Components/`) | App-wide convention (CLAUDE.md) | Constants are Swift statics, no runtime concern. Placement next to the components that consume them keeps discoverability high. |
| Hide-when-empty invariant | Documentation (`CLAUDE.md`) | Developer practice | D-17 is a rule, not code. No tier owns it; it's enforced by reviewer awareness + phase-12 grep sweep. |

## Project Constraints (from CLAUDE.md)

Extracted from `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/CLAUDE.md` — planner must honor these with the same authority as locked decisions:

- **Swift 5.9+, SwiftUI, macOS 15+ (Sequoia).** Target macOS 14.0+ per build settings (verified via `xcodebuild -list`), but the CLAUDE.md copy says macOS 15+. Planner should not introduce APIs gated to macOS 26 (Tahoe) without `#available` fallback.
- **Use Swift modern concurrency** (`async/await`, `@Observable`, `@MainActor`).
- **Every `@Observable` class MUST have `@MainActor`.** Applies to `ScratchPadManager` (already conforms). No new `@Observable` classes introduced this phase.
- **`@State` must be `private`.** Applies to the new `selection: Selection?` binding in `SidebarView`.
- **Use `@Environment(AppState.self)` for DI**, not init params.
- **Prefer value types (structs); classes only when needed.** All new components in Phase 12 are structs (views) or enums (constants + selection type).
- **Keep views under ~80 lines — extract subviews beyond that.** Audit note: `NestedBookmarkSubSection.swift` is ~350 lines (file, not a single view); Phase 12 **removes** `DeleteKeyHandler` (-14 lines) and the bespoke inline header (-20 lines). Plan should note this trimming.
- **Use `Button` over `onTapGesture`; `.clipShape()` over `.cornerRadius()`.** Applies to any new UI code (none required).
- **Cache `NSRegularExpression` as `static let` — never create in hot paths.** N/A this phase.
- **Task-based debouncing, not `DispatchWorkItem`.** N/A this phase.
- **Use `MainActor.run` / `Task { @MainActor in }`, not `DispatchQueue.main.async`.** N/A this phase (the existing `NSWorkspace.shared.recycle` completion handler, if used, will need a `Task { @MainActor in }` wrapper to hop back — see Pitfall 2).
- **Never sync file I/O on main thread.** Current `deleteScratchPad` uses `FileManager.trashItem` synchronously on MainActor. If switching to `NSWorkspace.shared.recycle(_:completionHandler:)`, the async variant actually **improves** this; if staying with `trashItem`, current behavior is preserved.
- **Never force unwrap except static regex `try!`.** N/A.
- **SwiftUI App lifecycle.** Confirmed.
- **Do NOT use document-based app template.** Confirmed.
- **`NavigationSplitView` for sidebar/editor layout.** Already in use; no change.
- **`fileSystemSynchronizedRootGroup` is in use.** Verified in `Wrangle.xcodeproj/project.pbxproj:17-23, 68-70`. **No pbxproj edits required** for new files. Creating `SidebarStorageKeys.swift` and `OverviewStorageKeys.swift` under `wrangle/Components/` will auto-include them in the target.

## Standard Stack

### Core

| Library / API | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| SwiftUI | macOS 15+ (Sequoia) | View framework, `List(selection:)`, `.alert`, `.onKeyPress`, `.sheet(item:)`, `@AppStorage` | Native platform UI. Already app baseline. [CITED: developer.apple.com/documentation/swiftui] |
| SwiftData | macOS 14+ | `@Model`, `@Query`, `modelContext.delete` for bookmark CRUD | Already app baseline since v1.0; bookmarks are `@Model`s (Phase 5). [CITED: developer.apple.com/documentation/swiftdata] |
| Foundation `FileManager` | macOS 10+ | `FileManager.trashItem(at:resultingItemURL:)` for Scratch Pad Trash | Currently in use at `ScratchPadManager.swift:80`. [CITED: developer.apple.com/documentation/foundation/filemanager/1414306-trashitem] |
| AppKit `NSWorkspace` | macOS 10+ | `NSWorkspace.shared.recycle(_:completionHandler:)` — UI-SPEC target for D-10 | D-10 names this as the Trash API. Note: existing code already moves to Trash via `trashItem`; both APIs are valid. See Pitfall 2. [CITED: developer.apple.com/documentation/appkit/nsworkspace/recycle(_:completionhandler:)] |

### Supporting

| Library / API | Version | Purpose | When to Use |
|---------------|---------|---------|-------------|
| SwiftUI `@AppStorage` | macOS 11+ | `UserDefaults`-backed persistent state | Already used for all 11 section-expansion keys. [VERIFIED: codebase audit, grep `@AppStorage` returns 18 total call sites across 11 relevant; see "@AppStorage Inventory" section] |
| SwiftUI `.onKeyPress(_:action:)` | macOS 14+ (Sonoma) | Keyboard event handling on focusable views | For Return/Delete on a selected row — if NOT using `.onDeleteCommand`. Requires `.focusable()` or inherited focus from `List(selection:)`. [CITED: developer.apple.com/documentation/swiftui/view/onkeypress(_:action:)-7jvlw, requires macOS 14+] |
| SwiftUI `.onDeleteCommand(perform:)` | macOS 10.15+ | System Delete-command (Edit → Delete, ⌫, ⌦) on focused list | For Delete-on-List — macOS-native alternative to `.onKeyPress(.delete)`. **Triggers on Delete key when List has focus** [CITED: Apple docs + swiftdevjournal.com]. This is the canonical macOS idiom; prefer over `.onKeyPress(.delete)` attached to rows. |
| SwiftUI `.tag(_:)` | macOS 10.15+ | Associates a hashable identity with a row for `List(selection:)` | Every Scratch Pad and Bookmark row must declare `.tag(Selection.scratchPad(pad.url))` / `.tag(Selection.bookmark(bookmark.id))`. |
| SwiftUI `.alert(_:isPresented:presenting:actions:message:)` | macOS 12+ | Destructive confirmation alerts | D-08 target. Takes an optional `presenting` value — idiomatic pattern for injecting the pad/bookmark name into the alert title. |
| SwiftUI `.focusable()` | macOS 10.15+ | Makes a view keyboard-focusable | Only needed if `.onKeyPress` is attached to individual rows without `List(selection:)` inheritance. With `List(selection:)` the list itself is focusable; `.onKeyPress` on the List picks up key events when a row is selected. |
| SwiftUI `@FocusState` | macOS 12+ | Tracks/sets input focus programmatically | For the inline Scratch Pad rename TextField — `@FocusState private var isRenameFocused: Bool` + `.focused($isRenameFocused)` + set to `true` when entering rename. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `List(selection:)` binding at SidebarView scope | Per-section `@State` (fallback) | Keyboard contract identical. Falls back when heterogeneous-sections selection is glitchy. Documented in D-06 as acceptable deviation. |
| Enum over row IDs for selection type | `AnyHashable` | Enum gives type safety + `switch` exhaustiveness for the Return/Delete handlers; `AnyHashable` is lighter but loses compile-time checking when the handler branches on row type. **Recommendation: enum.** [CITED: nilcoalescing.com/blog/ListSelectionForNavigation] |
| `.onKeyPress(.delete)` attached to each row | `.onDeleteCommand` attached to the List | `.onDeleteCommand` is the canonical macOS idiom — wires to Edit → Delete menu + ⌫/⌦ keys when List has focus. Per-row `.onKeyPress(.delete)` requires focus plumbing and can miss events if focus moves. **Recommendation: `.onDeleteCommand` on the List.** [CITED: swiftdevjournal.com/removing-items-from-swiftui-lists-in-mac-apps/] Branch on `selection` inside the handler to dispatch to Scratch Pad or Bookmark delete path. |
| `.onKeyPress(.return)` attached to each row | `.onKeyPress(.return)` at List scope | Same reasoning — List scope works cleanly with `List(selection:)`. Branch on selection to decide rename destination. |
| `NSWorkspace.shared.recycle([url], completionHandler:)` for Trash | Existing `FileManager.default.trashItem(at:resultingItemURL:)` | Both move to Trash. `NSWorkspace.recycle` is async with a completion handler (older callback-style); `trashItem` is synchronous + throws. The existing code uses `trashItem`. D-10 specifies `NSWorkspace.recycle` but admits "(or equivalent)". **Recommendation: keep `trashItem` — it's already in place, synchronous, throws, and aligns with Swift idioms.** Apple itself recommends `trashItem` for new Swift code. Document the equivalence in the plan. [CITED: both Apple developer docs; christiantietze.de] |
| Static funcs on `OverviewStorageKeys` | `String`-interpolating namespace-style formatter | Both produce identical runtime strings; static funcs give named, discoverable call sites. **Recommendation: static funcs** (e.g., `OverviewStorageKeys.browsersExpanded(projectID)`). Matches Swift's enum-namespace pattern already used elsewhere (`SecurityScopedBookmark`). |
| `count: Int? = nil` + `if let count, !isExpanded` | `count: Int = 0` + `if count > 0 && !isExpanded` | Optional pattern is more explicit — `nil` means "don't show a count" regardless of value; `0` overloads "no count" with "empty section" (but empty sections hide entirely per Phase 11, so unreachable anyway). **Recommendation: `Int?` with default `nil`.** |

### Version Verification

Package versions (resolved Swift packages in the Xcode project): [VERIFIED: `xcodebuild -list` output 2026-04-20]

- SwiftTerm: 1.11.2 — not touched by Phase 12.
- swift-argument-parser: 1.7.0 — not touched by Phase 12.
- No new packages required for Phase 12.

macOS target version is Apple-defined; no npm-equivalent registry check needed. SwiftUI and AppKit APIs cited above are all available at macOS 14.0+ (documented in Apple's availability markers).

## Architecture Patterns

### System Architecture Diagram

Data flow for Phase 12's three interactive domains (count display, selection-driven keyboard, storage-key constants):

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        SwiftUI View Hierarchy (macOS 15)                 │
└──────────────────────────────────────────────────────────────────────────┘

                 ┌─────────────────────────────────────┐
                 │           SidebarView               │
                 │  (@State selection: Selection?)     │
                 │  (owns List(selection:) binding)    │
                 └─────────────┬───────────────────────┘
                               │ .onKeyPress(.return) / .onDeleteCommand
                               │ Branches on selection (enum switch)
                 ┌─────────────┴───────────────────────┐
                 │       List { Section { … } }        │
                 └─────────────┬───────────────────────┘
                               │
          ┌────────────────────┼───────────────────────┐
          │                    │                       │
          ▼                    ▼                       ▼
 ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────────┐
 │ ScratchPadSection│  │ BrowserSessions │  │ other sections (no      │
 │                  │  │ Section         │  │ selection: Browsers tab │
 │ Rows:            │  │                 │  │ rows, Locations, Other  │
 │  padRow(pad).tag │  │ NestedBookmark  │  │ Sessions, Overview row) │
 │  (.scratchPad)   │  │ SubSection      │  │                         │
 │                  │  │                 │  │                         │
 │  renameRow(pad)  │  │ BookmarkRow.tag │  │                         │
 │  (inline         │  │  (.bookmark)    │  │                         │
 │   TextField)     │  │                 │  │                         │
 └──────┬───────────┘  └────────┬────────┘  └──────────────────────────┘
        │                       │
        ▼                       ▼
  ┌──────────────────┐   ┌──────────────────┐
  │ ScratchPadManager│   │ BookmarkStore    │
  │                  │   │                  │
  │ deleteScratchPad │   │ remove(bookmark) │
  │   → trashItem    │   │   → modelContext │
  │   (Trash)        │   │     .delete      │
  └──────────────────┘   └──────────────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │    SwiftData     │
                         │   (BrowserBook-  │
                         │    mark @Model)  │
                         └──────────────────┘


┌──────────────────────────────────────────────────────────────────────────┐
│                   Count display (UIX-20 parity)                          │
└──────────────────────────────────────────────────────────────────────────┘

 Section data source ──→  count: Int? passed to ──→ Shared header renders
 (@Query / computed      SidebarSectionHeader OR     Text("\(count)") when
  prop / in-view         CollapsibleVStackSection    count != nil && !isExpanded
  filter)                                             (.font(.system(size:10))
                                                      .foregroundStyle(.tertiary))


┌──────────────────────────────────────────────────────────────────────────┐
│                   AppStorage constants (UIX-22)                          │
└──────────────────────────────────────────────────────────────────────────┘

  Call site @AppStorage(...)  ──→  references  ──→  SidebarStorageKeys.* or
                                                     OverviewStorageKeys.*(projectID)
                                                            │
                                                            ▼
                                                     UserDefaults(name: key)
```

### Recommended File Layout (delta from current)

```
wrangle/
├── Components/
│   ├── SidebarSectionHeader.swift         # EDIT — add count: Int? param
│   ├── CollapsibleSection.swift           # EDIT — add count: Int? to both inits
│   ├── SidebarStorageKeys.swift           # NEW — 5 static let constants
│   └── OverviewStorageKeys.swift          # NEW — 6 static funcs taking projectID
├── Sidebar/
│   ├── SidebarView.swift                  # EDIT — @State selection; rewire 4 @AppStorage
│   └── ScratchPadSection.swift            # EDIT — Return/Delete handlers; .tag(.scratchPad)
├── Browser/Bookmarks/
│   └── NestedBookmarkSubSection.swift     # EDIT — replace bespoke header; delete DeleteKeyHandler; .tag(.bookmark)
├── Features/Dashboard/
│   └── ProjectOverviewView.swift          # EDIT — pass count: to 5 non-Todos cards; rewire 6 @AppStorage
├── Models/
│   └── ScratchPadManager.swift            # EDIT — swap Trash API (optional — see Pitfall 2)
CLAUDE.md                                  # EDIT — two new rule blocks
```

### Pattern A — Extended `SidebarSectionHeader` with optional count

**What:** Add `count: Int?` param (default `nil`). Render count only when `count != nil && !isExpanded`.

**When to use:** Every sidebar section header (5 call sites). Count is rendered inside the existing `Button` label `HStack(spacing: 4)`, after the title `Text`, before the outer `Spacer`.

**Example:**

```swift
// Source: 12-UI-SPEC.md Pattern A + existing SidebarSectionHeader.swift + NestedBookmarkSubSection.swift:44-56
struct SidebarSectionHeader: View {
    let title: String
    @Binding var isExpanded: Bool
    let count: Int?  // NEW — default nil via a convenience init or explicit nil at call sites

    init(title: String, isExpanded: Binding<Bool>, count: Int? = nil) {
        self.title = title
        self._isExpanded = isExpanded
        self.count = count
    }

    var body: some View {
        HStack(spacing: 4) {
            Button {
                withAnimation(.snappy(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    Text(title)
                    if let count, !isExpanded {
                        Text("\(count)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}
```

### Pattern B — Extended `CollapsibleVStackSection` with optional count

**What:** Add `count: Int?` to both initializers (primary with `accessory:`, and the `Accessory == EmptyView` convenience). Render identically to Pattern A.

**Example:**

```swift
// Source: 12-UI-SPEC.md Pattern B + existing CollapsibleSection.swift
init(
    _ title: String,
    storageKey: String,
    count: Int? = nil,                 // NEW
    defaultExpanded: Bool = true,
    @ViewBuilder accessory: @escaping () -> Accessory,
    @ViewBuilder content: @escaping () -> Content
) {
    // existing assignments + self.count = count
}

// Inside body's HStack(spacing: 8):
HStack(spacing: 6) {
    Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .rotationEffect(.degrees(isExpanded ? 90 : 0))
    Text(title)
        .font(.headline)
        .foregroundStyle(.secondary)
    if let count, !isExpanded {
        Text("\(count)")
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
    }
}
```

### Pattern C — Selection-driven keyboard handling (macOS-canonical)

**What:** `List(selection:)` binding at `SidebarView` scope, enum over row types. `.onDeleteCommand` + `.onKeyPress(.return)` attached to the `List`. Handlers branch on `selection` to dispatch to Scratch Pad or Bookmark flows.

**When to use:** For Phase 12, only Scratch Pad rows + nested Bookmark rows. Other sections' rows (Browser tabs, Locations, Orphaned Sessions, Overview row) do NOT tag for selection (per D-06 blast-radius limit).

**Example:**

```swift
// Source: nilcoalescing.com (enum pattern) + swiftdevjournal.com (onDeleteCommand) + codebase context
enum SidebarSelection: Hashable {
    case scratchPad(URL)      // URL is Hashable, unique per pad file
    case bookmark(String)     // BrowserBookmark.id (String, Hashable)
}

struct SidebarView: View {
    @State private var selection: SidebarSelection?
    @State private var pendingDelete: SidebarSelection?
    @State private var showDeleteAlert: Bool = false
    // ... existing state ...

    var body: some View {
        List(selection: $selection) {          // NEW: selection binding
            // ... existing sections ...
            Section {
                if isScratchPadsExpanded {
                    ScratchPadSection()        // rows inside declare .tag(.scratchPad(pad.url))
                }
            } header: {
                SidebarSectionHeader(
                    title: "Scratch Pads",
                    isExpanded: $isScratchPadsExpanded,
                    count: visiblePads.count
                )
            }
            // ...
        }
        .onKeyPress(.return) {
            guard let selection else { return .ignored }
            switch selection {
            case .scratchPad(let url): enterRename(for: url)
            case .bookmark(let id):    openEditSheet(for: id)
            }
            return .handled
        }
        .onDeleteCommand {
            guard let selection else { return }
            pendingDelete = selection
            showDeleteAlert = true
        }
        .alert(
            alertTitle(for: pendingDelete),
            isPresented: $showDeleteAlert,
            presenting: pendingDelete
        ) { pending in
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button(destructiveLabel(for: pending), role: .destructive) {
                performDelete(pending)
                selection = nil  // D-12: clear selection after delete
                pendingDelete = nil
            }
        }
    }
}
```

Inside `ScratchPadSection`, rows declare `.tag(SidebarSelection.scratchPad(pad.url))`. Inside `NestedBookmarkSubSection`, `BookmarkRow` declares `.tag(SidebarSelection.bookmark(bookmark.id))`. The `.tag(_:)` modifier is what wires rows into the List's selection binding. Without it, `List(selection:)` can't correlate row identity with the binding's value type.

**Selection clear on rename commit** (D-12): when the Scratch Pad rename `TextField` fires `onCommit`, set `selection = nil` alongside `renamingURL = nil`. Same when `BookmarkEditSheet` dismisses (via `.sheet(item: $editing)` with `onDismiss:` — clear selection there).

**Focus requirement:** The `List` itself is keyboard-focusable in SwiftUI on macOS — no manual `.focusable()` needed when using `List(selection:)`. When the user clicks a row, the List takes focus, and `.onDeleteCommand`/`.onKeyPress` fire as expected. [CITED: swiftjectivec.com/Handling-Keyboard-Presses-in-SwiftUI-for-macOS]

### Pattern D — Destructive confirmation alert with `presenting:`

**What:** Use `.alert(_:isPresented:presenting:actions:message:)` or `.alert(_:isPresented:presenting:actions:)` (no message) — the `presenting:` closure receives the unwrapped optional, which lets you interpolate the pad/bookmark name into the title without capturing `@State` inside the button actions.

**Example:**

```swift
// Source: Apple SwiftUI docs + existing ContentView.swift:139-160 pattern
.alert(
    "Move '\(pad.name)' to Trash?",     // ASCII single-quote; D-08 verbatim
    isPresented: $showDeleteAlert,
    presenting: pendingDelete
) { pending in
    Button("Cancel", role: .cancel) { pendingDelete = nil }
    Button("Move to Trash", role: .destructive) {
        deleteScratchPad(pending)
        pendingDelete = nil
    }
}
```

**Note:** The `title:` parameter is a `LocalizedStringKey` that SwiftUI evaluates **before** the `presenting:` closure runs. To dynamically interpolate the name, either (a) compute the title from the tracked `pendingDelete` outside the modifier and pass the computed string, or (b) use the two-alert pattern (one alert per row type) to keep the title string static per alert surface. The UI-SPEC's copy spec (D-08 exact wording) forces approach (a) — compute the title string from `pendingDelete`. This is a standard SwiftUI idiom; the existing "Close Terminal?" alert in `ContentView.swift:139-160` does exactly this.

### Pattern E — `@AppStorage` key constants

**What:** Enum namespace for storage keys. Sidebar keys are static lets. Overview keys are static funcs (take `projectID`) returning the interpolated string.

**Example:**

```swift
// Source: CLAUDE.md coding-patterns.md section 6 (enum-based namespaces) + D-14
enum SidebarStorageKeys {
    static let locationsExpanded          = "sidebar.locations.expanded"
    static let scratchPadsExpanded        = "sidebar.scratchPads.expanded"
    static let browsersExpanded           = "sidebar.browsers.expanded"
    static let otherSessionsExpanded      = "sidebar.otherSessions.expanded"
    static let browserBookmarksExpanded   = "sidebar.browsers.bookmarks.expanded"
}

enum OverviewStorageKeys {
    static func todosExpanded(_ projectID: String)            -> String { "overview.todos.expanded.\(projectID)" }
    static func sessionsExpanded(_ projectID: String)         -> String { "overview.sessions.expanded.\(projectID)" }
    static func browsersExpanded(_ projectID: String)         -> String { "overview.browsers.expanded.\(projectID)" }
    static func browserBookmarksExpanded(_ projectID: String) -> String { "overview.browsers.bookmarks.expanded.\(projectID)" }
    static func documentsExpanded(_ projectID: String)        -> String { "overview.documents.expanded.\(projectID)" }
    static func locationsExpanded(_ projectID: String)        -> String { "overview.locations.expanded.\(projectID)" }
}
```

**Rewire:**

```swift
// Before:
@AppStorage("sidebar.locations.expanded") private var isLocationsExpanded: Bool = true
// After:
@AppStorage(SidebarStorageKeys.locationsExpanded) private var isLocationsExpanded: Bool = true

// Before:
CollapsibleVStackSection("Terminal Sessions", storageKey: "overview.sessions.expanded.\(projectID)") { … }
// After:
CollapsibleVStackSection("Terminal Sessions", storageKey: OverviewStorageKeys.sessionsExpanded(projectID)) { … }
```

No runtime behavior changes — same key strings, same default values.

### Anti-Patterns to Avoid

- **Don't attach `.onKeyPress(.delete)` to individual rows with `.focusable(onHover)`.** That's the existing `DeleteKeyHandler` pattern Phase 12 is explicitly removing (D-11). Using row-scoped `.onKeyPress` requires hover-focus (brittle) and conflicts with `List(selection:)`. Use `.onDeleteCommand` on the List instead.
- **Don't inline-filter inside `ForEach`.** Existing code in `ScratchPadSection.visiblePads` correctly prefilters; Phase 12 should not introduce new inline filters. [CITED: .claude/skills/swiftui-expert-skill/references/list-patterns.md]
- **Don't use `Text(verbatim:)` for the count.** `Text("\(count)")` — standard interpolation — matches Phase 11's shipped bespoke sub-header verbatim.
- **Don't wrap count display in its own `HStack`.** It lives inside the existing `HStack(spacing: 4)` (sidebar) / `HStack(spacing: 6)` (overview) that already holds chevron + title. Matches `NestedBookmarkSubSection.swift:44-56` exactly.
- **Don't use `.caption2`, `.caption`, `.footnote`, or any dynamic-type role for the count.** D-01 / D-04 specify `.font(.system(size: 10))` literal pt. Dynamic-type scaling would drift from the established pixel size.
- **Don't promote the `selection` binding into `AppState`.** It's view-scoped ephemeral state; belongs in `SidebarView` as `@State private var`. Per CLAUDE.md: "`@State` must be `private`."
- **Don't use `onTapGesture` to toggle expansion.** The existing `Button { … }` pattern is correct and is the only compliant path.
- **Don't force-unwrap `SidebarSelection` cases.** Use `switch` for exhaustive handling.
- **Don't skip selection-clear after rename/delete.** D-12 invariant — subsequent Return on a stale selection re-enters rename on a row that may no longer exist.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Move file to Trash | Custom recursive move to `~/.Trash` via `FileManager.moveItem` | `FileManager.default.trashItem(at:resultingItemURL:)` (existing) OR `NSWorkspace.shared.recycle(_:completionHandler:)` | Both handle volume-crossing, permissions, "Put Back" metadata, APFS semantics. Hand-rolled moves break Put Back and fail across volumes. [CITED: Apple docs] |
| Keyboard event handling on List rows | NSEvent local monitor | `.onKeyPress` / `.onDeleteCommand` modifiers | NSEvent monitors are process-scoped, leak into other windows, require explicit add/remove in lifecycle hooks. SwiftUI's modifier owns lifecycle. |
| Destructive confirmation UI | Custom sheet with buttons | `.alert(_:isPresented:presenting:actions:message:)` | Handles VoiceOver, button roles (destructive = red text), system-managed button order (destructive trailing on macOS). |
| Selection-across-heterogeneous-Sections | Multiple parallel `@State` with manual sync | `List(selection:)` + typed enum tag | SwiftUI auto-manages highlight rendering, accessibility state, arrow-key navigation. Manual sync drifts and breaks VoiceOver. |
| Per-project storage key composition | Manual string concat scattered across call sites | `OverviewStorageKeys.<section>(projectID)` static funcs | D-14/D-15. One place to enforce the naming pattern. |
| `@AppStorage` literal drift detection | Custom runtime assertion / linter rule | Constants file (this phase) + CLAUDE.md convention | Structural enforcement. Compiler fails the build if a key is misspelled; no runtime cost. |
| SwiftUI focus plumbing for rename TextField | Manual `@State` focus flag + `DispatchQueue.main.asyncAfter` delay | `@FocusState private var isRenameFocused: Bool` + `.focused($isRenameFocused)` + set in an `onChange(of: renamingURL)` hook | FocusState is SwiftUI's first-class mechanism; avoids race conditions. |

**Key insight:** Phase 12 is a refactor phase; the "Don't hand-roll" column mostly enumerates patterns the codebase is already following (the existing `DeleteKeyHandler` + `.focusable` is the ONE place it's hand-rolling, and Phase 12 is removing that in favor of the canonical `.onDeleteCommand`).

## Common Pitfalls

### Pitfall 1: `List(selection:)` visual glitches with heterogeneous Sections on macOS

**What goes wrong:** When two `Section`s contribute selectable rows with different ID types, selection can leak (wrong row highlighted) or flicker (highlight briefly appears on both) as selection transitions between sections. Apple Developer Forums and community reports confirm this class of bug persists across macOS Sonoma and Sequoia. [CITED: developer.apple.com/forums/thread/739118 (Section expansion bug), forum-confirmed selection issues with NavigationLink / typed tags]

**Why it happens:** SwiftUI's List on macOS composes its selection rendering from AppKit's `NSTableView` / `NSOutlineView`. The bridge to SwiftUI tags is imperfect when the tag type is `AnyHashable` (erased) or when tag values from different sections share the same underlying hash.

**How to avoid:**
1. Use a **strongly-typed enum** for the selection type (not `AnyHashable`). The enum cases use different associated-value types (URL vs String), so hashes are distinct and visually distinct.
2. Validate the binding in a Wave 0 spike **before** wiring the handlers. A 15-minute task: select a pad, select a bookmark, select back, use arrow keys across the section boundary, clear via Esc. If the highlight tracks correctly, proceed. If not, fall back per D-06.
3. Ensure `.listStyle(.sidebar)` is retained (already the case at `SidebarView.swift:107`) — default `.inset` or `.plain` style may exhibit different selection behavior.
4. Do NOT put selection-dependent rows in the same Section as non-selectable rows. The two selectable sections (Scratch Pads, nested Bookmarks) are already in distinct Section scopes — this is already correct.

**Warning signs:**
- Selection highlight persists on a row after it's been deleted.
- Arrow keys jump selection to an unexpected section.
- Selection highlight appears "muted" or "wrong color" — might indicate it's using the inactive-row highlight style because the List lost focus.
- Xcode View Debugger shows multiple `NSTableRowView` in selected state.

### Pitfall 2: Dual Trash API confusion (`FileManager.trashItem` vs `NSWorkspace.recycle`)

**What goes wrong:** D-10 says "switch from `FileManager.removeItem` to `NSWorkspace.shared.recycle([url])`." But a codebase audit shows `ScratchPadManager.deleteScratchPad(at:)` **already uses `FileManager.default.trashItem(at: url, resultingItemURL: nil)` with a `removeItem` fallback in the `catch` branch** (`ScratchPadManager.swift:78-85`). The current code **already moves to Trash**. So the planner may interpret D-10 as "nothing to change" and skip it, OR as "literally swap to `NSWorkspace.recycle`" and introduce an async API where a sync API is working.

**Why it happens:** CONTEXT.md uses `NSWorkspace.shared.recycle` as shorthand for "the Trash API." The distinction between the two Trash APIs wasn't surfaced during discuss-phase.

**How to avoid:**
- Document the equivalence in the plan: both APIs move to Trash.
- **Recommendation: keep `FileManager.default.trashItem` (the existing code).** Reasons:
  1. Synchronous + throwing (Swift-idiomatic).
  2. Apple itself recommends `trashItem` for new Swift code over the older callback-based `recycle`.
  3. No behavior change reduces risk.
  4. Consolidate the behavior into a proper error path: when `trashItem` throws, surface it (log or show a non-blocking error) instead of silently falling back to `removeItem` (which is a **hard delete**). The current fallback at `ScratchPadManager.swift:82` is a latent bug — if Trash fails, the file is **hard-deleted**, which is the opposite of the D-10 intent.
- If the user/planner wants strict D-10 compliance with `NSWorkspace.shared.recycle`, migrate cleanly to async: `recycle(_:completionHandler:)` returns immediately and calls the handler on the main thread; wrap in a `withCheckedContinuation` or similar to maintain synchronous semantics for callers. Flag this as a significant test-surface change.

**Warning signs:**
- Code grep for `removeItem` in the ScratchPad flow finds the fallback branch.
- Unit test asserts the file is hard-deleted (it isn't — it's trashed).
- UAT: after "Delete", the file doesn't appear in Finder Trash. Means the fallback fired.

### Pitfall 3: Alert title interpolation vs static string

**What goes wrong:** `alert(title:isPresented:presenting:actions:)` evaluates the title once at modifier-install time. Interpolating `pad.name` directly inline like `.alert("Move '\(pad.name)' to Trash?", isPresented: …)` uses the `pad` value at compile/install time (often wrong value, or nil).

**Why it happens:** SwiftUI separates the title (eager evaluation) from `presenting:` + `actions:` (lazy-per-presentation). The UI-SPEC copy includes `\(pad.name)` interpolation, which requires the title to see the currently pending deletion.

**How to avoid:**
Two viable patterns:

**(a) Compute title from `@State` (canonical):**

```swift
@State private var pendingDelete: SidebarSelection?
@State private var showAlert: Bool = false

private var alertTitle: String {
    guard let pendingDelete else { return "" }
    switch pendingDelete {
    case .scratchPad(let url):
        let name = appState.scratchPadManager.scratchPads.first { $0.url == url }?.name ?? url.lastPathComponent
        return "Move '\(name)' to Trash?"
    case .bookmark(let id):
        let name = /* resolve display name */
        return "Delete bookmark '\(name)'?"
    }
}

.alert(alertTitle, isPresented: $showAlert, presenting: pendingDelete) { pending in
    Button("Cancel", role: .cancel) { pendingDelete = nil }
    Button(destructiveButtonLabel(pending), role: .destructive) {
        performDelete(pending)
        selection = nil
        pendingDelete = nil
    }
}
```

Because `alertTitle` is a computed property, SwiftUI re-evaluates it whenever `pendingDelete` changes (via state diffing). This works because the view body re-renders when `pendingDelete` is set, and the modifier receives the fresh title on that render pass, just before `isPresented` flips to true.

**(b) Two separate `.alert()` modifiers, one per row type:**

```swift
.alert("Move Scratch Pad to Trash?", isPresented: $showScratchPadAlert, presenting: pendingScratchPad) { pad in
    Button("Cancel", role: .cancel) { pendingScratchPad = nil }
    Button("Move to Trash", role: .destructive) { deletePad(pad); … }
} message: { pad in
    Text("'\(pad.name)' will be moved to Trash.")
}
.alert("Delete Bookmark?", isPresented: $showBookmarkAlert, presenting: pendingBookmark) { bm in
    // …
} message: { bm in
    Text("'\(displayName(bm))' will be removed.")
}
```

Pattern (b) puts interpolation in `message:` (which IS per-presentation) and keeps titles static. The UI-SPEC copy spec uses the pad/bookmark name in the **title**, so pattern (a) is required to match the locked copy.

**Warning signs:**
- Alert title shows stale or empty content.
- Xcode preview / runtime warnings about "Binding action tried to update multiple times per frame."

### Pitfall 4: Selection state not clearing after rename/delete (D-12 violation)

**What goes wrong:** User renames a Scratch Pad by pressing Return. The rename commits, but `selection` still references the old row ID (the pre-rename URL). Pressing Return again immediately re-enters rename mode on the new URL... EXCEPT the `.tag(SidebarSelection.scratchPad(pad.url))` on rows uses the new URL, and the stored `selection` still has the old URL. Now selection points to a non-existent row and SwiftUI may render a stale highlight or crash on lookup.

**Why it happens:** `renameScratchPad` returns a new URL (the file is moved). Rows ForEach re-renders with the new URL in tags; the selection binding is untouched.

**How to avoid:** In `commitRename(from: url)` (existing at `ScratchPadSection.swift:69-83`), after `renamingURL = nil`, also clear the parent's selection. Since selection lives in SidebarView, either:
1. Plumb a `Binding<SidebarSelection?>` into `ScratchPadSection` and set `selection.wrappedValue = nil` after commit.
2. Observe `renamingURL` from SidebarView via a shared `AppState` or `@Binding` and clear selection when it transitions to nil.
3. Simplest: move the selection-clear into SidebarView's handler, by detecting that renamingURL cleared — use `onChange(of: something)` or invert the flow so SidebarView sets renamingURL via a binding.

**Recommendation:** Option 1 — pass `Binding<SidebarSelection?>` into `ScratchPadSection`. Clear on commit AND on cancel (`onExitCommand`). Same in `NestedBookmarkSubSection.BookmarkRow` — when `BookmarkEditSheet` dismisses, clear selection.

**Warning signs:**
- Second Return press re-enters rename immediately (indicates selection wasn't cleared).
- After deletion, next row below highlights incorrectly.
- `List` console logs "Unknown selection" or similar.

### Pitfall 5: `.onDrop` modifier position on replaced header

**What goes wrong:** `NestedBookmarkSubSection.swift:60-63` attaches `.onDrop(of: [.text], delegate: BookmarkFolderDropDelegate(targetFolderID: nil, modelContext: modelContext))` to the bespoke `Button` that serves as the header. When D-03 replaces that `Button` with `SidebarSectionHeader(…)`, the `.onDrop` must re-attach to the new header call site. If attached to the wrong level (e.g., to the outer `Group`), the drop target expands/shrinks incorrectly.

**Why it happens:** `.onDrop` attaches to the view's hit-test rect. Attaching to a Group applies to the entire Group's bounds (header + content); attaching to the header alone limits it to just the chevron+title+count row. Phase 11's shipped behavior was limited to the header's Button rect.

**How to avoid:** Attach `.onDrop` directly to the `SidebarSectionHeader(…)` call-site expression. SwiftUI applies the modifier to the returned `some View`, which is the header's rendered surface — same hit-test rect as the outgoing `Button`. No Group-level attachment.

```swift
SidebarSectionHeader(
    title: "Bookmarks",
    isExpanded: $isExpanded,
    count: visibleBookmarks.count
)
.onDrop(of: [.text], delegate: BookmarkFolderDropDelegate(
    targetFolderID: nil,
    modelContext: modelContext
))
```

**Warning signs:**
- Drops land on the content area (wrong behavior, was Phase 11 header-only).
- Drops don't land anywhere (modifier scope error).

### Pitfall 6: `.onKeyPress` at List vs row scope — precedence

**What goes wrong:** If `.onKeyPress(.return)` is attached both at the List scope and at row scope (e.g., some other view inside a row that sets its own `.onKeyPress`), event routing depends on focus order. On macOS, parent returns `.handled` blocks child delivery; child handlers returning `.ignored` bubble up.

**Why it happens:** Phase 12 scope limits `.onKeyPress(.return)` to the List level (`SidebarView` body), and Return is not caught elsewhere in the sidebar. But **the Scratch Pad rename `TextField`** is inside a row, and TextField intercepts Return by default (to commit). This is the desired behavior.

**How to avoid:**
- Attach `.onKeyPress(.return)` at the List level only, not on individual rows.
- Inside the rename TextField, rely on the existing `onCommit` flow (Return → commit rename). SwiftUI routes Return to the TextField first because it has keyboard focus when active. The List's `.onKeyPress(.return)` fires only when no focusable child catches it.

**Warning signs:**
- Pressing Return inside the rename field triggers BOTH commit AND rename-re-enter.
- Pressing Return in the rename field does nothing.

## @AppStorage Inventory

[VERIFIED: `grep -n '@AppStorage' **/*.swift` + `grep -n 'storageKey:' **/*.swift` on 2026-04-20]

Confirmed the CONTEXT.md claim of "11 keys" is exact. All 11 already follow the canonical naming convention.

### Sidebar keys (5) — `@AppStorage(...)` direct literals

| Key | File:line | Default | Binding name |
|-----|-----------|---------|--------------|
| `sidebar.locations.expanded` | `SidebarView.swift:18` | `true` | `isLocationsExpanded` |
| `sidebar.scratchPads.expanded` | `SidebarView.swift:19` | `true` | `isScratchPadsExpanded` |
| `sidebar.browsers.expanded` | `SidebarView.swift:537` (private `BrowserSessionsSection`) | `true` | `isExpanded` |
| `sidebar.otherSessions.expanded` | `SidebarView.swift:571` (private `OrphanedSessionsSection`) | `true` | `isExpanded` |
| `sidebar.browsers.bookmarks.expanded` | `NestedBookmarkSubSection.swift:21` | `true` | `isExpanded` |

### Overview keys (6) — `CollapsibleVStackSection(storageKey:)` parameter

| Key (interpolated) | File:line | Context |
|--------------------|-----------|---------|
| `overview.todos.expanded.\(projectID)` | `ProjectOverviewView.swift:208` | Todos card (kept; Phase 12 does NOT pass `count:`) |
| `overview.sessions.expanded.\(projectID)` | `ProjectOverviewView.swift:279` | Terminal Sessions card |
| `overview.browsers.expanded.\(projectID)` | `ProjectOverviewView.swift:382` | Browsers card (outer) |
| `overview.browsers.bookmarks.expanded.\(projectID)` | `ProjectOverviewView.swift:413` | Nested Bookmarks card |
| `overview.documents.expanded.\(projectID)` | `ProjectOverviewView.swift:479` | Open Files card |
| `overview.locations.expanded.\(projectID)` | `ProjectOverviewView.swift:525` | Locations card |

### Other `@AppStorage` call sites (NOT part of UIX-22 — out of scope)

| Key | File:line | Notes |
|-----|-----------|-------|
| `showLineNumbers` | `MarkdownTextView.swift:19`, `GeneralSettingsView.swift:7` | Editor setting, not section expansion. **Do NOT rewire.** |
| `showSystemMetrics` | `ContentView.swift:29`, `SystemMetricsView.swift:10`, `GeneralSettingsView.swift:9` | App chrome setting. **Do NOT rewire.** |
| `editorFontSize` | `GeneralSettingsView.swift:6` | Editor setting. **Do NOT rewire.** |
| `autoSaveEnabled` | `GeneralSettingsView.swift:8` | Editor setting. **Do NOT rewire.** |
| `showHiddenFiles` | `FileTreeView.swift:9`, `GeneralSettingsView.swift:10` | File-tree setting. **Do NOT rewire.** |
| `BrowserUserAgent.modeDefaultsKey` | `GeneralSettingsView.swift:11` | Already uses a constant; exemplar of the pattern Phase 12 is introducing elsewhere. |
| `BrowserUserAgent.customValueDefaultsKey` | `GeneralSettingsView.swift:12` | Same as above. |

## Existing `SidebarSectionHeader` Call Sites

[VERIFIED: `grep -n 'SidebarSectionHeader' **/*.swift` on 2026-04-20]

| File:line | Title | Passes `count:` after Phase 12 |
|-----------|-------|--------------------------------|
| `SidebarView.swift:63-66` | `"Scratch Pads"` | `visiblePads.count` (need to lift to SidebarView scope or expose from ScratchPadSection) |
| `SidebarView.swift:86-89` | `"Locations"` | `projectLocations.count` (already computed at `:31-34`) |
| `SidebarView.swift:561` | `"Browsers"` (inside `BrowserSessionsSection`) | `browsers.count` (computed at `:547`) |
| `SidebarView.swift:583` | `"Other Sessions"` (inside `OrphanedSessionsSection`) | `orphaned.count` (computed at `:574`) |
| `NestedBookmarkSubSection.swift` — NEW at `:39-59` replacement | `"Bookmarks"` | `visibleBookmarks.count` (computed at `:23-26`) |

Current `visiblePads` is computed inside `ScratchPadSection` (private). Options for SidebarView to access count:
1. Call `appState.scratchPadManager.scratchPads(forProject: projectID).count` inline.
2. Add a `visiblePads` computed property on `SidebarView` mirroring the existing `projectLocations` pattern.

**Recommendation: Option 2** for symmetry with `projectLocations`. Keeps the View thin and testable.

## Existing Empty-State / Inline-Row Grep (UIX-23 baseline)

[VERIFIED: grep on 2026-04-20]

- `Text\("No \w+` → **zero matches in `.swift`.**
- `Text\("(Nothing|Empty|No \w)` → **zero matches.**

The single instance of "Nothing here yet" lives in `ProjectOverviewView.emptyHero` (line 366) — the approved overview-level empty hero from Phase 11. No other violations exist. D-16 / D-17 are confirmed as documentation-only changes.

## Existing `.alert()` Idioms in Codebase

[VERIFIED: grep on 2026-04-20]

Four existing `.alert()` call sites provide precedents:

1. **`ContentView.swift:139-160`** — "Close Terminal?" — closest match to Phase 12 pattern. Destructive confirm with dynamic title/message, `role: .cancel` + `role: .destructive`, `isPresented:` + `message:` closure. Conditional message body based on pending state.
2. **`ContentView.swift:161-185`** — "Update Available" / "You're Up to Date" — two flat alerts with default + cancel buttons.
3. **`BookmarkListView.swift:168-183`** — "Rename Location" — alert-based rename (TextField inside alert). Not a pattern Phase 12 follows; Scratch Pad rename stays inline.
4. **`IntentListView.swift:43-…`** — same shape as the Rename Location alert.

**Conclusion:** Phase 12's alert matches pattern (1) exactly. Two inline `.alert(...)` modifiers at the SidebarView level (or one with branching title) is the natural shape.

## Runtime State Inventory

Phase 12 is a refactor but ships **no rename / migration of data**. The audit categories are included for completeness per GSD research discipline:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — SwiftData `@Model` schemas unchanged. No Mem0/ChromaDB/SQLite analog. | None. |
| Live service config | None — app is native macOS; no external services. | None. |
| OS-registered state | `@AppStorage` keys in UserDefaults under bundle ID `Wrangle`. **All 11 keys already exist and already follow the canonical naming convention.** Per D-13, no migration: key strings don't change during the constants extraction (refactor is purely syntactic). | None — key strings are byte-identical before and after. |
| Secrets / env vars | None — no secrets used. | None. |
| Build artifacts / installed packages | None — `fileSystemSynchronizedRootGroup` means new files auto-compile without pbxproj edits. No egg-info / compiled-binary analogs. | None. |

**The canonical question — "After every file in the repo is updated, what runtime systems still have the old string cached, stored, or registered?"** — ANSWER: dev-local UserDefaults plist may contain stale keys from pre-Phase-11 builds (e.g., the orphan `overview.bookmarks.expanded.<projectID>` from the defunct standalone bookmarks card). These are **inert** — no code reads them — and occupy a handful of bytes. Per D-13, no migration. On launch, fresh users of v1.2 will see the correct 11 keys written as sections expand/collapse.

## Environment Availability

Phase 12 depends only on frameworks and tools already present for the rest of the Wrangle codebase.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode (xcodebuild) | Build verification | ✓ | 26.2 (per `LastSwiftUpdateCheck = 2620`, `LastUpgradeCheck = 2620` in `Wrangle.xcodeproj/project.pbxproj:86-87`) | — |
| Swift | Build | ✓ | 5.9+ (per CLAUDE.md) | — |
| SwiftTerm | Terminal (not touched this phase) | ✓ | 1.11.2 | — |
| swift-argument-parser | CLI (not touched this phase) | ✓ | 1.7.0 | — |
| macOS Sequoia 15+ | Target | ✓ | Developer machine 25.2.0 (Darwin) — macOS 15+ | — |
| `NSWorkspace.shared.recycle` | D-10 Trash path (if used) | ✓ | macOS 10+ | Use existing `FileManager.trashItem` (recommended — see Pitfall 2). |
| `.onKeyPress` | Return/Delete handlers | ✓ (macOS 14+) | N/A | `.onDeleteCommand` is available macOS 10.15+. Use it as primary. |
| `.onDeleteCommand` | Keyboard Delete on List | ✓ (macOS 10.15+) | N/A | — |
| `@FocusState` | Rename TextField focus | ✓ (macOS 12+) | N/A | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None — all required APIs are available at or below the project's minimum macOS target.

**Build verification command:** `xcodebuild -project /Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/Wrangle.xcodeproj -scheme Wrangle -configuration Debug build 2>&1 | tail -20` (project has only the `Wrangle` scheme — see Validation Architecture).

## Validation Architecture

[Nyquist validation is implicitly enabled — no `.planning/config.json` in the project root, so the key is absent (treat as enabled).]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect` macros) + XCTest hybrid — verified in `WrangleTests/TokenCounterTests.swift:1-3` (uses `import Testing` + `@Test`) |
| Config file | None (no `.xctestplan`, no pytest.ini analog) |
| Quick run command | **BLOCKED** — no test target wired (see Wave 0 Gaps) |
| Full suite command | **BLOCKED** — no test target wired |
| Build verification | `xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -configuration Debug build` |

**Critical finding:** Four test files exist in `WrangleTests/` (`TokenCounterTests.swift`, `FileTypeTests.swift`, `MarkdownParserTests.swift`, `EditorDocumentTests.swift`) but **no test target is defined** in `Wrangle.xcodeproj/project.pbxproj` (verified: `grep -c Tests project.pbxproj` = 0; `xcodebuild -list` shows only the `Wrangle` app target). The test files are orphaned — they cannot currently be run via `xcodebuild test`. This is a pre-existing project gap, not introduced by Phase 12.

### Phase Requirements → Test Map

Phase 12 is predominantly UI-plumbing. Automated unit testing is viable for a narrow slice (storage-key constants, alert-title builder, selection-clear logic), but behavioral tests (header count appearing on collapse, Return-triggers-rename, Delete-triggers-alert) require either UI tests (XCUITest) or manual verification. The table below maps each requirement to the highest-fidelity test type that's realistic within Phase 12's scope.

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UIX-20 | `SidebarSectionHeader` count renders only when `count != nil && !isExpanded` | unit (view snapshot or view-body-return) | N/A — no test target | ❌ Wave 0 / manual-only |
| UIX-20 | `CollapsibleVStackSection` count renders with identical styling to sidebar | unit / snapshot | N/A | ❌ Wave 0 / manual-only |
| UIX-20 | All 5 sidebar call sites pass the correct count | grep-based assertion on source | `grep -n 'SidebarSectionHeader' wrangle/**/*.swift` (manual review) | manual |
| UIX-21 | Return on selected Scratch Pad enters rename | manual (UI — `XCUITest` would work but no target) | — | ❌ manual-only |
| UIX-21 | Return on selected Bookmark opens `BookmarkEditSheet` | manual | — | ❌ manual-only |
| UIX-21 | Delete on selected row shows `.alert()` | manual | — | ❌ manual-only |
| UIX-21 | Context-menu Delete stays immediate (no alert) | manual | — | ❌ manual-only |
| UIX-21 | Scratch Pad file lands in Finder Trash on delete confirm | manual (requires Finder check) | — | ❌ manual-only |
| UIX-21 | Alert title interpolates the row's display name | unit (title builder function in isolation) | N/A — no test target | ❌ Wave 0 |
| UIX-22 | All 11 `@AppStorage` literals rewired to constants | grep-based assertion | `grep -nE '@AppStorage\("(sidebar\|overview)\.' wrangle/**/*.swift` — expect **zero** matches after Phase 12; `grep -nE 'storageKey: "(overview\.)' wrangle/**/*.swift` — expect **zero** matches | manual sweep |
| UIX-22 | Key strings produced by constants match the old literals byte-for-byte | unit | N/A — no test target | ❌ Wave 0 |
| UIX-23 | No new `Text("No …")` / `"Nothing "` / `"Empty "` in sidebar/overview Section bodies | grep-based assertion | `grep -nE 'Text\("(No \w+\|Nothing \|Empty )' wrangle/**/*.swift` — expect **zero** matches (or only the `emptyHero` already verified) | manual sweep |

**Sampling Rate:**
- **Per task commit:** `xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -configuration Debug build 2>&1 | tail -5` — build must be green. Zero warnings introduced (strictly, Phase 12 should not widen the warning-count baseline).
- **Per wave merge:** build + grep sweep (UIX-22, UIX-23 assertions).
- **Phase gate:** full manual UAT per the requirement table above before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] **Test target wiring** — Four test files in `WrangleTests/` are orphaned. **Do NOT scope this to Phase 12** — it's a pre-existing gap that predates this milestone. Flag in the plan SUMMARY as out-of-scope, with a note recommending a future phase adds the test target. Phase 12's verification is manual UAT + grep + build, same pattern every prior phase followed (STATE.md shows every phase's verification was "build green" + manual).
- [ ] **Selection-binding spike (Wave 0 task, 15-min)** — Before wiring Return/Delete handlers, the planner adds a small spike task: introduce `@State private var selection: SidebarSelection?` in `SidebarView`, tag rows in both ScratchPadSection and NestedBookmarkSubSection, and manually verify: (a) clicking a Scratch Pad highlights it; (b) clicking a Bookmark highlights it and clears the Scratch Pad highlight; (c) arrow keys navigate within + across Section boundaries; (d) Esc clears selection. If visual glitches appear, fall back per D-06.
- [ ] **Alert title builder — pull out into a testable free function** — So that when/if a test target is added later, the logic can be unit-tested without pulling a View. Small benefit; optional.
- [ ] **Grep-based CI check for UIX-22 / UIX-23 invariants** — Optional; D-14 provides compile-time enforcement for UIX-22 (misspelled key → build error if refactored into a constant), so the grep check is a belt-and-suspenders layer. Not required.

**None required to ship:** Phase 12 follows the established "build green + manual UAT" verification cadence of every prior phase in this milestone.

## Code Examples

### Extending `SidebarSectionHeader` with optional count

See Pattern A above. Exact code.

### Extending `CollapsibleVStackSection` with optional count

See Pattern B above. Exact code. Note: because `CollapsibleVStackSection` has two initializers (one with `accessory:`, one via the `Accessory == EmptyView` extension), the `count: Int? = nil` parameter must be added to **both** to preserve the API surface.

### Enum-based selection + Return/Delete dispatch

See Pattern C above. Full example showing List-scope modifier attachment.

### Alert with dynamic title (two-alert alternative)

See Pitfall 3 patterns (a) and (b). Pattern (a) matches the UI-SPEC copy spec.

### AppStorage constants files

See Pattern E above. Complete enum definitions.

### Scratch Pad delete — keep existing `trashItem` (recommended)

```swift
// Source: existing ScratchPadManager.swift:78-85 — the fallback is a latent bug.
// Recommended: promote the throw path to a non-fatal error, don't silently removeItem.

func deleteScratchPad(at url: URL) {
    do {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    } catch {
        // Previously: try? FileManager.default.removeItem(at: url)  ← hard-delete on Trash failure
        // Replace with: log / surface via UI. Delete failure should NOT silently hard-delete.
        NSLog("deleteScratchPad: trashItem failed for \(url.path): \(error)")
    }
    loadScratchPads()
}
```

### Scratch Pad delete — strict D-10 `NSWorkspace.shared.recycle` variant

```swift
// Source: Apple docs — NSWorkspace.recycle(_:completionHandler:)
// Only needed if plan requires literal D-10 compliance.

func deleteScratchPad(at url: URL) async {
    await withCheckedContinuation { continuation in
        NSWorkspace.shared.recycle([url]) { _ in
            continuation.resume()
        }
    }
    loadScratchPads()
}
```

Callers would need `await` — a wider API change. **Not recommended** per Pitfall 2.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hover-based `.focusable(enabled)` + `.onKeyPress(.delete)` on rows | `List(selection:)` + `.onDeleteCommand` at List scope | SwiftUI 5.0 (macOS 14+) — `.onKeyPress` introduced; `.onDeleteCommand` predates SwiftUI | Delete key works on keyboard-selected rows without hover. macOS-native. |
| `NSWorkspace.shared.recycle(_:completionHandler:)` (callback-based) | `FileManager.default.trashItem(at:resultingItemURL:)` (throws) | Foundation method predates the Swift 5 throwing variant; `recycle` is legacy | Apple recommends `trashItem` for new Swift code. [CITED: Apple Developer docs comparison] |
| `ObservableObject` + `@Published` + `@ObservedObject` | `@Observable` + `@State` / `@Bindable` | Swift 5.9 / iOS 17 / macOS 14 | Already adopted throughout Wrangle. No change in Phase 12. |
| `cornerRadius()` | `.clipShape(.rect(cornerRadius:))` | SwiftUI 5.0 | Already adopted. |
| `foregroundColor()` | `.foregroundStyle()` | iOS 17 / macOS 14 | Already adopted. |

**Deprecated/outdated:**
- **`DeleteKeyHandler` + `.focusable(onHover)` pattern** (`NestedBookmarkSubSection.swift:336-349` and usage at `:303`): Replaced in Phase 12 by selection-driven handlers. The hover-based pattern was a workaround for the pre-`List(selection:)` era and became moot once List selection was wired.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | macOS 15+ (Sequoia) is the project's target floor as stated in CLAUDE.md, despite the `xcodebuild -list` output not showing it explicitly | Project Constraints | Low — project targets macOS 14.0+ per coding-patterns.md (line "Target macOS 14.0+") and CLAUDE.md tech-stack section. All Phase 12 APIs work at 14+. |
| A2 | `List(selection:)` across heterogeneous Sections on macOS 15 has visual glitches | Pitfall 1 | Medium — based on Apple Developer Forum reports for macOS 14 and general community reports on macOS 15; no specific first-party statement confirms macOS 15 behavior. Mitigation: Wave 0 spike validates empirically; D-06 documents fallback. |
| A3 | `FileManager.trashItem` is the Swift-idiomatic Trash API (versus `NSWorkspace.shared.recycle`) | Pitfall 2 / Alternatives | Low — MEDIUM sourcing: `trashItem` docs are current, `recycle` docs are flagged as older callback-based. Multiple community blog posts concur. Mitigation: D-10 explicitly says "or equivalent"; both work. |
| A4 | The `.onDrop` modifier attached to `SidebarSectionHeader(…)` will have the same hit-test rect as attached to the existing bespoke `Button` | Pitfall 5 | Medium — SwiftUI's modifier application to a composed view's outer frame SHOULD match. Verify in the spike: drop a bookmark on the header; if it lands on content-area rows, the modifier scope is wrong. |
| A5 | The alert `title:` parameter re-evaluates when the computed property changes via state diffing | Pitfall 3 (approach a) | Medium — SwiftUI's documented behavior, but interactions with `presenting:` have sharp edges. Mitigation: if approach (a) glitches, fall back to approach (b) — two alerts, static titles, `message:` interpolation. |
| A6 | UIX-22 constants refactor is purely syntactic — key strings byte-identical pre/post | Runtime State Inventory | Low — CONTEXT.md D-13/D-14 explicitly specify this. Planner verifies by unit test OR by grep comparison of old literal vs new constant value. |
| A7 | No test target in Wrangle.xcodeproj is a pre-existing gap, not a Phase 12 concern | Validation Architecture | Low — verified via `grep -c Tests Wrangle.xcodeproj/project.pbxproj` = 0 and the STATE.md log of prior phases all using "build green + manual" verification. Plan should flag but not scope. |

## Open Questions

1. **Does `List(selection:)` reliably highlight rows across the Scratch Pads ↔ nested Bookmarks boundary on macOS 15?**
   - What we know: selection binding is a supported SwiftUI API; enum-based selection types work; the Scratch Pads and Bookmarks sections are in distinct `Section` scopes inside the same List.
   - What's unclear: whether macOS 15's List has residual glitches when selection transitions between two sections that have different ID types, particularly when one section's rows are `ScratchPadItem`-backed (URL ID) and the other is `BrowserBookmark`-backed (String ID).
   - Recommendation: Wave 0 spike (15 min). If glitches appear, fall back per D-06.

2. **Does the `.alert(_:isPresented:presenting:actions:)` modifier's `title:` parameter re-render when a computed property driving it changes?**
   - What we know: SwiftUI re-evaluates view bodies when `@State` changes; a computed property inside a body reads the latest state.
   - What's unclear: whether the alert modifier itself holds a stale snapshot of the title string between the `isPresented` flip and the render. (Apple's docs don't explicitly guarantee this.)
   - Recommendation: if approach (a) from Pitfall 3 shows stale titles, switch to approach (b) — two alerts, each with a static title + dynamic message.

3. **Should the Scratch Pad delete keep `FileManager.trashItem` or migrate to `NSWorkspace.shared.recycle`?**
   - What we know: both move to Trash; both are Apple-supported; existing code uses `trashItem`.
   - What's unclear: whether the UI-SPEC / CONTEXT D-10 "(or equivalent)" language is permissive or literal.
   - Recommendation: keep `trashItem` (minimal risk, no behavior change). Fix the silent-hard-delete fallback at `ScratchPadManager.swift:82` as a non-blocking improvement inside the same task. Document the equivalence in SUMMARY.

4. **Where should `SidebarStorageKeys.swift` + `OverviewStorageKeys.swift` live?**
   - What we know: existing convention puts shared components in `wrangle/Components/`. CONTEXT.md Claude's Discretion explicitly names `Storage/` or `Constants/` as acceptable alternatives.
   - What's unclear: whether the project has a preference not surfaced in existing docs.
   - Recommendation: `wrangle/Components/` — matches the existing discovery pattern (planner can audit `import` statements for dependencies — both files are import-free Swift).

5. **Should the selection clear-after-rename hook live in SidebarView or in the row's commit handler?**
   - What we know: D-12 says "Selection must clear after rename commits." Current rename logic is inside `ScratchPadSection.commitRename` (private).
   - What's unclear: whether to pass `Binding<SidebarSelection?>` down, or observe a state change up.
   - Recommendation: pass `Binding<SidebarSelection?>` into `ScratchPadSection` + `NestedBookmarkSubSection.BookmarkRow` — clearest contract, no observability-chain pitfalls.

## Sources

### Primary (HIGH confidence)
- **Codebase audit** (2026-04-20 grep runs) — all `@AppStorage` inventory, existing component shapes, current `deleteScratchPad` implementation, empty-state baseline, alert idioms, existing `SidebarSectionHeader` call sites, test target gap (`project.pbxproj` grep).
- **Existing project artifacts** — `CLAUDE.md`, `docs/coding-patterns.md`, `docs/architecture.md`, STATE.md, CONTEXT.md, UI-SPEC.md, REQUIREMENTS.md.
- **Apple Developer docs** — `FileManager.trashItem(at:resultingItemURL:)` [developer.apple.com/documentation/foundation/filemanager/1414306-trashitem] confirmed throwing synchronous signature.
- **Apple Developer docs** — `NSWorkspace.recycle(_:completionHandler:)` [developer.apple.com/documentation/appkit/nsworkspace/recycle(_:completionhandler:)] confirmed async callback signature.
- **Apple Developer docs** — `alert(_:isPresented:presenting:actions:message:)` [developer.apple.com/documentation/swiftui/view/alert(_:ispresented:presenting:actions:message:)-29bp4] — signature confirmed via search results + hacking-with-swift summaries.
- **Project skills** — `.claude/skills/swiftui-expert-skill/references/list-patterns.md` (stable identity, inline-filter anti-pattern); `.claude/skills/ios-design/references/craft-state-local.md` (`@State private` invariant); `.claude/skills/swiftui-expert-skill/SKILL.md` (modern API list).

### Secondary (MEDIUM confidence)
- **SwiftJective-C** — `swiftjectivec.com/Handling-Keyboard-Presses-in-SwiftUI-for-macOS/` — `.onKeyPress` focus requirements on macOS.
- **SwiftDevJournal** — `swiftdevjournal.com/removing-items-from-swiftui-lists-in-mac-apps/` — `.onDeleteCommand` + `List(selection:)` canonical pattern.
- **nilcoalescing.com** — `nilcoalescing.com/blog/ListSelectionForNavigation/` — enum-based selection for heterogeneous sections.
- **HackingWithSwift onKeyPress overview** — fetched summary confirmed focusable requirement and `.handled` vs `.ignored` dispatch.
- **serialcoder.dev** — `serialcoder.dev/text-tutorials/swiftui/enabling-selection-double-click-and-context-menus-in-swiftui-list-on-macos/` — confirms `List(selection:)` with double-click + context-menu patterns on macOS.

### Tertiary (LOW confidence)
- **Apple Developer Forum thread 667366** — "How to enable the Delete key shortcut" — documented gap in SwiftUI delete-key handling, 0 replies. Informs Pitfall 1 but not authoritative.
- **Apple Developer Forum thread 739118** — "Section(isExpanded:) bug on macOS?" — related macOS List / Section bug. Informs Pitfall 1 risk assessment.
- **christiantietze.de PSA on FileManager.trashItem + NSFileCoordinator** — supports the recommendation in Pitfall 2 that `trashItem` is the modern choice.
- **sindresorhus/macos-trash issue #4** — "Put back only works for the first file" — macOS-level quirk with trashed file metadata; informs UAT expectations but not actionable in Phase 12.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every API is Apple first-party and already in use elsewhere in the codebase.
- Architecture patterns (count extension, AppStorage constants, alert patterns, delete-to-trash): HIGH — codebase audit verified every line cited.
- Selection pattern (Pattern C) / heterogeneous-section risk: MEDIUM — pattern is canonical, but the macOS-15-specific glitch profile isn't codified by Apple; Wave 0 spike derisks.
- Pitfalls: HIGH — Pitfalls 2, 4, 5, 6 are directly from codebase grep + forum-confirmed behaviors. Pitfall 1 is MEDIUM (see above). Pitfall 3 is MEDIUM (SwiftUI modifier re-evaluation is documented but with sharp edges).

**Research date:** 2026-04-20
**Valid until:** 2026-07-20 (stable — SwiftUI APIs and macOS 15 behavior are stable quarterly).
