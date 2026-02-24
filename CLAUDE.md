# CLAUDE.md — Wrangle

## Project Overview

Wrangle is a native macOS (Apple Silicon) markdown editor purpose-built for developers working with AI agents, skills, system prompts, and configuration files. Built with Swift and SwiftUI.

Think "Typora meets AI development" — rich rendered editing by default, with deep awareness of the unique file patterns in AI/agent workflows (XML-in-markdown, token counting, `.claude.md` files, SKILL.md files, MCP configs).

**Xcode project name:** `wrangle`
**Bundle identifier:** Wrangle

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (macOS 14+ / Sonoma minimum)
- **Editor Core:** Custom `NSTextView`-based editor wrapped in SwiftUI via `NSViewRepresentable`, using `NSAttributedString` for rich rendering
- **Terminal:** Embedded terminal via [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) (`LocalProcessTerminalView`)
- **File System:** Native Foundation `FileManager` APIs + `NSOpenPanel` / `NSSavePanel`
- **Persistence:** SwiftData for bookmarks, preferences, recent files
- **Architecture:** MVVM with SwiftUI observation (`@Observable`, `@MainActor`)

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

### Chrome & Theming
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
wrangle/
├── wrangle.xcodeproj
├── wrangle/
│   ├── App/
│   │   ├── wrangleApp.swift               # App entry point, WindowGroup
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
    └── token-counting-research.md
```

## Coding Conventions

- Use Swift's modern concurrency (`async/await`, `@Observable`, `@MainActor`)
- Prefer value types (structs) for data, reference types (classes) only when needed (e.g., NSTextView delegates, `@Observable` models)
- Use `@Observable` macro (not `ObservableObject`) for view models — always paired with `@MainActor`
- Name files after their primary type
- Keep views small — extract subviews into their own files when they exceed ~80 lines
- Error handling: use `Result` type or `throws` — never force unwrap (`!`) except for static regex compilation
- Comments: explain *why*, not *what*

## Preferred Patterns

### 1. State Management

**Rule:** Every `@Observable` class MUST be annotated with `@MainActor`.

```swift
// CORRECT
@MainActor
@Observable
class AppState {
    var tabs: [WorkspaceTab] = []
}

// INCORRECT — missing @MainActor
@Observable
class AppState {
    var tabs: [WorkspaceTab] = []
}
```

**Rule:** `@State` must be `private`. Use `@Environment(AppState.self)` for dependency injection.

```swift
// CORRECT
@Environment(AppState.self) private var appState
@State private var isExpanded = false

// INCORRECT — @State not private, AppState passed as init param
@State var isExpanded = false
let appState: AppState
```

**Rule:** Use `@Bindable` to create two-way bindings from `@Observable` objects.

```swift
// CORRECT
var body: some View {
    @Bindable var appState = appState
    Toggle("Dark Mode", isOn: $appState.isDarkMode)
}

// INCORRECT — manual Binding construction
Toggle("Dark Mode", isOn: Binding(
    get: { appState.isDarkMode },
    set: { appState.isDarkMode = $0 }
))
```

**Rule:** SwiftData `@Model` classes are separate from `@Observable` view models. Never put `@Model` and `@Observable` on the same class.

---

### 2. Concurrency

**Rule:** Prefer `Task {}` over `Task.detached {}`. Use `Task.detached` only when you explicitly need to escape actor context for CPU-heavy work.

```swift
// CORRECT — stays on MainActor, can access @State
Task {
    let tree = await buildTreeInBackground(url)
    nodes = tree
}

// CORRECT — CPU-heavy work that must not block main actor
let tree = await Task.detached {
    FileNode.buildTree(at: url)
}.value
```

**Rule:** Always store `Task` references for cancellation. Never fire-and-forget `Task.detached`.

```swift
// CORRECT
@State private var loadTask: Task<Void, Never>?

private func reload() {
    loadTask?.cancel()
    loadTask = Task {
        let data = await fetchData()
        guard !Task.isCancelled else { return }
        self.data = data
    }
}

// INCORRECT — no cancellation possible
Task.detached {
    let data = await fetchData()
    await MainActor.run { self.data = data }
}
```

**Rule:** Use Task-based debouncing, not `DispatchWorkItem`.

```swift
// CORRECT
private var debounceTask: Task<Void, Never>?

func onTextChange() {
    debounceTask?.cancel()
    debounceTask = Task {
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        performUpdate()
    }
}

// INCORRECT — pre-concurrency pattern
private var workItem: DispatchWorkItem?

func onTextChange() {
    workItem?.cancel()
    let item = DispatchWorkItem { self.performUpdate() }
    workItem = item
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
}
```

**Rule:** Use `MainActor.run` or `Task { @MainActor in }` instead of `DispatchQueue.main.async`.

```swift
// CORRECT
Task { @MainActor in
    appState.openFile(url: url)
}

// INCORRECT
DispatchQueue.main.async {
    appState.openFile(url: url)
}
```

**Rule:** Never perform synchronous file I/O on the main thread. Never put sync I/O in computed properties on `@Observable` types.

```swift
// CORRECT — async stored property updated on change
var detectedClaudeFile: URL?

func refreshDetectedFile() {
    Task.detached {
        let found = candidates.first { FileManager.default.fileExists(atPath: $0.path) }
        await MainActor.run { self.detectedClaudeFile = found }
    }
}

// INCORRECT — sync I/O in computed property evaluated during view body
var detectedClaudeFile: URL? {
    candidates.first { FileManager.default.fileExists(atPath: $0.path) }
}
```

---

### 3. NSViewRepresentable

**Rule:** Use the Coordinator pattern with a weak reference to the NSView.

```swift
// CORRECT
class Coordinator: NSObject, NSTextViewDelegate {
    weak var textView: NSTextView?
    // ...
}
```

**Rule:** For async operations in Coordinators, use generation counters to discard stale results.

```swift
// CORRECT
private var generation = 0

func reparse() {
    generation += 1
    let currentGen = generation
    Task.detached {
        let result = parse(text)
        await MainActor.run {
            guard currentGen == self.generation else { return }
            self.apply(result)
        }
    }
}
```

**Rule:** For titlebar accessories using `NSTitlebarAccessoryViewController`, always implement `dismantleNSView` to remove the accessory.

---

### 4. View Composition

**Rule:** Use `Button` instead of `onTapGesture` for interactive elements. `Button` provides accessibility, keyboard navigation, and press feedback for free.

```swift
// CORRECT
Button {
    toggleStar()
} label: {
    Image(systemName: isStarred ? "star.fill" : "star")
}
.buttonStyle(.plain)

// INCORRECT — no accessibility, no keyboard nav
Image(systemName: isStarred ? "star.fill" : "star")
    .onTapGesture { toggleStar() }
```

**Rule:** Do NOT put `onTapGesture` on `DisclosureGroup` labels. It conflicts with the built-in expand/collapse behavior.

```swift
// CORRECT — selection is a Button, expansion is the DisclosureGroup
DisclosureGroup(isExpanded: $isExpanded) {
    ForEach(children) { child in ChildView(child) }
} label: {
    Button { selectNode() } label: { nodeLabel }
        .buttonStyle(.plain)
}

// INCORRECT — gesture conflict causes double-toggle
DisclosureGroup(isExpanded: $isExpanded) {
    ForEach(children) { child in ChildView(child) }
} label: {
    nodeLabel.onTapGesture { isExpanded.toggle() }
}
```

**Rule:** Use `.clipShape()` instead of deprecated `.cornerRadius()`.

```swift
// CORRECT
.clipShape(RoundedRectangle(cornerRadius: 6))

// INCORRECT — deprecated
.cornerRadius(6)
```

**Rule:** Never force unwrap optionals except for static regex compilation (`try!` on `static let`).

```swift
// CORRECT — static regex with constant pattern, will never fail
private static let headingRegex = try! NSRegularExpression(
    pattern: "^(#{1,6})\\s+",
    options: .anchorsMatchLines
)

// CORRECT — safe unwrap
if let tab = appState.tabs.first(where: { $0.id == targetID }) {
    appState.closeTab(tab)
}

// INCORRECT — crash risk
appState.closeTab(appState.tabs.first(where: { $0.id == targetID })!)
```

**Rule:** Consolidate related `@State` properties into enums when they represent mutually exclusive states.

```swift
// CORRECT
enum SheetState {
    case none
    case renaming(BookmarkedDirectory, text: String)
    case pickingColor(BookmarkedDirectory)
}
@State private var sheetState: SheetState = .none

// INCORRECT — 6 interdependent @State vars
@State private var showRenameSheet = false
@State private var renamingBookmark: BookmarkedDirectory?
@State private var renameText = ""
@State private var showColorPicker = false
@State private var colorPickerBookmark: BookmarkedDirectory?
@State private var selectedColor: Color = .blue
```

---

### 5. Navigation

- Use `NavigationSplitView` for the sidebar/editor layout
- Use enum-based tab content for type-safe tab switching:

```swift
enum TabContent {
    case document(EditorDocument)
    case terminal(TerminalSession)
}
```

---

### 6. Utilities

**Rule:** Cache all `NSRegularExpression` patterns as `static let` properties. Never create them inside methods that run per-keystroke.

```swift
// CORRECT
class MarkdownParser {
    private static let headingRegex = try! NSRegularExpression(
        pattern: "^(#{1,6})( +)(.+)$",
        options: .anchorsMatchLines
    )
    // Use Self.headingRegex in parse methods
}

// INCORRECT — creates 13 regex objects on every keystroke
func parse(_ text: String) -> NSAttributedString {
    if let pattern = regex("^(#{1,6})( +)(.+)$", options: .anchorsMatchLines) {
        // ...
    }
}
```

**Rule:** Use enum-based namespaces for types that only contain static members.

```swift
// CORRECT
enum SecurityScopedBookmark {
    static func create(for url: URL) throws -> Data { ... }
    static func resolve(_ data: Data) throws -> URL { ... }
}

// INCORRECT — class that should never be instantiated
class SecurityScopedBookmark {
    static func create(for url: URL) throws -> Data { ... }
}
```

---

### 7. Security-Scoped Bookmarks

**Rule:** `startAccessingSecurityScopedResource()` and `stopAccessingSecurityScopedResource()` should be called in the same scope. Use `defer` to guarantee cleanup.

```swift
// CORRECT
func readBookmarkedFile(url: URL) {
    _ = url.startAccessingSecurityScopedResource()
    defer { url.stopAccessingSecurityScopedResource() }
    // ... use the URL
}

// INCORRECT — stop called in a different scope/thread
_ = url.startAccessingSecurityScopedResource()
Task.detached {
    // ... use the URL
    await MainActor.run {
        url.stopAccessingSecurityScopedResource()
    }
}
```

**Rule:** For long-lived access (e.g., open documents), store the resolved URL and stop access in `onDisappear` or `deinit`.

---

### 8. Error Handling

- Use `throws` / `Result` for error propagation
- Never `try!` except for static regex compilation with constant patterns
- Never `try?` silently — at minimum log the error or show user feedback
- Guard against optionals with `guard let` or `if let`, never force unwrap

## AI-Specific File Awareness

The editor should recognize and give special treatment to:
- `CLAUDE.md` / `.claude.md` — Claude Code project files
- `SKILL.md` — Skill definition files
- `AGENTS.md` — Agent configuration files
- `system-prompt.md` / `system_prompt.md` — System prompts
- Files containing `<tools>`, `<instructions>`, `<system>` XML tags

Special treatment includes:
- Distinct icons in the file tree (implemented in `FileType` enum in `EditorDocument.swift`)
- XML tag syntax highlighting/collapsing in the editor
- Token count always visible in status bar for these files

## Build Approach

We build in vertical feature slices. Each slice delivers a working increment of the app that touches both UI and underlying logic.

## Testing Strategy

- Unit tests for: MarkdownParser, TokenCounter, SecurityScopedBookmark
- UI tests for: File open/save flow, bookmark management
- Manual testing for: Editor rendering, terminal integration

## Important Notes for Claude Code

- Use SwiftUI App lifecycle (not AppKit AppDelegate)
- Target macOS 14.0+ (Sonoma) for latest SwiftUI features
- Do NOT use document-based app template — we manage files ourselves
- The app supports multiple windows (each window = one workspace)
- Use `NavigationSplitView` for the sidebar/editor layout
- Terminal is implemented via SwiftTerm's `LocalProcessTerminalView`, not a custom PTY
- Always consult `docs/audit-report.md` for known issues before modifying affected files
