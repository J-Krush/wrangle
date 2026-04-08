import SwiftUI
import SwiftData

struct FileTreeContent: View {
    let bookmark: BookmarkedDirectory
    let filterText: String
    let activeFileTypeFilters: Set<FileTypeFilter>
    @Environment(AppState.self) private var appState
    @AppStorage("showHiddenFiles") private var showHiddenFiles: Bool = false
    @State private var nodes: [FileNode] = []
    @State private var watcher: FileWatcher?
    @State private var resolvedURL: URL?
    @State private var isLoading = false
    @State private var loadGeneration = 0
    @State private var loadTask: Task<Void, Never>?

    private var parentBookmarkID: String {
        bookmark.persistentModelID.hashValue.description
    }

    private var filteredNodes: [FileNode] {
        if filterText.isEmpty && activeFileTypeFilters.isEmpty { return nodes }
        return nodes.compactMap { $0.filtered(by: filterText, fileTypes: activeFileTypeFilters) }
    }

    var body: some View {
        Group {
            if isLoading && nodes.isEmpty {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            } else if filteredNodes.isEmpty {
                if !filterText.isEmpty || !activeFileTypeFilters.isEmpty {
                    Text("No matches")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    Text("Empty directory")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(filteredNodes) { node in
                    FileTreeNodeView(
                        node: node,
                        bookmarkID: parentBookmarkID,
                        onSelect: { url in
                            appState.openFileAsPreview(url: url, scopedURL: resolvedURL)
                        },
                        onDoubleClick: { url in
                            appState.openFile(url: url, scopedURL: resolvedURL)
                            // Promote in case it was already the preview tab
                            if let doc = appState.activeDocument {
                                appState.promotePreviewTab(for: doc.id)
                            }
                        }
                    )
                    .contextMenu {
                        contextMenu(for: node)
                    }
                }
            }
        }
        .onAppear { loadTree(refreshBookmark: true) }
        .onChange(of: bookmark.bookmarkData) { loadTree(refreshBookmark: false) }
        .onChange(of: showHiddenFiles) { loadTree(refreshBookmark: false) }
        .onDisappear {
            loadTask?.cancel()
            watcher?.stop()
            watcher = nil
            if let url = resolvedURL {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    // MARK: - Context Menus

    @ViewBuilder
    private func contextMenu(for node: FileNode) -> some View {
        if node.isDirectory {
            Button("Open Terminal Here") {
                appState.openTerminal(projectName: node.url.lastPathComponent, directory: node.url, bookmarkID: parentBookmarkID)
            }
            Button("Launch Claude Code Here") {
                appState.openTerminal(projectName: node.url.lastPathComponent, directory: node.url, bookmarkID: parentBookmarkID, launchClaude: true)
            }
            Button("Launch Gemini Code Here") {
                appState.openTerminal(projectName: node.url.lastPathComponent, directory: node.url, bookmarkID: parentBookmarkID, launchGemini: true)
            }
            OpenInSubmenu(url: node.url)
        } else {
            OpenInSubmenu(url: node.url)
        }
    }

    // MARK: - File Operations

    private func loadTree(refreshBookmark: Bool = true) {
        loadTask?.cancel()
        watcher?.stop()
        watcher = nil

        guard let url = bookmark.resolveURL(refreshIfStale: refreshBookmark) else {
            resolvedURL?.stopAccessingSecurityScopedResource()
            resolvedURL = nil
            nodes = []
            return
        }

        // Start security-scoped access so files within this directory can be read
        if resolvedURL != url {
            resolvedURL?.stopAccessingSecurityScopedResource()
            _ = url.startAccessingSecurityScopedResource()
        }
        resolvedURL = url
        loadGeneration += 1
        let currentGeneration = loadGeneration
        isLoading = true

        let showHidden = showHiddenFiles
        loadTask = Task {
            let tree = await Task.detached {
                FileNode.buildTree(at: url, showAllHidden: showHidden)
            }.value
            guard !Task.isCancelled, currentGeneration == loadGeneration else { return }
            nodes = tree
            isLoading = false
        }

        let newWatcher = FileWatcher(url: url) { [url] in
            loadGeneration += 1
            let gen = loadGeneration
            loadTask?.cancel()
            loadTask = Task {
                let tree = await Task.detached {
                    FileNode.buildTree(at: url, showAllHidden: showHidden)
                }.value
                guard !Task.isCancelled, gen == loadGeneration else { return }
                nodes = tree
            }
        }
        newWatcher.start()
        watcher = newWatcher
    }

}
