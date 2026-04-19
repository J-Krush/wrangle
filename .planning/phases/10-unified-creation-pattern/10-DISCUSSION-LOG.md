# Phase 10: Unified Creation Pattern — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `10-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-19
**Phase:** 10-unified-creation-pattern
**Areas discussed:** Tab strip + scope, Menu items & ordering, Bookmark item behavior, Terminal variants

---

## Tab strip `+` scope

| Option | Description | Selected |
|--------|-------------|----------|
| Fold in — one unified `+` menu everywhere | Tab strip `+`, sidebar `+`, overview `+` all render from one shared `UnifiedAddMenu`. Same items, same order, everywhere. | ✓ |
| Keep tab strip `+` separate as a quick-tab shortcut | Tab strip `+` shrinks to tab-creating items only (File, Scratch Pad, Browser, Terminal, Claude, Gemini). Sidebar/overview `+` is the full creation menu. | |
| Keep tab strip `+` identical to today | Tab strip `+` stays untouched; only sidebar + overview unify. | |

**User's choice:** Fold in — one unified `+` menu everywhere (Recommended).
**Notes:** Three presenters, one menu model.

---

## Menu items & ordering

| Option | Description | Selected |
|--------|-------------|----------|
| Full menu, creation-type grouped | Scratch Pad / Browser / Private Browser / Bookmark… — Terminal / Claude Code / Gemini Code — File… / Location… — Import Bookmarks…. Three dividers, four groups. | ✓ |
| Tight menu, frequency-first ordering | Scratch Pad / Browser / Terminal / Claude / Location — File / Bookmark / Private / Gemini / Import. Dense, frequency-first. | |
| Minimal menu | Scratch Pad / Browser / Bookmark — Terminal (picker with Claude/Gemini toggles) — File / Location — Import. Private Browser + skip-perms exclusively via File menu. | |

**User's choice:** Full menu, creation-type grouped (Recommended).
**Notes:** Preview depicted three terminal rows; reconciled with Terminal-Variants answer below (four rows, not three). The final menu has four terminal items.

---

## "Bookmark…" item behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Enabled only when a browser tab is focused; star current page | Menu item disabled when no browser tab active. When active, stars current URL (same as toolbar star button). No new UI. | |
| Always enabled; opens small 'Add Bookmark' sheet (URL + title) | Always-available action; opens lightweight sheet with URL + Title fields. Pre-fills from active browser tab if present. New small sheet view. | ✓ |
| Always enabled; opens full `BookmarkEditSheet` in create mode | Reuses full edit dialog including folder picker and icon. Most complete; heaviest UX. | |

**User's choice:** Always enabled; opens a small 'Add Bookmark' sheet (URL + title fields).
**Notes:** New lightweight sheet, not `BookmarkEditSheet`. Pre-fills from active browser tab if one is focused.

---

## Terminal variants in the unified `+`

| Option | Description | Selected |
|--------|-------------|----------|
| One 'Terminal…' item — picker handles variant | Single menu item opens `TerminalDirectoryPicker` with a segmented variant control. | |
| Four separate items: Terminal / Claude Code / Gemini Code / Claude (Skip Perms) | Preserves today's tab-strip layout exactly. All 4 variants at top level. | ✓ |
| Two items: 'Terminal…' + 'AI Session…' | Split dangerous/AI terminals from plain terminals. Invents new grouping term. | |

**User's choice:** Four separate items.
**Notes:** Overrides the preview shown on the previous question (which depicted three terminal rows). Final menu has Terminal, Claude Code, Gemini Code, and Claude (Skip Permissions) as four distinct items.

---

## Claude's Discretion

- Exact `@State`/binding plumbing for the unified menu (per-presenter state vs shared).
- Menu implementation detail: `Menu { Button … }` vs custom popover.
- Whether to ship a single `UnifiedAddMenu` with an enum `Presenter` case or duplicate content in a helper function.
- "Add Bookmark" sheet optional "More options…" link to `BookmarkEditSheet`.
- Visual treatment of the `+` IconButton — match sidebar `+` but exact pixels are discretionary.
- Whether the tab strip `+` gets any visual nudge to disambiguate from simultaneous sidebar/overview `+` buttons.

## Deferred Ideas

- Hide-when-empty behavior — Phase 11.
- Bookmarks nested inside Browsers — Phase 11.
- Section-header visual normalization + Scratch Pad row parity — Phase 12.
- Multi-type "Saved" bucket — out of v1.2 scope entirely.
