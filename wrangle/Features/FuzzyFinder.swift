import SwiftUI
import SwiftData

struct FuzzyFinderView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @State private var searchText: String = ""
    @State private var allFiles: [IndexedFile] = []
    @State private var selectedIndex: Int = 0
    @State private var indexTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool

    /// Lightweight model for an indexed file used only within the fuzzy finder.
    struct IndexedFile: Identifiable {
        let id = UUID()
        let url: URL
        let name: String
        let relativePath: String
        let isMarkdown: Bool
    }

    /// Filtered and ranked results based on the current search text.
    private var results: [IndexedFile] {
        guard !searchText.isEmpty else {
            return Array(allFiles.prefix(50))
        }
        let query = searchText.lowercased()

        // Score each file and keep only matches
        var scored: [(file: IndexedFile, score: Int)] = []
        for file in allFiles {
            let nameLower = file.name.lowercased()
            let pathLower = file.relativePath.lowercased()

            if nameLower == query {
                // Exact match on name
                scored.append((file, 100 + (file.isMarkdown ? 10 : 0)))
            } else if nameLower.hasPrefix(query) {
                // Prefix match on name
                scored.append((file, 80 + (file.isMarkdown ? 10 : 0)))
            } else if nameLower.contains(query) {
                // Substring match on name
                scored.append((file, 60 + (file.isMarkdown ? 10 : 0)))
            } else if pathLower.contains(query) {
                // Substring match on path
                scored.append((file, 40 + (file.isMarkdown ? 10 : 0)))
            } else if fuzzyMatch(query: query, target: nameLower) {
                // Fuzzy character-sequence match on name
                scored.append((file, 20 + (file.isMarkdown ? 10 : 0)))
            } else if fuzzyMatch(query: query, target: pathLower) {
                // Fuzzy match on path
                scored.append((file, 10 + (file.isMarkdown ? 10 : 0)))
            }
        }

        scored.sort { $0.score > $1.score }
        return Array(scored.map(\.file).prefix(50))
    }

    var body: some View {
        ZStack {
            // Dark overlay background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Finder panel
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search files...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            openSelectedResult()
                        }
                }
                .padding(12)

                Divider()

                // Results list
                if results.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Text("No files found")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { scrollProxy in
                        List(Array(results.enumerated()), id: \.element.id) { index, file in
                            Button {
                                appState.openFile(url: file.url)
                                dismiss()
                            } label: {
                                resultRow(file: file, isSelected: index == selectedIndex)
                            }
                            .buttonStyle(.plain)
                            .id(file.id)
                        }
                        .listStyle(.plain)
                        .onChange(of: selectedIndex) { _, newIndex in
                            if newIndex < results.count {
                                scrollProxy.scrollTo(results[newIndex].id)
                            }
                        }
                    }
                }
            }
            .frame(width: 500)
            .frame(maxHeight: 400)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        }
        .onAppear {
            indexAllFiles()
            isSearchFieldFocused = true
        }
        .onDisappear {
            indexTask?.cancel()
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < results.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onChange(of: searchText) {
            selectedIndex = 0
        }
    }

    // MARK: - Result Row

    private func resultRow(file: IndexedFile, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: FileType.detect(from: file.url).iconName)
                .foregroundStyle(FileType.detect(from: file.url).iconColor)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.body)
                    .lineLimit(1)
                Text(file.relativePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .listRowBackground(
            isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.clear
        )
    }

    // MARK: - Indexing

    private func indexAllFiles() {
        indexTask?.cancel()
        let currentBookmarks = bookmarks
        indexTask = Task {
            // Resolve bookmark URLs on the main actor
            var roots: [(url: URL, rootPath: String)] = []
            for bookmark in currentBookmarks {
                guard let rootURL = bookmark.resolveURL() else { continue }
                _ = rootURL.startAccessingSecurityScopedResource()
                roots.append((url: rootURL, rootPath: rootURL.path))
            }

            // Walk directories in background
            let files = await Task.detached {
                var files: [IndexedFile] = []
                for root in roots {
                    Self.walkDirectory(at: root.url, rootPath: root.rootPath, into: &files)
                }
                return files
            }.value

            // Stop security-scoped access (always, even if cancelled)
            for root in roots {
                root.url.stopAccessingSecurityScopedResource()
            }

            guard !Task.isCancelled else { return }
            allFiles = files
        }
    }

    private nonisolated static func walkDirectory(at url: URL, rootPath: String, into files: inout [IndexedFile]) {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for childURL in contents {
            let isDir = (try? childURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                walkDirectory(at: childURL, rootPath: rootPath, into: &files)
            } else {
                let name = childURL.lastPathComponent
                let relative = String(childURL.path.dropFirst(rootPath.count))
                let isMarkdown = childURL.pathExtension.lowercased() == "md"
                files.append(IndexedFile(
                    url: childURL,
                    name: name,
                    relativePath: relative,
                    isMarkdown: isMarkdown
                ))
            }
        }
    }

    // MARK: - Helpers

    private func dismiss() {
        appState.showFuzzyFinder = false
    }

    private func openSelectedResult() {
        guard selectedIndex < results.count else { return }
        appState.openFile(url: results[selectedIndex].url)
        dismiss()
    }

    /// Returns true if every character in `query` appears in `target` in order.
    private func fuzzyMatch(query: String, target: String) -> Bool {
        var targetIndex = target.startIndex
        for char in query {
            guard let found = target[targetIndex...].firstIndex(of: char) else {
                return false
            }
            targetIndex = target.index(after: found)
        }
        return true
    }
}
