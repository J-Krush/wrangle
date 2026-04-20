# Phase 11: Hide-When-Empty + Bookmarks Nested Under Browsers — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-19
**Phase:** 11-hide-when-empty-bookmarks-nested-under-browsers
**Areas discussed:** Sidebar nesting structure, Browsers w/ bookmarks only, Overview empty hero, Overview card nesting

---

## Sidebar nesting structure

### Q1. How should Bookmarks nest structurally inside the Browsers sidebar Section?

| Option | Description | Selected |
|--------|-------------|----------|
| Sub-section w/ own header (Recommended) | Inside Browsers Section, after tab rows, render a 'Bookmarks' chevron header, then bookmark rows/folders. Two independent chevrons. | ✓ |
| DisclosureGroup row | Single 'Bookmarks (n)' DisclosureGroup row below tab rows; expands inline. | |
| Interleaved, no sub-header | Tab rows then bookmark rows with divider; no separate Bookmarks label. | |

**User's choice:** Sub-section w/ own header.

### Q2. Keep the bookmark count badge?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep (Recommended) | 'Bookmarks (5)' always visible, tertiary foreground. | |
| Drop | Just 'Bookmarks'; cleaner. | |

**User's choice:** Drop it when expanded, show the number only when collapsed (user-supplied refinement: `▸ Bookmarks (5)` collapsed, `▾ Bookmarks` expanded).

### Q3. Expansion state persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Independent keys (Recommended) | `sidebar.browsers.expanded` + `sidebar.browsers.bookmarks.expanded`. | ✓ |
| Single key covers both | Collapsing Browsers also hides bookmarks; no independent Bookmarks collapse. | |

**User's choice:** Independent keys.

### Q4. Where do unfiled bookmarks render?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline at top of Bookmarks (Recommended) | Current behavior preserved. | ✓ |
| Under synthetic 'Unfiled' folder | Wrap in DisclosureGroup labeled 'Unfiled'. | |

**User's choice:** Inline at top.

---

## Browsers w/ bookmarks only

### Q1. 0 tabs + 3 bookmarks — what renders?

| Option | Description | Selected |
|--------|-------------|----------|
| Browsers header + Bookmarks sub (Recommended) | 'Browsers' chevron at top-level, then 'Bookmarks' sub-chevron directly. Header stays 'Browsers'. | ✓ |
| Only the Bookmarks sub-header | Skip Browsers parent; show 'Bookmarks (3)' at top-level position. | |
| Dynamic header label | Header rewrites: 'Browsers' or 'Bookmarks' based on content. | |

**User's choice:** Browsers header + Bookmarks sub.

### Q2. Ordering with tabs and bookmarks both present

| Option | Description | Selected |
|--------|-------------|----------|
| Tabs first, Bookmarks sub below (Recommended) | Tab rows first, then nested Bookmarks sub-section. | ✓ |
| Bookmarks sub first, then tabs | Favorites-at-top pattern. | |

**User's choice:** Tabs first, Bookmarks sub below.

### Q3. 0 bookmarks, 2 tabs — Bookmarks sub behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Bookmarks sub-section disappears (Recommended) | Sub-chevron hides entirely; only tab rows shown under Browsers. | ✓ |
| Keep empty Bookmarks sub w/ (0) | Always render sub-chevron for structural stability. | |

**User's choice:** Bookmarks sub-section disappears.

---

## Overview empty hero

### Q1. When does the hero appear?

| Option | Description | Selected |
|--------|-------------|----------|
| Project truly empty (Recommended) | No terminals, browsers, bookmarks, documents, locations. Todos doesn't count — Todos section always renders. | ✓ |
| Any section missing | Hero shows whenever fewer than all section types are populated. | |
| Only when nothing at all, incl. Todos | Stricter: every source including Todos must be empty. | |

**User's choice:** Project truly empty.

### Q2. Visual treatment for the hero

| Option | Description | Selected |
|--------|-------------|----------|
| Centered, muted, no CTA button (Recommended) | SF Symbol + headline + subheadline; no duplicate '+' button. | ✓ |
| Centered w/ embedded + button | Adds a third '+' menu surface. | |
| Inline hint line under Todos | Faint italic line only. | |

**User's choice:** Centered, muted, no CTA.

### Q3. Remove inline empty-state rows on Bookmarks / Locations cards?

| Option | Description | Selected |
|--------|-------------|----------|
| Remove completely (Recommended) | Per UIX-14 + UIX-23: section doesn't render when empty. | ✓ |
| Keep only if section header stays visible | Hint stays if section still renders empty. | |

**User's choice:** Remove completely.

### Q4. Hero copy

| Option | Description | Selected |
|--------|-------------|----------|
| "Press + to add your first…" (Recommended) | Full list of four types that get sections. | ✓ |
| Terser: "This project is empty" | Short, less specific. | |
| Warmer: "Let's build something" | Friendlier; inconsistent with Wrangle voice. | |

**User's choice:** "Press + to add your first Scratch Pad, Browser, Bookmark, or Location."

**Note:** User re-emphasized that the Todos list stays visible at the top even when the hero fires — reaffirming the Recommended trigger.

---

## Overview card nesting

### Q1. How should the Bookmarks card relate to the Browsers card?

| Option | Description | Selected |
|--------|-------------|----------|
| Truly nested inside Browsers (Recommended) | One CollapsibleVStackSection; tab grid then nested Bookmarks sub-chevron then bookmarks grid. | ✓ |
| Stacked, shared chrome | Two separate CollapsibleVStackSections, Bookmarks indented. | |
| Adjacent, equal weight | Two separate sections, no indent. | |

**User's choice:** Truly nested.

### Q2. 0 tabs + 5 bookmarks on overview — what renders?

| Option | Description | Selected |
|--------|-------------|----------|
| Browsers card w/ nested Bookmarks (Recommended) | Browsers card renders with no tab grid, Bookmarks sub directly. | ✓ |
| Only Bookmarks card at top level | Browsers parent disappears; Bookmarks card stands alone. | |

**User's choice:** Browsers card w/ nested Bookmarks.

### Q3. 3 tabs + 0 bookmarks on overview — what renders?

| Option | Description | Selected |
|--------|-------------|----------|
| Browsers card, no Bookmarks sub (Recommended) | Tab grid only; nested Bookmarks sub-header omitted. | ✓ |
| Always render Bookmarks sub header | Sub-header visible with (0). | |

**User's choice:** Browsers card, no Bookmarks sub.

### Q4. Scope check: delete standalone Browsers card or keep it?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep standalone Browsers card (Recommended) | Existing Browsers card at :432 stays; Bookmarks nests inside. | ✓ |
| Replace w/ unified Browsers+Bookmarks card | Merge; delete standalone Bookmarks section. | |

**User's choice:** Keep standalone Browsers card (confirmed in follow-up: delete the separate Bookmarks `bookmarksSection` card at :346 — its content moves inside the existing Browsers card).

---

## Claude's Discretion

- SF Symbol choice for the overview hero icon.
- Hero headline text (or whether to omit it and show only icon + subheadline).
- Hero spacing, icon size, font weights — subjective fit within Wrangle's dense-utility voice.
- Whether to extract the nested Bookmarks helper into its own file (`NestedBookmarkSection.swift`) or keep it inline inside `BrowserSessionsSection` / `browsersSection`.
- Exact `BookmarkSidebarSection.swift` fate: delete entirely vs rename + relocate.
- Indent amount (if any) for the overview nested Bookmarks sub-section.

## Deferred Ideas

- Canonical `SidebarSectionHeader` treatment → Phase 12 (UIX-20).
- Scratch Pad rename/delete parity → Phase 12 (UIX-21).
- Full `@AppStorage` expansion-state audit → Phase 12 (UIX-22).
- Assert-no-residual-empty-state-rows sweep → Phase 12 (UIX-23).
- Drag-to-reorder bookmarks within nested sub-section → out of scope for v1.2.
- Animated section show/hide transitions → not in scope; conflicts with user preference.
