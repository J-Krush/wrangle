# Preferred Coding Patterns — Wrangle

## 1. State Management

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

## 2. Concurrency

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

## 3. NSViewRepresentable

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

## 4. View Composition

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

## 5. Navigation

- Use `NavigationSplitView` for the sidebar/editor layout
- Use enum-based tab content for type-safe tab switching:

```swift
enum TabContent {
    case document(EditorDocument)
    case terminal(TerminalSession)
}
```

---

## 6. Utilities

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

## 7. Security-Scoped Bookmarks

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

## 8. Error Handling

- Use `throws` / `Result` for error propagation
- Never `try!` except for static regex compilation with constant patterns
- Never `try?` silently — at minimum log the error or show user feedback
- Guard against optionals with `guard let` or `if let`, never force unwrap
