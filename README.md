# Wrangle

A native macOS markdown editor purpose-built for developers working with AI agents, skills, system prompts, and configuration files.

## Overview

Wrangle brings Typora-style inline rendering to AI development workflows. Instead of a split preview pane, markdown is rendered in-place as you type — headings scale up, code blocks get highlighted, and XML tags are color-coded — while the underlying file stays plain `.md` on disk. It's a file editor, not a note-taking app.

Built for developers who spend their day in `CLAUDE.md`, `SKILL.md`, system prompts, and MCP configs, Wrangle understands these file patterns natively and provides an embedded terminal so you can stay in one window.

## Key Features

- **Inline markdown rendering** — Rich formatting displayed as you type, raw syntax revealed at the cursor
- **XML-in-markdown highlighting** — First-class rendering for `<tools>`, `<instructions>`, and other XML tags common in AI prompts
- **Embedded terminal** — Full terminal via SwiftTerm, launch shells or Claude Code sessions without leaving the editor
- **Token counting** — Approximate token counts in the status bar for prompt files
- **Fuzzy finder** — `Cmd+P` to quickly open any file across all bookmarked projects
- **File tree with bookmarks** — Bookmark directories for fast access with security-scoped persistence
- **AI file recognition** — Distinct icons and behavior for `CLAUDE.md`, `SKILL.md`, `AGENTS.md`, and system prompt files

## Getting Started

### Prerequisites

- macOS 14.0+ (Sonoma)
- Xcode 16+
- Apple Silicon (native target)

### Build & Run

```bash
git clone <repo-url>
open wrangle.xcodeproj
# Build & Run with Cmd+R
```

Dependencies (SwiftTerm) are resolved automatically via Swift Package Manager on first build.

> **Note:** The App Sandbox entitlement is disabled. This is required for the embedded terminal to launch child processes.

## Project Structure

```
wrangle/
├── App/              # App entry point, global state, main layout
├── Editor/           # NSTextView-based markdown editor, parser, tab strip
├── Sidebar/          # File tree, bookmarks, terminal list
├── Terminal/          # SwiftTerm integration, session management
├── Features/         # Fuzzy finder, global search, external editor launch
├── Models/           # SwiftData models (bookmarks, recents, tabs)
├── Utilities/        # Theme, file watcher, security-scoped bookmarks
└── Resources/        # Asset catalog
```

## Architecture

- **SwiftUI + NSTextView hybrid** — SwiftUI for layout and navigation, a custom `NSViewRepresentable` wrapping `NSTextView` for the editor core (full control over attributed string rendering, keyboard shortcuts, and cursor behavior)
- **MVVM with `@Observable`** — All view models use the `@Observable` macro with `@MainActor` isolation
- **SwiftData** — Persistence for bookmarks, recent files, and preferences
- **Swift concurrency** — `async/await` throughout, task-based debouncing, no GCD unless required by system APIs
