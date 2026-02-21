# PromptPad — Build Plan

## Philosophy

We build in **vertical feature slices** — each slice delivers a working, testable increment that touches UI + logic together. No "build all the models first, then all the views" — every slice should result in something you can launch, see, and use.

Slices are ordered by dependency and value. Earlier slices unlock later ones.

---

## Slice 1: Bare Bones Editor Window

**Goal:** Launch the app → see an editor → open a `.md` file → edit it → save it.

**What to build:**
- `PromptPadApp.swift` — App entry point with a single `WindowGroup`
- `AppState.swift` — Minimal global state (current file path, file content)
- `EditorDocument.swift` — Model holding file URL, raw text content, dirty flag
- `MarkdownTextView.swift` — `NSViewRepresentable` wrapping `NSTextView` with basic text editing
- `MarkdownParser.swift` — **V1: Headings only.** Parse `#` through `######` and render as styled `NSAttributedString` with appropriate font sizes
- File menu: Open (`NSOpenPanel`), Save (`Cmd+S` writes back to original path), Save As
- Basic app chrome: title bar shows filename, window resizable

**What it looks like when done:**
You can open a markdown file, see headings rendered large/bold, edit text, and save. That's it. No sidebar, no toolbar, no fancy stuff.

**Key decisions:**
- Get the `NSTextView` ↔ SwiftUI bridge right early — this is the hardest integration point
- The parser should be designed for incremental extension (easy to add bold, code blocks, etc. in later slices)
- Store raw markdown in memory, render to attributed string on change

---

## Slice 2: Rich Markdown Rendering

**Goal:** The editor now renders all common markdown elements inline.

**What to build:**
- Extend `MarkdownParser.swift` to handle:
  - **Bold** / *italic* / ~~strikethrough~~
  - `inline code` (monospace + background)
  - Code blocks with ``` (monospace, background block, language label)
  - Bullet lists and numbered lists (with proper indentation)
  - Blockquotes (left border + muted color)
  - Horizontal rules
  - Links (colored, clickable)
- `EditorToolbar.swift` — Floating or pinned toolbar with buttons: H1-H3, Bold, Italic, Code, Bullet List, Numbered List, Blockquote, Link
- Toolbar buttons insert/wrap markdown syntax at cursor position
- "Reveal on edit" behavior: when cursor is on a markdown element, reveal the raw syntax for that line/block

**What it looks like when done:**
Full Typora-style inline rendered editing. Write markdown, see it formatted. Click into a heading, see the `##` prefix. Toolbar lets you format without remembering syntax.

---

## Slice 3: Sidebar + Bookmarked Directories

**Goal:** Add a sidebar with bookmarked (starred) directories and a file tree.

**What to build:**
- `NavigationSplitView` layout: sidebar | editor
- `BookmarkedDirectory.swift` — SwiftData model: name, path, security-scoped bookmark data, display order, icon color
- `SecurityScopedBookmark.swift` — Create/resolve macOS security-scoped bookmarks for persistent folder access
- `SidebarView.swift` — Shows list of bookmarked directories, "Add Directory" button
- `BookmarkListView.swift` — Each bookmark shows folder name, icon, right-click to remove/rename
- `FileTreeView.swift` — When a bookmark is selected, show its file tree
- `FileTreeNode.swift` — File/folder row: icon, name, click to open in editor
- `FileWatcher.swift` — FSEvents-based watcher so the file tree updates when files change on disk
- AI file awareness: special icons for `CLAUDE.md`, `SKILL.md`, `AGENTS.md` files in the tree
- Drag to reorder bookmarks
- Persist bookmarks across launches via SwiftData

**What it looks like when done:**
Left sidebar with your starred project folders. Click a folder → see its files. Click a file → opens in the editor. Files save in place. Star new folders from a "+" button or drag-and-drop.

---

## Slice 4: Tabs + Multi-File Editing

**Goal:** Open multiple files in tabs, work across projects.

**What to build:**
- Tab bar above the editor showing open files
- Each tab = one `EditorDocument` instance
- Tab shows: filename, dot indicator for unsaved changes, close button
- `Cmd+W` closes current tab
- `Cmd+Shift+[` / `]` switches tabs
- Clicking a file in the sidebar opens it in a new tab (or focuses existing tab if already open)
- Tab state persisted across launches (reopen last session)
- Unsaved changes prompt on close

**What it looks like when done:**
You can have `CLAUDE.md` from Project A, `SKILL.md` from Project B, and `agents.md` from Project C all open in tabs, switching freely.

---

## Slice 5: XML Tag Rendering

**Goal:** Make XML tags in markdown render beautifully — the killer feature for AI prompt editing.

**What to build:**
- `XMLTagRenderer.swift` — Detect XML tags within markdown content and render them specially:
  - Opening/closing tags shown as colored pills/badges (e.g., `<tools>` rendered as a teal rounded badge)
  - Tag content indented with a subtle left-border (like a colored blockquote)
  - Collapsible: click a tag pill to collapse/expand its content
  - Nested tags get progressively indented with different border colors
  - Self-closing tags shown as single pills
- Color-coded by tag type:
  - Blue: `<instructions>`, `<system>`
  - Teal: `<tools>`, `<tool>`
  - Purple: `<examples>`, `<example>`
  - Orange: `<artifacts>`, `<artifact>`
  - Gray: all other tags
- Tags are still stored as raw text — rendering is visual only

**What it looks like when done:**
A system prompt file with XML tags looks **gorgeous** — structured, color-coded, collapsible. You can see the hierarchy at a glance instead of scanning raw angle brackets.

---

## Slice 6: Token Counter + Status Bar

**Goal:** Always know how big your prompt/skill is in tokens.

**What to build:**
- `TokenCounter.swift` — Approximate token count using a simple heuristic (words × 1.3 + whitespace adjustment) or integrate `tiktoken` via a bundled Swift port
- Status bar at bottom of editor showing:
  - Token count (updates live as you type)
  - Character count
  - Line count
  - File path
  - File type badge (CLAUDE.md, SKILL.md, etc.)
- Token count color-coded: green < 4K, yellow 4K-8K, orange 8K-32K, red 32K+
- Optional: show token count per XML section when collapsed

**What it looks like when done:**
Glance at the bottom of the editor → instantly know your prompt is 2,847 tokens. Edit a section → watch the count change live.

---

## Slice 7: Fuzzy Finder + Global Search

**Goal:** Quickly find and open any file across all bookmarked projects.

**What to build:**
- `FuzzyFinder.swift` — `Cmd+P` overlay:
  - Indexes all files across all bookmarked directories
  - Fuzzy matching on filename and relative path
  - Shows results ranked by relevance with path context
  - Enter opens file in new tab
  - Prioritize `.md` files, then `.yaml`, `.json`
- `GlobalSearch.swift` — `Cmd+Shift+F` overlay:
  - Full-text search across all bookmarked projects
  - Results show file, line number, context snippet
  - Click result opens file at that line
  - Filter by file type

**What it looks like when done:**
`Cmd+P` → type "skill" → instantly see every SKILL.md across all your projects. Click to open.

---

## Slice 8: Integrated Terminal

**Goal:** Open a terminal pane for any bookmarked directory, optimized for Claude Code.

**What to build:**
- `TerminalEmulator.swift` — Basic terminal backend:
  - Fork a PTY with `/bin/zsh` (or user's default shell)
  - Set working directory to the selected bookmark's path
  - Handle input/output streams
  - Basic ANSI color code rendering
- `TerminalView.swift` — SwiftUI view:
  - Monospace font, dark background
  - Scrollback buffer
  - Text input at bottom
  - Resizable split pane (editor top, terminal bottom) or toggle with `Cmd+``
- `ClaudeCodeLauncher.swift` — Helper that:
  - Detects if `claude` CLI is installed
  - Launches `claude` in the terminal with the correct working directory
  - One-click "Open Claude Code here" button per bookmark
- Terminal per bookmark: each bookmarked directory can have its own terminal session

**What it looks like when done:**
You're editing a SKILL.md → press `Cmd+`` → terminal opens at the bottom → already `cd`'d into that project → type `claude` and start working. Switch to another bookmark → its terminal session is preserved.

---

## Slice 9: New File Creation + Templates

**Goal:** Quickly create new markdown files with AI-aware templates.

**What to build:**
- "New File" in context menu when right-clicking in file tree
- "New File" in menu bar → prompts for location (defaults to current bookmark directory)
- Template picker when creating new files:
  - Blank `.md`
  - `CLAUDE.md` template (with standard sections)
  - `SKILL.md` template (with skill structure)
  - `AGENTS.md` template
  - System Prompt template (with common XML sections)
  - MCP Config template
- Templates stored as bundled resources, user can add custom templates
- `Cmd+N` creates new file in current directory

**What it looks like when done:**
Right-click a folder → New File → pick "SKILL.md Template" → a pre-structured skill file appears ready to fill in. Or `Cmd+N` for a blank file wherever you want.

---

## Slice 10: Themes + Preferences

**Goal:** Make it yours — dark/light theme, font choices, editor tuning.

**What to build:**
- `Theme.swift` — Theme engine:
  - Light and dark mode (follows system by default)
  - Customizable editor font and size (default: a nice monospace-friendly font like Berkeley Mono, SF Mono, or JetBrains Mono)
  - Heading scale factors
  - XML tag color scheme
  - Background, foreground, selection colors
- Preferences window:
  - Appearance: theme, font, font size
  - Editor: tab size, line spacing, show/hide line numbers, word wrap
  - Files: default new file location, auto-save interval
  - Terminal: shell path, font, font size
- `Cmd+,` opens preferences
- Settings persisted via `@AppStorage` / SwiftData

**What it looks like when done:**
A polished, customizable editor that feels like home. Your font, your colors, your spacing.

---

## Future Slices (Backlog)

These are ideas for after the core 10 slices are solid:

- **Slice 11: Diff View** — Side-by-side comparison of two files (great for comparing prompt versions)
- **Slice 12: Git Integration** — Show git status on files, inline diff highlights for uncommitted changes
- **Slice 13: Project Map** — Visual graph showing how files in a project reference each other
- **Slice 14: Snippets** — User-defined text snippets with expansion shortcuts
- **Slice 15: Send to Claude** — Select text → send to Claude Code as context with one click
- **Slice 16: Multiple Windows** — Each window is an independent workspace with its own bookmarks/tabs
- **Slice 17: Markdown Table Editor** — Visual table editing (click cells, add rows/columns)
- **Slice 18: Image Preview** — Inline preview of images referenced in markdown
- **Slice 19: Export** — Export rendered markdown to PDF, HTML
- **Slice 20: Plugin System** — Let users extend with custom renderers, commands, integrations

---

## Build Principles

1. **Ship each slice.** Every slice should result in a usable improvement. Don't half-finish a slice to start the next.
2. **Test the hard parts first.** Within each slice, tackle the riskiest technical challenge first (e.g., NSTextView bridge in Slice 1).
3. **Raw markdown is the source of truth.** Always. The rendered view is a projection. Files on disk are plain `.md`.
4. **Native over library.** Prefer Apple frameworks over third-party dependencies. Every dependency is a future maintenance burden.
5. **Performance matters.** The editor must feel instant. Parsing and rendering should be fast enough that there's no perceptible lag while typing.
6. **Design for keyboard users.** Every common action should have a keyboard shortcut. The mouse is optional.
