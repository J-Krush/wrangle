# Phase 12: Section Parity & Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 12-section-parity-polish
**Areas discussed:** Header canonicalization (UIX-20), Scratch Pad keyboard parity (UIX-21), AppStorage audit & orphan cleanup (UIX-22), UIX-23 regression guard

---

## Gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Header canonicalization (UIX-20) | SidebarSectionHeader count variant vs bespoke | ✓ |
| Scratch Pad keyboard parity (UIX-21) | Rename/delete trigger model | ✓ |
| AppStorage audit & orphan cleanup (UIX-22) | Migration + drift prevention | ✓ |
| UIX-23 regression guard | Enforce no header+empty-row | ✓ |

**User's choice:** All four areas selected.

---

## Header canonicalization (UIX-20)

### Q1: How should the nested Bookmarks sub-header fit into SidebarSectionHeader?

| Option | Description | Selected |
|--------|-------------|----------|
| Extend SidebarSectionHeader with optional count | Add `count: Int?` param, render when collapsed | ✓ |
| Keep NestedBookmarkSubSection bespoke | Leave the inline header alone | |
| Extract a header variant protocol | SidebarSectionHeaderWithCount wrapper | |

**User's choice:** Extend SidebarSectionHeader with optional count.

### Q2: Should any other section gain a count badge during this pass?

| Option | Description | Selected |
|--------|-------------|----------|
| No — Bookmarks only | Count stays specific to Bookmarks | |
| Yes — all collapsible sidebar sections | Apply to Browsers, Scratch Pads, Locations, Other Sessions, nested Bookmarks | ✓ |
| Deferred — Phase 13 design review | Bookmarks stays the outlier | |

**User's choice:** Yes — all collapsible sidebar sections.

### Q3: Chevron animation on toggle — keep or instant?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep chevron animation (current) | 0.15s snappy stays; show/hide is what's instant per memory | ✓ |
| Instant chevron swap | Remove withAnimation from chevron rotation | |

**User's choice:** Keep chevron animation (current).
**Notes:** `feedback_no_slide_transitions` covers section show/hide, not chevron rotation.

### Q4: Browsers count — tabs only or tabs+bookmarks?

| Option | Description | Selected |
|--------|-------------|----------|
| Tabs only | Browsers (3) = 3 tabs; Bookmarks (5) is its own count | ✓ |
| Tabs + bookmarks combined | Browsers (8) = 3 tabs + 5 bookmarks | |

**User's choice:** Tabs only.

### Q5: Should ProjectOverview CollapsibleVStackSection also gain a count variant?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — matching treatment | Add count to overview cards too for parity | ✓ |
| No — sidebar only | Overview keeps headline-only headers | |

**User's choice:** Yes — matching treatment.

### Q6: Count styling — current or system scale?

| Option | Description | Selected |
|--------|-------------|----------|
| Match current: .system(size: 10), .tertiary | Mirror Phase 11's bespoke bookmark header | ✓ |
| Use .caption2 + .secondary | Tighten to Apple system type scale | |

**User's choice:** Match current: .system(size: 10), .tertiary.

---

## Scratch Pad keyboard parity (UIX-21)

### Q1: Trigger model for rename/delete

| Option | Description | Selected |
|--------|-------------|----------|
| Selection-based (macOS-native, recommended) | List selection + Return/Delete; touches BookmarkRow too | ✓ |
| Hover-based (match current BookmarkRow) | Keep hover+focusable+onKeyPress; less native | |
| Hybrid: selection for Scratch Pads, hover stays on Bookmarks | Minimizes blast radius; violates parity intent | |

**User's choice:** Selection-based (macOS-native, recommended).
**Notes:** User explicitly asked "what is best for macOS" and accepted Finder/Mail/Xcode selection-based pattern after Claude explained conventions. Confirmed parity is the whole point of Phase 12.

### Q2: Return-to-rename surface on Bookmarks

| Option | Description | Selected |
|--------|-------------|----------|
| Return opens BookmarkEditSheet | Same as "Edit..." context menu | ✓ |
| Return inline-edits title only | Inline TextField, full sheet via menu | |

**User's choice:** Return opens BookmarkEditSheet.

### Q3: Delete confirmation on Scratch Pads (and extended to BookmarkRow for parity)

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate — match (current) Bookmarks | No confirmation | |
| Confirm on Delete key only (context menu = immediate) | Hybrid protects keyboard accident | ✓ |
| Always confirm | Safest | |

**User's choice:** Confirm on Delete key only. User explicitly extended this to BookmarkRow too ("bring that up to date with the bookmarkrow"). Context-menu Delete stays immediate on both row types.

### Q4: Selection scope

| Option | Description | Selected |
|--------|-------------|----------|
| Per-section @State | Minimal plumbing, no sidebar-wide refactor | |
| Unified sidebar selection on AppState | Single source of truth; bigger refactor | |
| SwiftUI List(selection:) binding | Most idiomatic SwiftUI | ✓ |

**User's choice:** SwiftUI List(selection:) binding.
**Notes:** Flagged planning risk — may fall back to per-section @State if List(selection:) is janky across Sections.

### Q5: Delete confirmation surface

| Option | Description | Selected |
|--------|-------------|----------|
| SwiftUI .alert() modifier | Classic macOS dialog; most common in codebase | ✓ |
| SwiftUI .confirmationDialog() | Lighter popup | |
| NSAlert via runModal | AppKit direct; overkill | |

**User's choice:** SwiftUI .alert() modifier.
**Notes:** User initially asked "what impacts does this have?" Claude explained each option's visual appearance and code footprint; user agreed to `.alert()` as the conventional low-surprise choice.

### Q6: Scratch Pad delete destination

| Option | Description | Selected |
|--------|-------------|----------|
| Move to Trash (NSWorkspace.recycle) | Finder convention; recoverable | ✓ |
| Keep current behavior (immediate unlink) | Scope minimized | |

**User's choice:** Move to Trash.

---

## AppStorage audit & orphan cleanup (UIX-22)

### Q1: Orphaned UserDefaults values

| Option | Description | Selected |
|--------|-------------|----------|
| Scrub on launch (one-time migration) | Delete known orphans | |
| Leave orphans (harmless drift) | Zero cost; no user impact | ✓ (implied) |
| Add debug menu 'Reset sidebar state' | Dev cleanup | |

**User's choice:** Skip migration entirely.
**Notes:** User asked "are these used for? No one in the wild has any browsers or bookmarks as I have yet to launch this version." Claude confirmed v1.2 hasn't shipped, only dev-local drift exists, no migration needed. This question was reframed away from Q1 entirely.

### Q2: Drift prevention strategy

| Option | Description | Selected |
|--------|-------------|----------|
| One-time review in the plan, no enforcement | Documentation only | |
| Constants file for all sidebar/overview keys | Structural enforcement via references | ✓ |
| Unit test that scans source for @AppStorage literals | CI enforcement | |

**User's choice:** Constants file for all sidebar/overview keys.

---

## UIX-23 regression guard

### Q1: How to enforce 'no header + inline empty-state row'

| Option | Description | Selected |
|--------|-------------|----------|
| Plan note + CLAUDE.md rule, no code enforcement | Documentation only | ✓ |
| Helper wrapper view (HideWhenEmptySection) | Structural enforcement | |
| Runtime debug assertion | DEBUG-only guard | |

**User's choice:** Plan note + CLAUDE.md rule, no code enforcement.

---

## Claude's Discretion

- Exact placement of `SidebarStorageKeys.swift` / `OverviewStorageKeys.swift` (Components/, Storage/, or Constants/ directory).
- `OverviewStorageKeys` API shape (static funcs vs namespace-style String formatter).
- `count:` param ergonomics (`Int?` with `if let` vs `Int = 0` with `if count > 0`).
- Whether to extract a shared `ConfirmDeleteAlert` view modifier or duplicate `.alert()` calls inline.
- Rename TextField initial selection (select-all vs cursor-at-end) — suggest select-all per Finder.
- Selection-binding type (enum over row IDs vs AnyHashable).
- Fallback to per-section @State if List(selection:) proves unstable.

## Deferred Ideas

- Overview count badges on Todos (redundant with stat badge).
- Shared `ConfirmDeleteAlert` modifier (borderline abstraction for two call sites).
- Unit test for `@AppStorage` naming (rejected in favor of constants file).
- Helper wrapper view for hide-when-empty sections.
- Runtime debug assertion against empty Section bodies.
- Dev-only "Reset sidebar/overview state" menu item.
- Promoting selection to all sidebar sections (only Scratch Pads + Bookmarks need it).
- UserDefaults orphan migration (no shipped users).
