import SwiftUI
import SwiftData

struct FileTreeContent: View {
    let bookmark: BookmarkedDirectory
    let filterText: String
    @Environment(AppState.self) private var appState
    @State private var nodes: [FileNode] = []
    @State private var watcher: FileWatcher?
    @State private var resolvedURL: URL?
    @State private var newFileName: String = ""
    @State private var showNewFileSheet = false
    @State private var showNewFolderSheet = false
    @State private var newFolderName: String = ""
    @State private var targetFolderURL: URL?

    private var filteredNodes: [FileNode] {
        if filterText.isEmpty { return nodes }
        return nodes.compactMap { $0.filtered(by: filterText) }
    }

    var body: some View {
        Group {
            if filteredNodes.isEmpty {
                if !filterText.isEmpty {
                    Text("No matches")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Empty directory")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(filteredNodes) { node in
                    FileTreeNodeView(node: node) { url in
                        appState.openFile(url: url)
                    }
                    .contextMenu {
                        contextMenu(for: node)
                    }
                }
            }
        }
        .onAppear { loadTree() }
        .onChange(of: bookmark.bookmarkData) { loadTree() }
        .onDisappear {
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
                appState.openFile(url: node.url)
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

    private func loadTree() {
        watcher?.stop()
        watcher = nil

        guard let url = bookmark.resolveURL() else {
            resolvedURL = nil
            nodes = []
            return
        }

        resolvedURL = url
        nodes = FileNode.buildTree(at: url)

        let newWatcher = FileWatcher(url: url) { [url] in
            nodes = FileNode.buildTree(at: url)
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
        appState.openFile(url: fileURL)
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
