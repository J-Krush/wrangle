# Wrangle — SwiftUI Codebase Audit Report

**Date:** 2026-02-22
**Scope:** Full audit of all 36 Swift source files in the Wrangle macOS app
**Target:** macOS 14+ (Sonoma), Swift 5.9+, SwiftUI + AppKit interop

---

## Executive Summary

The codebase uses many correct modern patterns — `@Observable`, `NavigationSplitView`, SwiftData, `@Environment` for DI — but has systemic issues around **thread safety** (missing `@MainActor`, data races in `FileWatcher`, background-thread mutations in `SwiftTermView`), **performance** (synchronous I/O on main thread, regex recreation per parse call), and **duplicated anti-patterns** (manual double-click detection, `onTapGesture` where `Button` belongs).

**20 findings total:** 5 Critical, 5 High, 7 Medium, 3 Low.

---

## Critical Findings

Fix before next feature work. These are correctness issues that can cause crashes, data races, or undefined behavior.

### C-1: Missing `@MainActor` on All `@Observable` Classes

**Severity:** Critical
**Files:** 7 classes across the codebase

| Class | File | Line |
|-------|------|------|
| `AppState` | `Wrangle/App/AppState.swift` | 10–11 |
| `EditorDocument` | `Wrangle/Models/EditorDocument.swift` | 134–135 |
| `WorkspaceTab` | `Wrangle/Models/WorkspaceTab.swift` | 14–15 |
| `TerminalEmulator` | `Wrangle/Terminal/TerminalEmulator.swift` | 13–14 |
| `TerminalSession` | `Wrangle/Terminal/TerminalSession.swift` | 9–10 |
| `TerminalSessionManager` | `Wrangle/Terminal/TerminalSessionManager.swift` | 8–9 |
| `EditorContext` | `Wrangle/Editor/EditorContext.swift` | 19–20 |

**Current code:**
```swift
// AppState.swift:10-11
@Observable
class AppState {
```

**Problem:** `@Observable` classes that drive SwiftUI views must have their properties mutated on the main actor. Without `@MainActor`, the compiler cannot enforce this, and mutations from background contexts (e.g., `Task.detached`, delegate callbacks) silently create data races.

**Fix:**
```swift
@MainActor
@Observable
class AppState {
```

Apply `@MainActor` to all 7 `@Observable` classes. This will surface compiler errors at every call site that mutates these objects off the main thread — which is exactly what we want, because those are the bugs.

---

### C-2: `FileWatcher` Data Race — `nonisolated(unsafe)` Properties

**Severity:** Critical
**File:** `Wrangle/Utilities/FileWatcher.swift`
**Lines:** 9–10 (declarations), 42–55 (mutations)

**Current code:**
```swift
// FileWatcher.swift:9-10
private nonisolated(unsafe) var dispatchSource: DispatchSourceFileSystemObject?
private nonisolated(unsafe) var debounceWorkItem: DispatchWorkItem?
```

```swift
// FileWatcher.swift:42-55 — event handler runs on utility queue
source.setEventHandler { [weak self] in
    guard let self else { return }
    self.debounceWorkItem?.cancel()        // ← read+write from utility queue
    let work = DispatchWorkItem { ... }
    self.debounceWorkItem = work            // ← write from utility queue
    DispatchQueue.global(qos: .utility).asyncAfter(...)
}
```

**Problem:** `nonisolated(unsafe)` tells the compiler "trust me, this is safe" — but it isn't. `debounceWorkItem` is written from the utility queue's event handler and read from `stop()` which runs on the main thread. `dispatchSource` is similarly shared. This is a textbook data race.

**Fix:** Use a dedicated serial dispatch queue for synchronization:
```swift
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private let queue = DispatchQueue(label: "FileWatcher", qos: .utility)
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    // ...
    func start() {
        queue.async { self._start() }
    }
    func stop() {
        queue.sync { self._stop() }
    }
}
```

Alternatively, make `FileWatcher` an actor and use its built-in isolation.

---

### C-3: `SwiftTermView` Delegate Callbacks Mutate `@Observable` on Background Thread

**Severity:** Critical
**File:** `Wrangle/Terminal/SwiftTermView.swift`
**Lines:** 113–126

**Current code:**
```swift
// SwiftTermView.swift:113-115
func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
    session.emulator.title = title  // ← called from SwiftTerm's background thread
}

// SwiftTermView.swift:117-121
func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
    if let dir = directory {
        session.emulator.workingDirectory = URL(fileURLWithPath: dir)  // ← background thread
    }
}

// SwiftTermView.swift:123-126
func processTerminated(source: TerminalView, exitCode: Int32?) {
    session.emulator.isRunning = false  // ← background thread
    session.handleProcessExit()
}
```

**Problem:** SwiftTerm's `LocalProcessTerminalViewDelegate` methods fire on SwiftTerm's internal background thread. These methods directly mutate `@Observable` properties (`title`, `workingDirectory`, `isRunning`) which drive SwiftUI views. This causes undefined behavior — views may read partially-written state or crash.

**Fix:** Dispatch mutations to the main actor:
```swift
func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
    Task { @MainActor in
        session.emulator.title = title
    }
}

func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
    guard let dir = directory else { return }
    Task { @MainActor in
        session.emulator.workingDirectory = URL(fileURLWithPath: dir)
    }
}

func processTerminated(source: TerminalView, exitCode: Int32?) {
    Task { @MainActor in
        session.emulator.isRunning = false
        session.handleProcessExit()
    }
}
```

---

### C-4: `FuzzyFinder` Synchronous Directory Walk on Main Thread

**Severity:** Critical
**File:** `Wrangle/Features/FuzzyFinder.swift`
**Lines:** 121 (call site), 174–186 (implementation)

**Current code:**
```swift
// FuzzyFinder.swift:120-122
.onAppear {
    indexAllFiles()       // ← synchronous, runs on main thread
    isSearchFieldFocused = true
}

// FuzzyFinder.swift:174-186
private func indexAllFiles() {
    var files: [IndexedFile] = []
    for bookmark in bookmarks {
        guard let rootURL = bookmark.resolveURL() else { continue }
        _ = rootURL.startAccessingSecurityScopedResource()
        let rootPath = rootURL.path
        walkDirectory(at: rootURL, rootPath: rootPath, into: &files)  // ← recursive FS walk
        rootURL.stopAccessingSecurityScopedResource()
    }
    allFiles = files
}
```

**Problem:** `indexAllFiles()` recursively walks every bookmarked directory's file tree synchronously on the main thread. For large projects (e.g., a monorepo with thousands of files), this blocks the UI — the fuzzy finder modal appears frozen until indexing completes.

**Fix:** Move the walk to a background task:
```swift
private func indexAllFiles() {
    let currentBookmarks = bookmarks
    Task.detached {
        var files: [IndexedFile] = []
        for bookmark in currentBookmarks {
            guard let rootURL = await MainActor.run({ bookmark.resolveURL() }) else { continue }
            // Note: startAccessingSecurityScopedResource must be on same thread as usage
            _ = rootURL.startAccessingSecurityScopedResource()
            walkDirectory(at: rootURL, rootPath: rootURL.path, into: &files)
            rootURL.stopAccessingSecurityScopedResource()
        }
        await MainActor.run {
            allFiles = files
        }
    }
}
```

---

### C-5: `GlobalSearch` Cross-Thread Security-Scoped Bookmark Access

**Severity:** Critical
**File:** `Wrangle/Features/GlobalSearch.swift`
**Lines:** 218–251

**Current code:**
```swift
// GlobalSearch.swift:218-224 — main thread
var resolvedRoots: [(url: URL, rootPath: String)] = []
for bookmark in currentBookmarks {
    if let url = bookmark.resolveURL() {
        _ = url.startAccessingSecurityScopedResource()  // ← start on main thread
        resolvedRoots.append((url: url, rootPath: url.path))
    }
}

// GlobalSearch.swift:226-251 — background thread
Task.detached {
    var found: [SearchResult] = []
    for root in resolvedRoots {
        searchDirectory(at: root.url, ...)  // ← URL used on background thread
    }
    await MainActor.run {
        self.results = capped
        for root in resolvedRoots {
            root.url.stopAccessingSecurityScopedResource()  // ← stop on main thread
        }
    }
}
```

**Problem:** `startAccessingSecurityScopedResource()` and `stopAccessingSecurityScopedResource()` are reference-counted per-process, not per-thread — so the cross-thread usage *technically* works. However, the real issue is that the file access could be revoked between `start` and the background `searchDirectory` call, and the `stop` call happens inside `MainActor.run` inside `Task.detached`, which is fragile. If the task is cancelled or the view disappears, `stop` may never be called, leaking the security scope.

**Fix:** Use a structured approach — start/stop within the same scope, and handle cancellation:
```swift
private func performSearch() {
    // ...
    searchTask = Task {
        let results = await withTaskGroup(of: [SearchResult].self) { group in
            for bookmark in currentBookmarks {
                group.addTask {
                    guard let url = bookmark.resolveURL() else { return [] }
                    _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    return searchDirectory(at: url, ...)
                }
            }
            return await group.reduce(into: []) { $0 += $1 }
        }
        self.results = Array(results.prefix(200))
        self.isSearching = false
    }
}
```

---

## High Findings

Should be addressed in the next cleanup pass. These affect performance, maintainability, or code quality.

### H-1: `MarkdownParser` Recreates Regex on Every Parse Call

**Severity:** High
**File:** `Wrangle/Editor/MarkdownParser.swift`
**Lines:** 89–91 (helper), 113–438 (13 call sites)

**Current code:**
```swift
// MarkdownParser.swift:89-91
private func regex(_ pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression? {
    try? NSRegularExpression(pattern: pattern, options: options)
}

// Called 13 times during every parse() invocation:
// Lines 113, 177, 206, 235, 267, 268, 307, 331, 362, 386, 410, 438
```

**Problem:** `NSRegularExpression` compilation is expensive. The `parse()` method is called on every keystroke, creating 13 new regex objects each time. This is unnecessary since the patterns are static string literals.

**Contrast with correct pattern already in the codebase:**
```swift
// MarkdownTextView.swift:397-406 — correctly cached as static properties
private static let headingRegex = try! NSRegularExpression(pattern: "^(#{1,6})\\s+", options: .anchorsMatchLines)
private static let boldRegex = try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*|__(.+?)__")
// ... 8 more static regexes
```

**Fix:** Cache all regex patterns as static properties on `MarkdownParser`:
```swift
class MarkdownParser {
    private static let codeBlockRegex = try! NSRegularExpression(
        pattern: "^```[^\\n]*\\n[\\s\\S]*?^```",
        options: .anchorsMatchLines
    )
    private static let inlineCodeRegex = try! NSRegularExpression(
        pattern: "`([^`\\n]+)`"
    )
    // ... 11 more static regexes

    // Remove the regex() helper entirely
}
```

---

### H-2: `BookmarkListView` State Explosion — 10 `@State` Properties

**Severity:** High
**File:** `Wrangle/Sidebar/BookmarkListView.swift`
**Lines:** 11–20

**Current code:**
```swift
// BookmarkListView.swift:11-20
@State private var expandedBookmarks: Set<String> = []
@State private var renamingBookmark: BookmarkedDirectory?
@State private var renameText: String = ""
@State private var showRenameSheet = false
@State private var showColorPicker = false
@State private var colorPickerBookmark: BookmarkedDirectory?
@State private var selectedColor: Color = .blue
@State private var draggingBookmarkID: String?
@State private var lastFileBookmarkClickTime: Date = .distantPast
@State private var lastFileBookmarkClickID: String?
```

**Problem:** 10 `@State` variables managing interrelated modal state (rename, color picker, drag, double-click) makes the view hard to reason about. Several are redundant — e.g., `renamingBookmark` and `showRenameSheet` always change together.

**Fix:** Consolidate into an enum for modal state:
```swift
enum SheetState: Equatable {
    case none
    case renaming(BookmarkedDirectory, text: String)
    case pickingColor(BookmarkedDirectory)
}

@State private var sheetState: SheetState = .none
@State private var expandedBookmarks: Set<String> = []
@State private var draggingBookmarkID: String?
```

---

### H-3: Manual Double-Click Simulation Duplicated in Two Files

**Severity:** High
**Files:**
- `Wrangle/Sidebar/BookmarkListView.swift` lines 148–171
- `Wrangle/Sidebar/FileTreeNode.swift` lines 239–258

**Current code (BookmarkListView):**
```swift
// BookmarkListView.swift:148-152
private func handleFileBookmarkClick(_ bookmark: BookmarkedDirectory) {
    let now = Date()
    let isDoubleClick = lastFileBookmarkClickID == bookmarkID
        && now.timeIntervalSince(lastFileBookmarkClickTime) < 0.3
    // ...
}
```

**Current code (FileTreeNode):**
```swift
// FileTreeNode.swift:239-242
private func handleFileClick() {
    let now = Date()
    let isDoubleClick = lastClickedURL == node.url
        && now.timeIntervalSince(lastClickTime) < 0.3
    // ...
}
```

**Problem:** Identical manual double-click detection logic duplicated across two files, using magic number `0.3` seconds. This pattern is fragile and doesn't respect the user's system double-click speed setting.

**Fix:** The TitleBarTabStrip already demonstrates the correct approach — use SwiftUI's built-in double-click detection:
```swift
.onTapGesture(count: 2) { onDoubleClick() }
.onTapGesture(count: 1) { onSingleClick() }
```

Or use `NSEvent.doubleClickInterval` if manual detection is truly needed.

---

### H-4: `FileTreeView` Uncancelled `Task.detached` with Manual Generation Tracking

**Severity:** High
**File:** `Wrangle/Sidebar/FileTreeView.swift`
**Lines:** 12 (generation state), 185–203 (detached tasks)

**Current code:**
```swift
// FileTreeView.swift:12
@State private var loadGeneration = 0

// FileTreeView.swift:181-192
loadGeneration += 1
let currentGeneration = loadGeneration
isLoading = true

Task.detached {
    let tree = FileNode.buildTree(at: url)
    await MainActor.run {
        guard currentGeneration == loadGeneration else { return }  // ← manual staleness check
        nodes = tree
        isLoading = false
    }
}
```

**Problem:** `Task.detached` launches an unstructured task with no stored reference — it cannot be cancelled. The manual `loadGeneration` counter is a workaround for the lack of cancellation. Additionally, `Task.detached` inherits no actor context, which means it must explicitly hop back to the main actor via `MainActor.run`.

**Fix:** Use a stored `Task` reference with cancellation:
```swift
@State private var loadTask: Task<Void, Never>?

private func loadTree() {
    loadTask?.cancel()
    loadTask = Task {
        let tree = await Task.detached {
            FileNode.buildTree(at: url)
        }.value
        guard !Task.isCancelled else { return }
        nodes = tree
        isLoading = false
    }
}
```

---

### H-5: `TerminalSession.detectedClaudeFile` — Synchronous File System Walk in Computed Property

**Severity:** High
**File:** `Wrangle/Terminal/TerminalSession.swift`
**Lines:** 60–70

**Current code:**
```swift
// TerminalSession.swift:60-70
var detectedClaudeFile: URL? {
    guard let dir = workingDirectory ?? emulator.workingDirectory else { return nil }
    let candidates = ["CLAUDE.md", ".claude.md", ".claude/claude.md"]
    for name in candidates {
        let url = dir.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: url.path) {  // ← sync I/O
            return url
        }
    }
    return nil
}
```

**Problem:** This computed property performs up to 3 synchronous `fileExists` calls. Since `TerminalSession` is `@Observable`, this property may be evaluated during SwiftUI view body computation, blocking the main thread.

**Fix:** Make it a stored property that updates asynchronously when `workingDirectory` changes:
```swift
var detectedClaudeFile: URL?

func updateDetectedClaudeFile() {
    Task {
        let dir = workingDirectory ?? emulator.workingDirectory
        guard let dir else {
            detectedClaudeFile = nil
            return
        }
        let candidates = ["CLAUDE.md", ".claude.md", ".claude/claude.md"]
        let found = await Task.detached {
            candidates.lazy.map { dir.appendingPathComponent($0) }
                .first { FileManager.default.fileExists(atPath: $0.path) }
        }.value
        detectedClaudeFile = found
    }
}
```

---

## Medium Findings

Should be addressed as part of normal development. These are style issues, deprecated APIs, or minor correctness concerns.

### M-1: `onTapGesture` Used Where `Button` Should Be

**Severity:** Medium
**Files & Lines:**
- `Wrangle/Sidebar/BookmarkListView.swift:291-293` — color picker circles
- `Wrangle/Sidebar/FileTreeNode.swift:232-234` — star toggle
- `Wrangle/Features/FuzzyFinder.swift:100-103` — result rows inside List
- `Wrangle/Features/GlobalSearch.swift:134` — result rows inside List

**Current code (BookmarkListView):**
```swift
// BookmarkListView.swift:291-293
Circle()
    .fill(color)
    .frame(width: 28, height: 28)
    .onTapGesture {
        colorPickerBookmark?.iconColorHex = hex
        showColorPicker = false
    }
```

**Problem:** `onTapGesture` does not provide:
- Accessibility labels or roles
- Keyboard navigation (Tab + Enter)
- VoiceOver interaction
- Visual press feedback

**Fix:** Use `Button` with `.plain` or `.borderless` style:
```swift
Button {
    colorPickerBookmark?.iconColorHex = hex
    showColorPicker = false
} label: {
    Circle()
        .fill(color)
        .frame(width: 28, height: 28)
}
.buttonStyle(.plain)
.accessibilityLabel("Select \(hex) color")
```

---

### M-2: `DisclosureGroup` + `onTapGesture` Conflict

**Severity:** Medium
**Files & Lines:**
- `Wrangle/Sidebar/BookmarkListView.swift:54` + `66-69`
- `Wrangle/Sidebar/FileTreeNode.swift:173` + `182-185`

**Current code (FileTreeNode):**
```swift
// FileTreeNode.swift:173-185
DisclosureGroup(isExpanded: $isExpanded) {
    // children...
} label: {
    styledNodeLabel
        .contentShape(Rectangle())
        .onTapGesture {           // ← conflicts with DisclosureGroup's built-in tap
            isExpanded.toggle()
            appState.selectedFileTreeURL = node.url
        }
}
```

**Problem:** `DisclosureGroup` already handles tap-to-expand via its disclosure arrow. Adding `onTapGesture` on the label creates a gesture conflict — the system's tap handler and the custom handler race. This can cause the disclosure to toggle twice (open then immediately close) or to not register at all.

**Fix:** Use `DisclosureGroup`'s `isExpanded` binding and handle selection separately:
```swift
DisclosureGroup(isExpanded: $isExpanded) {
    // children...
} label: {
    Button {
        appState.selectedFileTreeURL = node.url
    } label: {
        styledNodeLabel
    }
    .buttonStyle(.plain)
}
```

---

### M-3: Deprecated `.cornerRadius()` Modifier

**Severity:** Medium
**File:** `Wrangle/Editor/TitleBarTabStrip.swift`
**Line:** 194

**Current code:**
```swift
// TitleBarTabStrip.swift:194
.cornerRadius(6)
```

**Problem:** `.cornerRadius()` is deprecated in favor of `.clipShape()`. The deprecated modifier also clips content, which may not be desired for drag previews.

**Fix:**
```swift
.clipShape(RoundedRectangle(cornerRadius: 6))
```

Note: The rest of the codebase already uses `.clipShape(RoundedRectangle(...))` correctly (e.g., FuzzyFinder.swift:117, GlobalSearch.swift:145).

---

### M-4: Force Unwrap in `ActiveTerminalsView`

**Severity:** Medium
**File:** `Wrangle/Sidebar/ActiveTerminalsView.swift`
**Line:** 88

**Current code:**
```swift
// ActiveTerminalsView.swift:86-89
Button("Close") {
    appState.closeTab(
        appState.tabs.first(where: { $0.terminalSession?.id == session.id })!
    )
}
```

**Problem:** `first(where:)` returns `Optional`. If the tab list changes between the context menu appearing and the user clicking "Close" (e.g., the tab was already closed by a keyboard shortcut), this force unwrap crashes.

**Fix:**
```swift
Button("Close") {
    if let tab = appState.tabs.first(where: { $0.terminalSession?.id == session.id }) {
        appState.closeTab(tab)
    }
}
```

---

### M-5: `DispatchQueue.main.async` Used Instead of `MainActor`

**Severity:** Medium
**Files & Lines:**
- `Wrangle/ContentView.swift:208` — `DispatchQueue.main.async`
- `Wrangle/Sidebar/SidebarView.swift:156` — `DispatchQueue.main.async`
- `Wrangle/Terminal/SwiftTermView.swift:80` — `DispatchQueue.main.asyncAfter`
- `Wrangle/Utilities/FileWatcher.swift:47` — `DispatchQueue.main.async`

**Current code (ContentView):**
```swift
// ContentView.swift:205-213
provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
    guard let data = data as? Data,
          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
    DispatchQueue.main.async {
        appState.openFile(url: url, scopedURL: url)
    }
}
```

**Problem:** Mixing GCD's `DispatchQueue.main` with Swift's `@MainActor` isolation creates two paths to the main thread that the compiler can't reason about together. `DispatchQueue.main.async` bypasses actor isolation checks.

**Fix:** Use `MainActor.run` or `Task { @MainActor in ... }`:
```swift
provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
    guard let data = data as? Data,
          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
    Task { @MainActor in
        appState.openFile(url: url, scopedURL: url)
    }
}
```

---

### M-6: `EditorDocument` Uses `DispatchWorkItem` for Debouncing

**Severity:** Medium
**File:** `Wrangle/Models/EditorDocument.swift`
**Lines:** 150 (property), 228–236 (implementation)

**Current code:**
```swift
// EditorDocument.swift:150
private var statsWorkItem: DispatchWorkItem?

// EditorDocument.swift:228-236
private func scheduleCachedStatsUpdate() {
    statsWorkItem?.cancel()
    let item = DispatchWorkItem { [weak self] in
        guard let self else { return }
        self.updateCachedStats()
    }
    statsWorkItem = item
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
}
```

**Problem:** `DispatchWorkItem` + `DispatchQueue.main.asyncAfter` is the pre-concurrency debounce pattern. It doesn't participate in structured concurrency or actor isolation.

**Contrast with correct pattern already in GlobalSearch:**
```swift
// GlobalSearch.swift:155-167 — correct Task-based debounce
searchTask?.cancel()
searchTask = Task {
    try? await Task.sleep(for: .milliseconds(300))
    guard !Task.isCancelled else { return }
    performSearch()
}
```

**Fix:**
```swift
private var statsTask: Task<Void, Never>?

private func scheduleCachedStatsUpdate() {
    statsTask?.cancel()
    statsTask = Task {
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        updateCachedStats()
    }
}
```

---

### M-7: `TitleBarAccessoryInstaller` Creates `NSHostingView` Without Coordinator Lifecycle Awareness

**Severity:** Medium
**File:** `Wrangle/Editor/TitleBarTabStrip.swift`
**Lines:** 14–36 (makeNSView), 41–48 (dismantleNSView)

**Current code:**
```swift
// TitleBarTabStrip.swift:14-36
func makeNSView(context: Context) -> NSView {
    let view = WindowAccessorView()
    view.onWindow = { [weak coordinator = context.coordinator] window in
        // ...
        let tabStrip = TitleBarTabStrip().environment(appState)
        let hostingView = NSHostingView(rootView: tabStrip)
        let accessoryVC = NSTitlebarAccessoryViewController()
        accessoryVC.view = hostingView
        window.addTitlebarAccessoryViewController(accessoryVC)
        coordinator.accessoryVC = accessoryVC
    }
    return view
}
```

**Problem:** The `NSHostingView` is created inside a closure that fires when the view moves to a window. The `dismantleNSView` properly removes the accessory VC, which is good. However, the `appState` is captured by value when creating the `TitleBarTabStrip` — if `appState` changes identity (unlikely but possible with view recreation), the tab strip would hold a stale reference.

**Note:** The current implementation works correctly for the common case. This is a maintenance concern, not a current bug. The `dismantleNSView` cleanup (lines 41-48) is properly implemented.

---

## Low Findings

Address opportunistically. These are style preferences and minor code organization issues.

### L-1: `FileTreeNodeView` Is ~294 Lines — Should Extract Subviews

**Severity:** Low
**File:** `Wrangle/Sidebar/FileTreeNode.swift`
**Lines:** 148–293

**Problem:** The view struct spans 146 lines with the body at 42 lines (171–212), plus helper methods. The CLAUDE.md convention states views exceeding ~80 lines should be split.

**Fix:** Extract `nodeLabel` (lines 218–237) and `handleFileClick`/`copyFiles` logic into separate types or a view model.

---

### L-2: `SidebarView` Drop State Could Be Consolidated

**Severity:** Low
**File:** `Wrangle/Sidebar/SidebarView.swift`
**Lines:** 10–12

**Current code:**
```swift
@State private var rawDropTargeted = false
@State private var isDropTargeted = false
@State private var hideOverlayTask: Task<Void, Never>?
```

**Problem:** Three `@State` vars manage a single concept: "is a drag hovering?" with debouncing. This could be a single state machine.

**Fix:**
```swift
enum DropState {
    case idle
    case hovering
    case exitDebounce(Task<Void, Never>)
}
@State private var dropState: DropState = .idle
```

---

### L-3: Computed Properties Doing Synchronous File System Checks

**Severity:** Low
**File:** `Wrangle/Sidebar/FileTreeNode.swift`
**Lines:** 54–62 (`isOpenable`)

**Current code:**
```swift
// FileTreeNode.swift:54-62
var isOpenable: Bool {
    if isDirectory { return false }
    let ext = url.pathExtension.lowercased()
    if !ext.isEmpty {
        return Self.openableExtensions.contains(ext)
    }
    return Self.openableFileNames.contains(name.lowercased())
}
```

**Problem:** While `isOpenable` itself only does string operations (which is fine), the `FileNode` struct's `buildTree` method (line 99) calls `FileManager.contentsOfDirectory` synchronously. This is mitigated by `FileTreeView` calling `buildTree` inside `Task.detached`, so this is informational only.

---

## Positive Findings — Patterns to Preserve

These patterns are well-implemented and should be maintained as the codebase evolves.

| # | Pattern | Location | Notes |
|---|---------|----------|-------|
| 1 | `@Observable` macro | 7 model classes | Correct modern pattern (not `ObservableObject`) |
| 2 | `NavigationSplitView` | `ContentView.swift:23` | Correct sidebar/detail layout |
| 3 | SwiftData `@Model` | `BookmarkedDirectory`, `RecentFile` | Proper persistence layer |
| 4 | Task-based debounce | `GlobalSearch.swift:155-167` | Correct cancellable debounce with `Task.sleep` |
| 5 | Generation counter | `FileTreeView.swift:12, 188` | Prevents stale async results |
| 6 | Security-scoped bookmarks | `SecurityScopedBookmark.swift` | Proper sandboxed file access |
| 7 | `Coordinator` with weak NSView | `MarkdownTextView.swift:119` | Prevents retain cycles in NSViewRepresentable |
| 8 | Static regex compilation | `MarkdownTextView.swift:397-406` | `try!` on `static let` with constant patterns |
| 9 | `.clipShape(RoundedRectangle(...))` | `FuzzyFinder:117`, `GlobalSearch:145` | Modern, non-deprecated clipping |
| 10 | `@Environment(AppState.self)` | All views | Correct DI via environment |
| 11 | Value type `FileNode` struct | `FileTreeNode.swift:3` | Immutable tree nodes |
| 12 | `@Bindable` for two-way bindings | `ContentView.swift:21` | Correct pattern for `@Observable` in SwiftUI |
| 13 | `@FocusState` | `FuzzyFinder:10`, `GlobalSearch:47` | Correct focus management |
| 14 | `dismantleNSView` cleanup | `TitleBarTabStrip.swift:41-48` | Proper titlebar accessory removal |
| 15 | Enum-based tab content | `WorkspaceTab.swift:9` | Clean `TabContent` enum (`.document` / `.terminal`) |

---

## Summary by Severity

| Severity | Count | Action |
|----------|-------|--------|
| Critical | 5 | Fix before next feature work |
| High | 5 | Fix in next cleanup pass |
| Medium | 7 | Fix during normal development |
| Low | 3 | Address opportunistically |
| **Total** | **20** | |

## Cross-Reference to CLAUDE.md

Every finding maps to a pattern rule in the updated CLAUDE.md:

| Finding | CLAUDE.md Pattern |
|---------|-------------------|
| C-1 | State Management → `@Observable` + `@MainActor` |
| C-2 | Concurrency → Actor/queue isolation for shared mutable state |
| C-3 | Concurrency → Dispatch to MainActor from delegate callbacks |
| C-4, C-5 | Concurrency → Never do sync I/O on main thread |
| H-1 | Utilities → Cache static regex as `static let` |
| H-2 | View Composition → Consolidate related @State into enum |
| H-3 | View Composition → Use SwiftUI's built-in gesture APIs |
| H-4 | Concurrency → Store Task references for cancellation |
| H-5 | Concurrency → No sync I/O in computed properties |
| M-1 | View Composition → Button over onTapGesture |
| M-2 | View Composition → No onTapGesture on DisclosureGroup labels |
| M-3 | View Composition → `.clipShape()` not `.cornerRadius()` |
| M-4 | Error Handling → Never force unwrap |
| M-5 | Concurrency → `MainActor.run` over `DispatchQueue.main.async` |
| M-6 | Concurrency → Task-based debouncing over DispatchWorkItem |
| M-7 | NSViewRepresentable → Coordinator lifecycle |
