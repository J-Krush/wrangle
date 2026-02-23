import SwiftUI
import SwiftData

struct FileTreeContent: View {
    let bookmark: BookmarkedDirectory
    let filterText: String
    let activeFileTypeFilters: Set<FileTypeFilter>
    @Environment(AppState.self) private var appState
    @State private var nodes: [FileNode] = []
    @State private var watcher: FileWatcher?
    @State private var resolvedURL: URL?
    @State private var isLoading = false
    @State private var loadGeneration = 0
    @State private var loadTask: Task<Void, Never>?
    @State private var newFileName: String = ""
    @State private var showNewFileSheet = false
    @State private var showNewFolderSheet = false
    @State private var newFolderName: String = ""
    @State private var targetFolderURL: URL?

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
        .onDisappear {
            loadTask?.cancel()
            watcher?.stop()
            watcher = nil
            if let url = resolvedURL {
                url.stopAccessingSecurityScopedResource()
            }
        }
        .sheet(isPresented: $showNewFileSheet) { newFileSheet }
        .sheet(isPresented: $showNewFolderSheet) { newFolderSheet }
    }

    // MARK: - Context Menus

    @ViewBuilder
    private func contextMenu(for node: FileNode) -> some View {
        if node.isDirectory {
            Button("New File Here...") {
                targetFolderURL = node.url
                newFileName = ""
                showNewFileSheet = true
            }
            Button("New Folder Here...") {
                targetFolderURL = node.url
                newFolderName = ""
                showNewFolderSheet = true
            }
            Divider()
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: node.url.path)
            }
        } else {
            Button("Open") {
                appState.openFile(url: node.url, scopedURL: resolvedURL)
            }
            Divider()
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([node.url])
            }
            Divider()
            Button("Delete", role: .destructive) {
                deleteFile(at: node.url)
            }
        }
    }

    // MARK: - Sheets

    private var newFileSheet: some View {
        VStack(spacing: 16) {
            Text("New File")
                .font(.headline)
            TextField("File name", text: $newFileName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") {
                    showNewFileSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createNewFile()
                    showNewFileSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newFileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private var newFolderSheet: some View {
        VStack(spacing: 16) {
            Text("New Folder")
                .font(.headline)
            TextField("Folder name", text: $newFolderName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") {
                    showNewFolderSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createNewFolder()
                    showNewFolderSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
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

        loadTask = Task {
            let tree = await Task.detached {
                FileNode.buildTree(at: url)
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
                    FileNode.buildTree(at: url)
                }.value
                guard !Task.isCancelled, gen == loadGeneration else { return }
                nodes = tree
            }
        }
        newWatcher.start()
        watcher = newWatcher
    }

    private func createNewFile() {
        guard let folder = targetFolderURL else { return }
        var name = newFileName.trimmingCharacters(in: .whitespaces)
        if !name.contains(".") {
            name += ".md"
        }
        let fileURL = folder.appendingPathComponent(name)
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        loadTree()
        appState.openFile(url: fileURL, scopedURL: resolvedURL)
    }

    private func createNewFolder() {
        guard let folder = targetFolderURL else { return }
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        let folderURL = folder.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        loadTree()
    }

    private func deleteFile(at url: URL) {
        try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        loadTree()
    }
}
