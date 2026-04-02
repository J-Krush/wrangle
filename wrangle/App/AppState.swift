import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum EditingMode: String, CaseIterable {
    case writing
    case dev
}

enum ViewMode: String, CaseIterable {
    case editor
    case dashboard
    case canvas

}

enum AppearanceMode: String, CaseIterable {
    case system, light, dark
}

// MARK: - Navigation History

struct NavigationEntry: Equatable {
    let roomID: String?
    let tabID: UUID?
    let viewMode: ViewMode
    let timestamp: Date

    static func == (lhs: NavigationEntry, rhs: NavigationEntry) -> Bool {
        lhs.roomID == rhs.roomID && lhs.tabID == rhs.tabID && lhs.viewMode == rhs.viewMode
    }
}

@MainActor
@Observable
class AppState {
    let windowID = UUID()
    weak var coordinator: AppCoordinator?
    weak var nsWindow: NSWindow?

    var tabs: [WorkspaceTab]
    var activeTabIndex: Int
    var selectedRoomID: String?
    var activeIntentID: String?
    var selectedBookmarkID: String?
    var isSidebarVisible: Bool = true
    var sidebarWidth: CGFloat = 200
    var roomTabIndexes: [String: Int] = [:]
    /// Per-room expanded location state so sidebar hierarchy survives room switches
    var roomExpandedBookmarks: [String: Set<String>] = [:]
    var showFuzzyFinder: Bool = false
    var showGlobalSearch: Bool = false
    var searchQuery: String = ""
    var detailAreaLeading: CGFloat = 240
    var editingMode: EditingMode = .writing
    var viewMode: ViewMode = .dashboard
    var sidebarFilterText: String = ""
    var showActiveSessionsOnly: Bool = false
    var selectedFileTreeURL: URL? = nil
    var revealFileURL: URL? = nil
    // Preview tab tracking — only one preview tab at a time
    var previewTabID: UUID? = nil

    // Terminal close confirmation state
    var pendingCloseTabIndex: Int?
    var showTerminalCloseConfirmation: Bool = false

    // Navigation history (back/forward)
    private var navHistory: [NavigationEntry] = []
    private var navIndex: Int = -1
    private var isNavigatingHistory = false
    var canGoBack: Bool { navIndex > 0 }
    var canGoForward: Bool { navIndex < navHistory.count - 1 }

    // Terminal session manager (retained for stopAll on quit)
    var terminalSessionManager = TerminalSessionManager()

    // Scratch pad manager
    var scratchPadManager = ScratchPadManager()

    // Computed delegates to coordinator for app-global state
    var appearanceMode: AppearanceMode {
        get { coordinator?.appearanceMode ?? .system }
        set { coordinator?.appearanceMode = newValue }
    }

    var isAppForeground: Bool {
        get { coordinator?.isAppForeground ?? true }
        set { coordinator?.isAppForeground = newValue }
    }

    // Set by ContentView from the @Query bookmarks array
    var activeProjectName: String?

    // Cached resolved bookmark URLs for scoped-access fallback
    var resolvedBookmarkURLs: [(directoryPath: String, resolvedURL: URL)] = []

    // MARK: - Room Tab Scoping

    /// Tabs visible for the currently selected room
    var visibleTabs: [WorkspaceTab] {
        guard let roomID = selectedRoomID else { return tabs }
        return tabs.filter { $0.roomID == roomID }
    }

    /// Index of the active tab within visibleTabs
    var visibleActiveIndex: Int {
        guard let active = activeTab else { return -1 }
        return visibleTabs.firstIndex(where: { $0.id == active.id }) ?? -1
    }

    /// Select a tab by its index in the visibleTabs array
    func selectVisibleTab(at visibleIndex: Int) {
        let visible = visibleTabs
        guard visibleIndex >= 0, visibleIndex < visible.count else { return }
        let tab = visible[visibleIndex]
        if let globalIndex = tabs.firstIndex(where: { $0.id == tab.id }) {
            selectTab(at: globalIndex)
        }
    }

    /// Close a tab by its index in the visibleTabs array
    func closeVisibleTab(at visibleIndex: Int) {
        let visible = visibleTabs
        guard visibleIndex >= 0, visibleIndex < visible.count else { return }
        let tab = visible[visibleIndex]
        if let globalIndex = tabs.firstIndex(where: { $0.id == tab.id }) {
            closeTab(at: globalIndex)
        }
    }

    /// Navigate to the All Projects dashboard view.
    func showAllProjects() {
        if let currentRoom = selectedRoomID {
            saveBrowserState(forRoom: currentRoom)
            saveTerminalState(forRoom: currentRoom)
        }
        selectedRoomID = nil
        activeIntentID = nil
        viewMode = .dashboard
        pushNavigation()
    }

    /// Called when switching rooms — saves current room's active tab, restores new room's
    func switchToRoom(_ newRoomID: String) {
        // Save current room's active tab and browser state
        if let currentRoom = selectedRoomID {
            if let activeID = activeTab?.id {
                if let visIdx = visibleTabs.firstIndex(where: { $0.id == activeID }) {
                    roomTabIndexes[currentRoom] = visIdx
                }
            }
            saveBrowserState(forRoom: currentRoom)
            saveTerminalState(forRoom: currentRoom)
        }

        selectedRoomID = newRoomID
        activeIntentID = nil
        viewMode = .editor

        // Ensure room overview tab exists
        ensureRoomOverviewTab(forRoom: newRoomID)

        // Restore browser and terminal sessions for the new room if none exist
        restoreBrowserState(forRoom: newRoomID)
        restoreTerminalState(forRoom: newRoomID)

        // Restore new room's active tab
        let newVisible = visibleTabs
        if newVisible.isEmpty {
            activeTabIndex = -1
        } else {
            let savedIndex = roomTabIndexes[newRoomID] ?? 0
            let clampedIndex = min(savedIndex, newVisible.count - 1)
            let tab = newVisible[max(0, clampedIndex)]
            if let globalIndex = tabs.firstIndex(where: { $0.id == tab.id }) {
                activeTabIndex = globalIndex
            }
        }

        pushNavigation()
    }

    // MARK: - Navigation History

    /// Record the current view state as a history entry.
    func pushNavigation() {
        guard !isNavigatingHistory else { return }

        // Skip recording if the active tab is a preview tab (clicking through files in sidebar)
        if let activeID = activeTab?.id, activeID == previewTabID {
            return
        }

        let entry = NavigationEntry(
            roomID: selectedRoomID,
            tabID: activeTab?.id,
            viewMode: viewMode,
            timestamp: Date()
        )

        // Don't push duplicates
        if navIndex >= 0, navIndex < navHistory.count, navHistory[navIndex] == entry {
            return
        }

        // Truncate forward history when pushing new entry (like browser)
        if navIndex < navHistory.count - 1 {
            navHistory.removeSubrange((navIndex + 1)...)
        }

        navHistory.append(entry)

        // Cap history at 200 entries
        if navHistory.count > 200 {
            navHistory.removeFirst(navHistory.count - 200)
        }

        navIndex = navHistory.count - 1
    }

    func goBack() {
        guard canGoBack else { return }
        isNavigatingHistory = true
        navIndex -= 1
        applyNavigationEntry(navHistory[navIndex])
        isNavigatingHistory = false
    }

    func goForward() {
        guard canGoForward else { return }
        isNavigatingHistory = true
        navIndex += 1
        applyNavigationEntry(navHistory[navIndex])
        isNavigatingHistory = false
    }

    private func applyNavigationEntry(_ entry: NavigationEntry) {
        // Switch room if needed
        if entry.roomID != selectedRoomID {
            if let roomID = entry.roomID {
                switchToRoom(roomID)
            } else {
                selectedRoomID = nil
            }
        }

        // Set view mode
        viewMode = entry.viewMode

        // Select the tab if it still exists
        if let tabID = entry.tabID,
           let index = tabs.firstIndex(where: { $0.id == tabID }) {
            activeTabIndex = index
        } else {
            // Tab no longer exists -- fallback to first visible tab
            let visible = visibleTabs
            if let first = visible.first,
               let index = tabs.firstIndex(where: { $0.id == first.id }) {
                activeTabIndex = index
            }
        }
    }

    // MARK: - Computed Properties

    var activeTab: WorkspaceTab? {
        guard activeTabIndex >= 0, activeTabIndex < tabs.count else { return nil }
        return tabs[activeTabIndex]
    }

    var activeDocument: EditorDocument? {
        activeTab?.document
    }

    /// All open documents across tabs (for save-all, etc.)
    var openDocuments: [EditorDocument] {
        tabs.compactMap(\.document)
    }

    /// All open terminal sessions across tabs
    var openTerminalSessions: [TerminalSession] {
        tabs.compactMap(\.terminalSession)
    }

    /// Terminal sessions belonging to a specific bookmark location
    func terminalSessions(for bookmarkID: String) -> [TerminalSession] {
        let all = tabs.compactMap(\.terminalSession).filter { $0.bookmarkID == bookmarkID }
        guard let intentID = activeIntentID else { return all }
        // Show sessions tagged to the active intent + unscoped sessions
        return all.filter { $0.intentID == intentID || $0.intentID == nil }
    }

    /// Terminal sessions with no associated bookmark (opened via Browse, etc.)
    var orphanedTerminalSessions: [TerminalSession] {
        tabs.compactMap(\.terminalSession).filter { $0.bookmarkID == nil }
    }

    init() {
        self.tabs = []
        self.activeTabIndex = -1
        // Seed the initial "All Projects" entry so back button works from first room
        pushNavigation()
    }

    // MARK: - Scratch Pads

    func newScratchPad(name: String? = nil) {
        let url: URL
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            url = scratchPadManager.createScratchPad(name: name, roomID: selectedRoomID)
        } else {
            url = scratchPadManager.createScratchPadWithTimestamp(roomID: selectedRoomID)
        }
        openFile(url: url)
    }

    // MARK: - Scoped URL Resolution

    /// Finds a parent bookmark URL that covers the given file URL.
    func findScopedURL(for url: URL) -> URL? {
        let filePath = url.path(percentEncoded: false)
        for entry in resolvedBookmarkURLs {
            if filePath.hasPrefix(entry.directoryPath) {
                return entry.resolvedURL
            }
        }
        return nil
    }

    // MARK: - Document Methods

    func openFile(url: URL, scopedURL: URL? = nil) {
        // Switch to editor when opening a file
        viewMode = .editor

        // Check if this file is already open in a tab
        if let existingIndex = tabs.firstIndex(where: { $0.document?.fileURL == url }) {
            activeTabIndex = existingIndex
            pushNavigation()
            return
        }

        let document = EditorDocument(fileURL: url)
        let effectiveScopedURL = scopedURL ?? findScopedURL(for: url)
        if let effectiveScopedURL {
            document.retainAccess(from: effectiveScopedURL)
        }
        document.isLoading = true
        let tab = WorkspaceTab(content: .document(document))
        tab.roomID = selectedRoomID
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
        pushNavigation()

        loadDocumentAsync(for: document, from: url)
    }

    func openFileAsPreview(url: URL, scopedURL: URL? = nil) {
        viewMode = .editor
        print("[AppState] openFileAsPreview: \(url.lastPathComponent), scopedURL: \(scopedURL?.path ?? "nil")")

        // If already open, just select it
        if let existingIndex = tabs.firstIndex(where: { $0.document?.fileURL == url }) {
            print("[AppState]   → already open at index \(existingIndex), selecting")
            activeTabIndex = existingIndex
            return
        }

        let document = EditorDocument(fileURL: url)
        let effectiveScopedURL = scopedURL ?? findScopedURL(for: url)
        if let effectiveScopedURL {
            document.retainAccess(from: effectiveScopedURL)
        }
        document.isLoading = true
        let tab = WorkspaceTab(content: .document(document))
        tab.roomID = selectedRoomID

        // Replace existing preview tab if one exists
        if let previewID = previewTabID,
           let previewIndex = tabs.firstIndex(where: { $0.id == previewID }) {
            print("[AppState]   → replacing preview tab at index \(previewIndex)")
            tabs[previewIndex] = tab
            activeTabIndex = previewIndex
        } else {
            print("[AppState]   → appending new tab, index will be \(tabs.count)")
            tabs.append(tab)
            activeTabIndex = tabs.count - 1
        }
        print("[AppState]   → activeTabIndex=\(activeTabIndex), tabs.count=\(tabs.count), previewTabID=\(tab.id)")
        previewTabID = tab.id

        loadDocumentAsync(for: document, from: url)
    }

    private func loadDocumentAsync(for document: EditorDocument, from url: URL) {
        print("[AppState] loadDocumentAsync: reading \(url.lastPathComponent)")
        Task {
            let result = await Task.detached {
                do {
                    return Result<String, Error>.success(try String(contentsOf: url, encoding: .utf8))
                } catch {
                    do {
                        return Result<String, Error>.success(try String(contentsOf: url, encoding: .isoLatin1))
                    } catch {
                        return Result<String, Error>.failure(error)
                    }
                }
            }.value
            switch result {
            case .success(let fileContent):
                print("[AppState]   → load result: success (\(fileContent.count) chars)")
                document.content = fileContent
                document.lastSavedContent = fileContent
                document.isDirty = false
                document.loadError = nil
            case .failure(let error):
                print("[AppState]   → load result: FAILED: \(error.localizedDescription)")
                document.loadError = error.localizedDescription
            }
            document.isLoading = false
            document.updateCachedStats()
        }
    }

    func promotePreviewTab(for documentID: UUID) {
        if let previewID = previewTabID,
           let tab = tabs.first(where: { $0.id == previewID }),
           tab.document?.id == documentID {
            previewTabID = nil
        }
    }

    func newDocument() {
        let panel = NSSavePanel()
        panel.title = "New File"
        panel.nameFieldStringValue = "Untitled.md"
        panel.allowedContentTypes = [.plainText, .json, .yaml]
        panel.allowsOtherFileTypes = true
        panel.isExtensionHidden = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Create the file on disk (empty)
        FileManager.default.createFile(atPath: url.path, contents: nil)

        let document = EditorDocument(fileURL: url)
        let tab = WorkspaceTab(content: .document(document))
        tab.roomID = selectedRoomID
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
        pushNavigation()
    }

    // MARK: - Tab Management

    func moveTab(fromID sourceID: UUID, toID destinationID: UUID) {
        guard sourceID != destinationID,
              let fromIndex = tabs.firstIndex(where: { $0.id == sourceID }),
              let toIndex = tabs.firstIndex(where: { $0.id == destinationID })
        else { return }

        let activeID = activeTab?.id
        let tab = tabs.remove(at: fromIndex)
        tabs.insert(tab, at: toIndex)

        if let activeID, let newActiveIndex = tabs.firstIndex(where: { $0.id == activeID }) {
            activeTabIndex = newActiveIndex
        }
    }

    func moveTabToEnd(sourceID: UUID) {
        guard let fromIndex = tabs.firstIndex(where: { $0.id == sourceID }),
              fromIndex != tabs.count - 1
        else { return }

        let activeID = activeTab?.id
        let tab = tabs.remove(at: fromIndex)
        tabs.append(tab)

        if let activeID, let newActiveIndex = tabs.firstIndex(where: { $0.id == activeID }) {
            activeTabIndex = newActiveIndex
        }
    }

    func selectTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        activeTabIndex = index
        tabs[index].terminalSession?.needsAttention = false
        // Deselect sidebar location when overview tab is active
        if tabs[index].isRoomOverview {
            selectedBookmarkID = nil
        }
        pushNavigation()
    }

    func closeTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        let closedTab = tabs[index]

        // Room overview tabs cannot be closed
        if closedTab.isRoomOverview { return }

        let closedName = closedTab.displayName

        // Clear preview if this was the preview tab
        if previewTabID == closedTab.id {
            previewTabID = nil
        }

        // Stop terminal if closing a terminal tab
        if let session = closedTab.terminalSession {
            session.stop()
        }

        tabs.remove(at: index)

        if tabs.isEmpty {
            activeTabIndex = -1
        } else if visibleTabs.isEmpty {
            // No visible tabs in this room — nothing to select
            activeTabIndex = -1
        } else if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        } else if activeTabIndex > index {
            activeTabIndex -= 1
        }

    }

    func closeAllTabs() {
        // Close only visible tabs (current room), preserving room overview tabs
        let visible = visibleTabs
        for tab in visible {
            if tab.isRoomOverview { continue }
            if let session = tab.terminalSession {
                session.stop()
            }
            tabs.removeAll { $0.id == tab.id }
        }
        previewTabID = nil
        // Select the overview tab if it exists
        if let overviewIndex = tabs.firstIndex(where: { $0.isRoomOverview && $0.roomID == selectedRoomID }) {
            activeTabIndex = overviewIndex
        } else {
            activeTabIndex = -1
        }
    }

    func closeTab(_ tab: WorkspaceTab) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            closeTab(at: index)
        }
    }

    // Convenience aliases for backward compatibility
    func closeDocument(at index: Int) {
        // Find the index in tabs that corresponds to the nth document
        closeTab(at: index)
    }

    func closeDocument(_ document: EditorDocument) {
        if let index = tabs.firstIndex(where: { $0.document?.id == document.id }) {
            closeTab(at: index)
        }
    }

    func selectDocument(at index: Int) {
        selectTab(at: index)
    }

    func saveActiveDocument() throws {
        guard let document = activeDocument else { return }
        try document.save()
    }

    // MARK: - Terminal Methods

    /// Requests closing a tab, showing a confirmation dialog if it's a running terminal.
    func requestCloseTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        let tab = tabs[index]

        // Room overview tabs cannot be closed
        if tab.isRoomOverview { return }

        // If it's a running terminal, show confirmation
        if let session = tab.terminalSession, session.isRunning {
            pendingCloseTabIndex = index
            showTerminalCloseConfirmation = true
        } else {
            closeTab(at: index)
        }
    }

    func confirmCloseTab() {
        if let index = pendingCloseTabIndex {
            closeTab(at: index)
        }
        pendingCloseTabIndex = nil
        showTerminalCloseConfirmation = false
    }

    func cancelCloseTab() {
        pendingCloseTabIndex = nil
        showTerminalCloseConfirmation = false
    }

    func openTerminal(projectName: String, directory: URL?, bookmarkID: String?, launchClaude: Bool = false, launchGemini: Bool = false, dangerousMode: Bool = false) {
        viewMode = .editor
        let emulator = TerminalEmulator()
        // Don't start the process here — SwiftTermView will start it when rendered

        let session = TerminalSession(
            emulator: emulator,
            projectName: projectName,
            workingDirectory: directory,
            bookmarkID: bookmarkID,
            isClaude: launchClaude,
            isGemini: launchGemini
        )
        session.intentID = activeIntentID

        if launchClaude {
            session.pendingCommand = ClaudeCodeLauncher.launchCommand(dangerousMode: dangerousMode)
        } else if launchGemini {
            session.pendingCommand = GeminiCodeLauncher.launchCommand()
        }

        // Deduplicate terminal display names (e.g., "my-project", "my-project 2")
        let baseName = session.displayTitle
        let uniqueName = uniqueTerminalName(for: baseName)
        if uniqueName != baseName {
            session.customTitle = uniqueName
        }

        let tab = WorkspaceTab(content: .terminal(session))
        tab.roomID = selectedRoomID
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
        pushNavigation()
    }

    /// Opens a terminal (or AI session) using the active project's context.
    func openTerminalForActiveProject(launchClaude: Bool = false, launchGemini: Bool = false) {
        let directory = activeDocument?.fileURL?.deletingLastPathComponent()
        openTerminal(
            projectName: activeProjectName ?? "Terminal",
            directory: directory,
            bookmarkID: selectedBookmarkID,
            launchClaude: launchClaude,
            launchGemini: launchGemini
        )
    }

    /// Find the tab index for a given terminal session
    func tabIndex(for session: TerminalSession) -> Int? {
        tabs.firstIndex(where: { $0.terminalSession?.id == session.id })
    }

    /// Returns a unique terminal display name by appending " 2", " 3", etc. if the base name is already in use.
    private func uniqueTerminalName(for baseName: String) -> String {
        let existingNames = Set(
            tabs.compactMap { $0.terminalSession?.displayTitle }
        )
        if !existingNames.contains(baseName) { return baseName }

        var n = 2
        while existingNames.contains("\(baseName) \(n)") { n += 1 }
        return "\(baseName) \(n)"
    }

    // MARK: - Browser Methods

    func openBrowser(url: URL? = nil, bookmarkID: String? = nil) {
        viewMode = .editor

        let session = BrowserSession(
            url: url,
            bookmarkID: bookmarkID ?? selectedBookmarkID,
            intentID: activeIntentID,
            roomID: selectedRoomID
        )

        let tab = WorkspaceTab(content: .browser(session))
        tab.roomID = selectedRoomID
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
        pushNavigation()
    }

    func openBrowserForActiveProject(url: URL? = nil) {
        openBrowser(url: url, bookmarkID: selectedBookmarkID)
    }

    /// All open browser sessions across tabs
    var openBrowserSessions: [BrowserSession] {
        tabs.compactMap(\.browserSession)
    }

    /// Browser sessions belonging to a specific bookmark location
    func browserSessions(for bookmarkID: String) -> [BrowserSession] {
        let all = tabs.compactMap(\.browserSession).filter { $0.bookmarkID == bookmarkID }
        guard let intentID = activeIntentID else { return all }
        return all.filter { $0.intentID == intentID || $0.intentID == nil }
    }

    /// Browser sessions for the currently selected room
    var roomBrowserSessions: [BrowserSession] {
        guard let roomID = selectedRoomID else { return [] }
        return tabs.compactMap(\.browserSession).filter { $0.roomID == roomID }
    }

    /// Browser sessions with no associated room
    var orphanedBrowserSessions: [BrowserSession] {
        tabs.compactMap(\.browserSession).filter { $0.roomID == nil }
    }

    /// Find the tab index for a given browser session
    func tabIndex(for session: BrowserSession) -> Int? {
        tabs.firstIndex(where: { $0.browserSession?.id == session.id })
    }

    // MARK: - Browser Hybrid Tab Operations

    /// Pop an internal browser tab out into its own workspace tab
    func popOutBrowserTab(_ browserTab: BrowserTab, from session: BrowserSession) {
        guard let tabIndex = session.tabs.firstIndex(where: { $0.id == browserTab.id }) else { return }

        // Remove from source session
        session.tabs.remove(at: tabIndex)
        if session.tabs.isEmpty {
            session.tabs.append(BrowserTab())
        }
        if session.activeTabIndex >= session.tabs.count {
            session.activeTabIndex = session.tabs.count - 1
        }

        // Create new session with just the popped tab
        let newSession = BrowserSession(
            bookmarkID: session.bookmarkID,
            intentID: session.intentID,
            roomID: session.roomID
        )
        newSession.tabs = [browserTab]
        newSession.activeTabIndex = 0

        let tab = WorkspaceTab(content: .browser(newSession))
        tab.roomID = selectedRoomID
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
    }

    /// Merge a solo browser session's tab into another browser session
    func mergeBrowserTab(from sourceSession: BrowserSession, into targetSession: BrowserSession) {
        guard let sourceTab = sourceSession.activeTab else { return }

        // Move tab to target
        targetSession.tabs.append(sourceTab)
        targetSession.activeTabIndex = targetSession.tabs.count - 1

        // Remove source tab from its session
        sourceSession.tabs.removeAll { $0.id == sourceTab.id }

        // If source session is now empty, close its workspace tab
        if sourceSession.tabs.isEmpty {
            if let wsIndex = tabs.firstIndex(where: { $0.browserSession?.id == sourceSession.id }) {
                closeTab(at: wsIndex)
            }
        }
    }

    // MARK: - Room Overview Tab

    /// Ensures a room overview tab exists as the first tab for the given room.
    func ensureRoomOverviewTab(forRoom roomID: String) {
        let hasOverview = tabs.contains { $0.roomOverviewID == roomID }
        guard !hasOverview else { return }

        let tab = WorkspaceTab(content: .roomOverview(roomID))
        tab.roomID = roomID
        tab.isPinned = true

        // Insert before any other tabs for this room
        if let firstRoomIndex = tabs.firstIndex(where: { $0.roomID == roomID }) {
            tabs.insert(tab, at: firstRoomIndex)
            // Adjust activeTabIndex if it shifted
            if activeTabIndex >= firstRoomIndex {
                activeTabIndex += 1
            }
        } else {
            tabs.append(tab)
        }
    }

    // MARK: - Browser Persistence

    func saveBrowserState(forRoom roomID: String) {
        let roomBrowserSessions = openBrowserSessions.filter { $0.roomID == roomID }
        BrowserStateStore.save(sessions: roomBrowserSessions, forRoom: roomID)
    }

    func restoreBrowserState(forRoom roomID: String) {
        // Only restore if no browser tabs exist for this room
        let existing = openBrowserSessions.filter { $0.roomID == roomID }
        guard existing.isEmpty else { return }

        let states = BrowserStateStore.restore(forRoom: roomID)
        for state in states {
            let session = BrowserSession(
                bookmarkID: state.bookmarkID,
                intentID: state.intentID,
                roomID: roomID
            )
            session.isDevToolsVisible = state.isDevToolsVisible

            // Restore tabs
            session.tabs.removeAll()
            for tabState in state.tabs {
                let url = tabState.url.flatMap { URL(string: $0) }
                let tab = BrowserTab(url: url)
                tab.title = tabState.title
                session.tabs.append(tab)
            }
            if session.tabs.isEmpty {
                session.tabs.append(BrowserTab())
            }
            session.activeTabIndex = min(state.activeIndex, session.tabs.count - 1)

            let wsTab = WorkspaceTab(content: .browser(session))
            wsTab.roomID = roomID
            tabs.append(wsTab)
        }
    }

    // MARK: - Terminal Persistence

    func saveTerminalState(forRoom roomID: String) {
        let roomTerminalSessions = tabs
            .compactMap { tab -> TerminalSession? in
                guard tab.roomID == roomID else { return nil }
                return tab.terminalSession
            }
        TerminalStateStore.save(sessions: roomTerminalSessions, forRoom: roomID)
    }

    func saveAllTerminalState() {
        // Collect all unique room IDs from terminal tabs
        let roomIDs = Set(tabs.compactMap { tab -> String? in
            guard tab.terminalSession != nil else { return nil }
            return tab.roomID
        })
        for roomID in roomIDs {
            saveTerminalState(forRoom: roomID)
        }
    }

    func restoreTerminalState(forRoom roomID: String) {
        // Only restore if no terminal tabs exist for this room
        let existing = tabs.filter { $0.roomID == roomID && $0.terminalSession != nil }
        guard existing.isEmpty else { return }

        let states = TerminalStateStore.restore(forRoom: roomID)
        for state in states {
            // Only restore Claude/Gemini sessions (plain terminals aren't useful without scrollback)
            guard state.isClaude || state.isGemini else { continue }

            let dir = state.workingDirectoryPath.map { URL(fileURLWithPath: $0) }
            let emulator = TerminalEmulator()
            emulator.workingDirectory = dir

            let session = TerminalSession(
                emulator: emulator,
                projectName: state.projectName,
                workingDirectory: dir,
                bookmarkID: state.bookmarkID,
                isClaude: state.isClaude,
                isGemini: state.isGemini
            )
            session.intentID = state.intentID
            session.customTitle = state.customTitle
            session.claudeSessionID = state.claudeSessionID
            session.isRestored = true

            let wsTab = WorkspaceTab(content: .terminal(session))
            wsTab.roomID = roomID
            tabs.append(wsTab)
        }
    }
}
