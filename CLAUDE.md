# CLAUDE.md — PromptPad

## Project Overview

PromptPad is a native macOS (Apple Silicon) markdown editor purpose-built for developers working with AI agents, skills, system prompts, and configuration files. Built with Swift and SwiftUI.

Think "Typora meets AI development" — rich rendered editing by default, with deep awareness of the unique file patterns in AI/agent workflows (XML-in-markdown, token counting, `.claude.md` files, SKILL.md files, MCP configs).

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (macOS 14+ / Sonoma minimum)
- **Editor Core:** Custom `NSTextView`-based editor wrapped in SwiftUI, using `NSAttributedString` for rich rendering
- **File System:** Native Foundation `FileManager` APIs + `NSOpenPanel` / `NSSavePanel`
- **Terminal:** Embedded terminal using pseudo-TTY (`posix_spawn` / `forkpty`) for Claude Code integration
- **Persistence:** SwiftData for bookmarks, preferences, recent files
- **Architecture:** MVVM with SwiftUI observation (`@Observable`)

## Key Architecture Decisions

### Editor Approach
We use a custom `NSViewRepresentable` wrapping `NSTextView` rather than SwiftUI's `TextEditor` because:
- We need full control over attributed string rendering (headings, code blocks, XML tags)
- We need to intercept keyboard shortcuts
- We need syntax-aware cursor positioning
- SwiftUI's `TextEditor` is too limited for rich editing

### Rendering Model
"Rendered by default" — the editor shows formatted markdown (large headings, styled code blocks, colored XML tags) as you type. Users can toggle to raw source view if needed. This is NOT a preview pane — it's inline rendering like Typora.

The rendering pipeline:
1. User types raw markdown
2. On every change, a parser converts markdown → `NSAttributedString`
3. The attributed string is displayed in the `NSTextView`
4. The underlying file always stores raw markdown
5. When editing near a markdown element (e.g., cursor on a heading), we reveal the raw syntax temporarily for that block

### File-First Philosophy
- No import/export. Files are opened in place, edited in place, saved in place.
- No proprietary format. Everything is `.md` on disk.
- Bookmarks use macOS security-scoped bookmarks so we retain access across launches.
- The app should feel like a file editor, not a note-taking app.

## Project Structure

```
PromptPad/
├── PromptPad.xcodeproj
├── PromptPad/
│   ├── App/
│   │   ├── PromptPadApp.swift          # App entry point, WindowGroup
│   │   └── AppState.swift              # Global app state
│   ├── Models/
│   │   ├── BookmarkedDirectory.swift   # SwiftData model for bookmarks
│   │   ├── RecentFile.swift            # SwiftData model for recents
│   │   └── EditorDocument.swift        # Document model (file handle, content, dirty state)
│   ├── Editor/
│   │   ├── MarkdownTextView.swift      # NSViewRepresentable wrapping NSTextView
│   │   ├── MarkdownParser.swift        # Markdown → NSAttributedString
│   │   ├── XMLTagRenderer.swift        # Special rendering for XML tags in markdown
│   │   ├── TokenCounter.swift          # Approximate token counter
│   │   └── EditorToolbar.swift         # Formatting toolbar (headings, bold, code, etc.)
│   ├── Sidebar/
│   │   ├── SidebarView.swift           # Main sidebar container
│   │   ├── BookmarkListView.swift      # Starred directories
│   │   ├── FileTreeView.swift          # File tree for selected directory
│   │   └── FileTreeNode.swift          # Individual file/folder node
│   ├── Terminal/
│   │   ├── TerminalView.swift          # Embedded terminal SwiftUI view
│   │   ├── TerminalEmulator.swift      # PTY-based terminal backend
│   │   └── ClaudeCodeLauncher.swift    # Helper to launch `claude` in a directory
│   ├── Features/
│   │   ├── FuzzyFinder.swift           # Cmd+P file finder across all bookmarks
│   │   ├── GlobalSearch.swift          # Search across all bookmarked projects
│   │   └── DiffView.swift             # Side-by-side file comparison
│   ├── Utilities/
│   │   ├── SecurityScopedBookmark.swift # macOS sandbox bookmark handling
│   │   ├── FileWatcher.swift           # FSEvents watcher for live file tree updates
│   │   └── Theme.swift                 # Editor theme (colors, fonts, spacing)
│   └── Resources/
│       └── Assets.xcassets
├── CLAUDE.md                           # This file
└── build-plan.md                       # Build plan with feature slices
```

## Coding Conventions

- Use Swift's modern concurrency (`async/await`, `@Observable`, `@MainActor`)
- Prefer value types (structs) for data, reference types (classes) only when needed (e.g., NSTextView delegates)
- Use `@Observable` macro (not `ObservableObject`) for view models
- Name files after their primary type
- Keep views small — extract subviews into their own files when they exceed ~80 lines
- Use SwiftUI previews for all views where practical
- Error handling: use `Result` type or `throws` — never force unwrap (`!`) except for IBOutlet-style patterns
- Comments: explain *why*, not *what*

## AI-Specific File Awareness

The editor should recognize and give special treatment to:
- `CLAUDE.md` / `.claude.md` — Claude Code project files
- `SKILL.md` — Skill definition files
- `AGENTS.md` — Agent configuration files
- `system-prompt.md` / `system_prompt.md` — System prompts
- Files containing `<tools>`, `<instructions>`, `<system>` XML tags

Special treatment includes:
- Distinct icons in the file tree
- XML tag syntax highlighting/collapsing in the editor
- Token count always visible in status bar for these files

## Build Approach

We build in vertical feature slices. Each slice delivers a working increment of the app that touches both UI and underlying logic. See `build-plan.md` for the full plan.

## Testing Strategy

- Unit tests for: MarkdownParser, TokenCounter, SecurityScopedBookmark
- UI tests for: File open/save flow, bookmark management
- Manual testing for: Editor rendering, terminal integration

## Important Notes for Claude Code

- When creating the Xcode project, use SwiftUI App lifecycle (not AppKit AppDelegate)
- Target macOS 14.0+ (Sonoma) for latest SwiftUI features
- Do NOT use document-based app template — we manage files ourselves
- The app should support multiple windows (each window = one workspace)
- Use `NavigationSplitView` for the sidebar/editor layout
- For the embedded terminal, start simple with a basic text view + process, iterate from there
