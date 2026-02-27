import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum EditingMode: String, CaseIterable {
    case writing
    case dev
}

enum AppearanceMode: String, CaseIterable {
    case system, light, dark
}

@MainActor
@Observable
class AppState {
    var tabs: [WorkspaceTab]
    var activeTabIndex: Int
    var selectedBookmarkID: String?
    var showFuzzyFinder: Bool = false
    var showGlobalSearch: Bool = false
    var searchQuery: String = ""
    var sidebarWidth: CGFloat = 240
    var detailAreaLeading: CGFloat = 240
    var editingMode: EditingMode = .writing
    var appearanceMode: AppearanceMode = .system
    var selectedFileTreeURL: URL? = nil
    // Preview tab tracking — only one preview tab at a time
    var previewTabID: UUID? = nil

    // Terminal close confirmation state
    var pendingCloseTabIndex: Int?
    var showTerminalCloseConfirmation: Bool = false

    // Terminal session manager (retained for stopAll on quit)
    var terminalSessionManager = TerminalSessionManager()

    // App foreground state (tracked for notification suppression)
    var isAppForeground: Bool = true

    // Claude Code hook service for notifications
    var claudeHookService: ClaudeHookService?

    // Set by ContentView from the @Query bookmarks array
    var activeProjectName: String?

    // Cached resolved bookmark URLs for scoped-access fallback
    var resolvedBookmarkURLs: [(directoryPath: String, resolvedURL: URL)] = []

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
        tabs.compactMap(\.terminalSession).filter { $0.bookmarkID == bookmarkID }
    }

    /// Terminal sessions with no associated bookmark (opened via Browse, etc.)
    var orphanedTerminalSessions: [TerminalSession] {
        tabs.compactMap(\.terminalSession).filter { $0.bookmarkID == nil }
    }

    init() {
        let blank = EditorDocument()
        let tab = WorkspaceTab(content: .document(blank))
        self.tabs = [tab]
        self.activeTabIndex = 0
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
        // Check if this file is already open in a tab
        if let existingIndex = tabs.firstIndex(where: { $0.document?.fileURL == url }) {
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
        tabs.append(tab)
        activeTabIndex = tabs.count - 1

        loadDocumentAsync(for: document, from: url)
    }

    func openFileAsPreview(url: URL, scopedURL: URL? = nil) {
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
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
    }

    // MARK: - Tab Management

    func selectTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        activeTabIndex = index
        tabs[index].terminalSession?.needsAttention = false
    }

    func closeTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        let closedTab = tabs[index]

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
            // Always keep at least one tab open
            let blank = EditorDocument()
            let tab = WorkspaceTab(content: .document(blank))
            tabs.append(tab)
            activeTabIndex = 0
        } else if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        } else if activeTabIndex > index {
            activeTabIndex -= 1
        }
    }

    func closeAllTabs() {
        for tab in tabs {
            if let session = tab.terminalSession {
                session.stop()
            }
        }
        tabs.removeAll()
        previewTabID = nil
        let blank = EditorDocument()
        let tab = WorkspaceTab(content: .document(blank))
        tabs.append(tab)
        activeTabIndex = 0
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
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
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
}
