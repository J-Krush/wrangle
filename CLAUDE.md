# CLAUDE.md — Wrangle

> **Detailed docs:** [Architecture & Structure](docs/architecture.md) | [Coding Patterns](docs/coding-patterns.md) | [Audit Report](docs/audit-report.md)

## Project Overview

Wrangle is a native macOS (Apple Silicon) markdown editor purpose-built for developers working with AI agents, skills, system prompts, and configuration files. Built with Swift and SwiftUI.

Think "Typora meets AI development" — rich rendered editing by default, with deep awareness of the unique file patterns in AI/agent workflows (XML-in-markdown, token counting, `.claude.md` files, SKILL.md files, MCP configs).

**Xcode project name:** `Wrangle`  |  **Bundle identifier:** Wrangle

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (macOS 15+ / Sequoia minimum)
- **Editor Core:** Custom `NSTextView`-based editor via `NSViewRepresentable` + `NSAttributedString`
- **Terminal:** Embedded via [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) (`LocalProcessTerminalView`)
- **File System:** Native Foundation `FileManager` + `NSOpenPanel` / `NSSavePanel`
- **Persistence:** SwiftData for bookmarks, preferences, recent files
- **Architecture:** MVVM with `@Observable` + `@MainActor`

## Coding Conventions

- Use Swift modern concurrency (`async/await`, `@Observable`, `@MainActor`)
- Prefer value types (structs); classes only when needed (NSTextView delegates, `@Observable` models)
- Every `@Observable` class MUST have `@MainActor`
- `@State` must be `private`; use `@Environment(AppState.self)` for DI
- Use `@Bindable` for two-way bindings from `@Observable` objects
- Name files after their primary type
- Keep views under ~80 lines — extract subviews beyond that
- Error handling: `Result` or `throws` — never force unwrap except static regex `try!`
- Comments: explain *why*, not *what*
- Use `Button` over `onTapGesture`; `.clipShape()` over `.cornerRadius()`
- Cache `NSRegularExpression` as `static let` — never create in hot paths
- Use Task-based debouncing, not `DispatchWorkItem`
- Use `MainActor.run` / `Task { @MainActor in }`, not `DispatchQueue.main.async`
- Never sync file I/O on main thread or in computed properties

See [docs/coding-patterns.md](docs/coding-patterns.md) for full rules with code examples.

## AI-Specific File Awareness

The editor recognizes and gives special treatment to:
- `CLAUDE.md` / `.claude.md` — Claude Code project files
- `SKILL.md` — Skill definition files
- `AGENTS.md` — Agent configuration files
- `system-prompt.md` / `system_prompt.md` — System prompts
- Files containing `<tools>`, `<instructions>`, `<system>` XML tags

Special treatment: distinct file tree icons (`FileType` enum in `EditorDocument.swift`), XML tag highlighting/collapsing, token count always visible in status bar.

## Build Approach

Vertical feature slices. Each slice delivers a working increment touching both UI and underlying logic.

## Testing Strategy

- **Unit tests:** MarkdownParser, TokenCounter, SecurityScopedBookmark
- **UI tests:** File open/save flow, bookmark management
- **Manual testing:** Editor rendering, terminal integration

## Sidebar / Overview Section Conventions

**Expansion state (`@AppStorage`):**
- Sidebar sections use `sidebar.<section>.expanded` (global, not per-project).
- Overview cards use `overview.<section>.expanded.<projectID>` (per-project).
- Nested sub-sections append the sub-segment (e.g., `sidebar.browsers.bookmarks.expanded`).
- ALL sidebar/overview expansion keys must route through
  `wrangle/Components/SidebarStorageKeys.swift` or `OverviewStorageKeys.swift` —
  never declare raw string literals. Adding a new section? Add the constant first.

**Hide-when-empty invariant:**
- Sidebar and Project Overview sections must hide entirely when empty.
- Never render a section header with an inline empty-state row ("No X yet",
  "Nothing here", etc.) inside its body.
- If a global empty-state message is needed, use the overview's centered
  `emptyHero` pattern (Phase 11) — never per-section placeholder rows.
- Section visibility is gated at the body/scope level with `if !xs.isEmpty { … }`
  before the `Section { } header: { }` or `CollapsibleVStackSection(…)` call.

**Header parity:**
- Sidebar sections use `SidebarSectionHeader(title:isExpanded:count:)`.
- Overview cards use `CollapsibleVStackSection(_:storageKey:count:)`.
- Both render an optional count when collapsed (`.system(size: 10)` +
  `.tertiary`). Do not build bespoke section headers.

**Header accessory scope:**
- Phase 10 stripped *creation* affordances (`+` / `…` / `Import…`) from all
  section headers — those live in `UnifiedAddMenu` only.
- *Navigation* accessories are still allowed via the trailing slot on
  `SidebarSectionHeader` and the `accessory:` closure on
  `CollapsibleVStackSection`. Example: Browsers header carries a
  `BookmarksPopoverButton` (book icon → popover listing bookmarks with
  "Import…"). Rule: if the accessory *creates* something, route through
  `UnifiedAddMenu`; if it *navigates* to related content, inline it.

## Important Notes for Claude Code

- SwiftUI App lifecycle (not AppKit AppDelegate)
- Target macOS 14.0+ (Sonoma)
- Do NOT use document-based app template — we manage files ourselves
- Multiple windows supported (each window = one workspace)
- `NavigationSplitView` for sidebar/editor layout
- Terminal via SwiftTerm's `LocalProcessTerminalView`, not custom PTY
- Consult `docs/audit-report.md` for known issues before modifying affected files
- Consult `docs/architecture.md` for project structure, theming, and editor design decisions
