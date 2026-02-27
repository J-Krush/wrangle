# Architecture — Wrangle

## Editor Approach

We use a custom `NSViewRepresentable` wrapping `NSTextView` rather than SwiftUI's `TextEditor` because:
- We need full control over attributed string rendering (headings, code blocks, XML tags)
- We need to intercept keyboard shortcuts
- We need syntax-aware cursor positioning
- SwiftUI's `TextEditor` is too limited for rich editing

## Rendering Model

"Rendered by default" — the editor shows formatted markdown (large headings, styled code blocks, colored XML tags) as you type. Users can toggle to raw source view if needed. This is NOT a preview pane — it's inline rendering like Typora.

The rendering pipeline:
1. User types raw markdown
2. On every change, a parser converts markdown → `NSAttributedString`
3. The attributed string is displayed in the `NSTextView`
4. The underlying file always stores raw markdown
5. When editing near a markdown element (e.g., cursor on a heading), we reveal the raw syntax temporarily for that block

## File-First Philosophy

- No import/export. Files are opened in place, edited in place, saved in place.
- No proprietary format. Everything is `.md` on disk.
- Bookmarks use macOS security-scoped bookmarks so we retain access across launches.
- The app should feel like a file editor, not a note-taking app.

## Chrome & Theming

The window uses a three-layer color system, all defined as appearance-aware dynamic `NSColor`s on `Theme`:

| Layer | Dark | Light | Used by |
|-------|------|-------|---------|
| `Theme.chromeBackground` | `#1C1C1C` | `.windowBackgroundColor` | Window background, titlebar, status bar, editor area |
| `Theme.sidebarBackground` | `#262626` | `#ECECEC` | Sidebar panel — slightly lighter so it reads as a card |
| `Theme.current.editorBackground` | 12% white | 100% white | Editor text area content background |

Key implementation details:
- `TitleBarTabStrip` sets `window.backgroundColor = Theme.chromeBackground` in `makeNSView`
- `ContentView` uses `.toolbarBackground(.hidden, for: .windowToolbar)` to suppress the system toolbar material so the window background shows through
- `SidebarView` uses `.scrollContentBackground(.hidden)` + `.background(Color(nsColor: Theme.sidebarBackground))` to override the default sidebar material
- Colors use `NSColor(name:dynamicProvider:)` with `appearance.bestMatch` — they respond to system appearance changes automatically

Appearance mode (`AppState.appearanceMode`) cycles system → dark → light via a status bar button. It sets both `NSApp.appearance` (for AppKit views like the terminal) and `.preferredColorScheme` (for SwiftUI views).

## Project Structure

```
Wrangle/
├── Wrangle.xcodeproj
├── Wrangle/
│   ├── App/
│   │   ├── WrangleApp.swift               # App entry point, WindowGroup
│   │   ├── AppState.swift                 # Global app state (@Observable), AppearanceMode enum
│   │   └── ContentView.swift              # Main NavigationSplitView layout
│   ├── Models/
│   │   ├── BookmarkedDirectory.swift      # SwiftData @Model for bookmarks
│   │   ├── RecentFile.swift               # SwiftData @Model for recents
│   │   ├── EditorDocument.swift           # Document model (file handle, content, dirty state)
│   │   └── WorkspaceTab.swift             # Tab model with enum TabContent (.document/.terminal)
│   ├── Editor/
│   │   ├── MarkdownTextView.swift         # NSViewRepresentable wrapping NSTextView
│   │   ├── EditorTextView.swift           # Custom NSTextView subclass
│   │   ├── MarkdownParser.swift           # Markdown → NSAttributedString
│   │   ├── XMLTagRenderer.swift           # Special rendering for XML tags in markdown
│   │   ├── TokenCounter.swift             # Approximate token counter
│   │   ├── EditorToolbar.swift            # Formatting toolbar (headings, bold, code, etc.)
│   │   ├── EditorContext.swift            # Editor state (cursor position, active formats)
│   │   ├── TitleBarTabStrip.swift         # Titlebar tab strip via NSTitlebarAccessoryViewController
│   │   ├── JsonToolbar.swift              # JSON-specific formatting toolbar
│   │   └── JsonSyntaxHighlighter.swift    # JSON syntax highlighting
│   ├── Sidebar/
│   │   ├── SidebarView.swift              # Main sidebar container
│   │   ├── BookmarkListView.swift         # Bookmarked locations list
│   │   ├── FileTreeView.swift             # File tree for selected directory
│   │   ├── FileTreeNode.swift             # Individual file/folder node + FileNode model
│   │   ├── ActiveTerminalsView.swift      # Running terminal sessions list
│   │   └── RecentFilesView.swift          # Recent files popover
│   ├── Terminal/
│   │   ├── SwiftTermView.swift            # NSViewRepresentable wrapping SwiftTerm
│   │   ├── TerminalView.swift             # Legacy terminal view (deprecated)
│   │   ├── TerminalTabContentView.swift   # Terminal tab content wrapper
│   │   ├── TerminalEmulator.swift         # Terminal state model (@Observable)
│   │   ├── TerminalSession.swift          # Terminal session model (@Observable)
│   │   ├── TerminalSessionManager.swift   # Session lifecycle management (@Observable)
│   │   └── ClaudeCodeLauncher.swift       # Helper to launch `claude` CLI in a directory
│   ├── Features/
│   │   ├── FuzzyFinder.swift              # Cmd+P file finder across all bookmarks
│   │   ├── GlobalSearch.swift             # Cmd+Shift+F search across all projects
│   │   └── ExternalEditorLauncher.swift   # Open in VS Code / Cursor / etc.
│   ├── Utilities/
│   │   ├── SecurityScopedBookmark.swift   # macOS sandbox bookmark handling
│   │   ├── FileWatcher.swift              # GCD dispatch source for live file tree updates
│   │   └── Theme.swift                    # Editor theme (colors, fonts, spacing)
│   └── Resources/
│       └── Assets.xcassets
├── CLAUDE.md                              # This file
└── docs/
    ├── audit-report.md                    # Full codebase audit (2026-02-22)
    ├── architecture.md                    # Architecture decisions & project structure
    ├── coding-patterns.md                 # Preferred coding patterns with examples
    └── token-counting-research.md
```
