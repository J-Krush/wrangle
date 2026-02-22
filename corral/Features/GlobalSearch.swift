import SwiftUI
import SwiftData

struct SearchResult: Identifiable {
    let id = UUID()
    let fileURL: URL
    let fileName: String
    let relativePath: String
    let lineNumber: Int
    let lineContent: String
    let matchRange: Range<String.Index>?
}

/// File type filter for narrowing global search results.
enum SearchFileFilter: String, CaseIterable {
    case all = "All"
    case markdown = ".md"
    case yaml = ".yaml"
    case json = ".json"

    nonisolated func matches(_ url: URL) -> Bool {
        switch self {
        case .all: return true
        case .markdown: return url.pathExtension.lowercased() == "md"
        case .yaml:
            let ext = url.pathExtension.lowercased()
            return ext == "yaml" || ext == "yml"
        case .json: return url.pathExtension.lowercased() == "json"
        }
    }

    /// Extensions that are searchable at all (text-based files).
    nonisolated static let searchableExtensions: Set<String> = [
        "md", "txt", "yaml", "yml", "json", "toml", "xml", "swift", "py", "js", "ts", "sh", "zsh",
        "bash", "fish", "env", "cfg", "ini", "conf", "log"
    ]
}

struct GlobalSearchView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @State private var searchText: String = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var selectedFilter: SearchFileFilter = .all
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        ZStack {
            // Dark overlay background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Search panel
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search across all projects...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            performSearch()
                        }
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
                .padding(12)

                // Filter buttons
                HStack(spacing: 8) {
                    ForEach(SearchFileFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                            performSearch()
                        } label: {
                            Text(filter.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == filter
                                              ? Color.accentColor.opacity(0.2)
                                              : Color.secondary.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    if !results.isEmpty {
                        Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

                Divider()

                // Results list
                if results.isEmpty && !searchText.isEmpty && !isSearching {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No results found")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty && searchText.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Text("Type to search across all bookmarked projects")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(results) { result in
                        resultRow(result)
                            .onTapGesture {
                                appState.openFile(url: result.fileURL)
                                dismiss()
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(width: 600)
            .frame(maxHeight: 500)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        }
        .onAppear {
            isSearchFieldFocused = true
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .onChange(of: searchText) {
            // Debounce: only search after the user pauses typing
            searchTask?.cancel()
            guard !searchText.isEmpty else {
                results = []
                return
            }
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                performSearch()
            }
        }
    }

    // MARK: - Result Row

    private func resultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: FileType.detect(from: result.fileURL).iconName)
                .foregroundStyle(FileType.detect(from: result.fileURL).iconColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(result.fileName)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(":\(result.lineNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(result.lineContent.trimmingCharacters(in: .whitespaces))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(result.relativePath)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    // MARK: - Search

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            results = []
            return
        }

        isSearching = true
        let currentFilter = selectedFilter
        let currentBookmarks = bookmarks

        // Capture resolved URLs on the main actor, then search in background
        var resolvedRoots: [(url: URL, rootPath: String)] = []
        for bookmark in currentBookmarks {
            if let url = bookmark.resolveURL() {
                _ = url.startAccessingSecurityScopedResource()
                resolvedRoots.append((url: url, rootPath: url.path))
            }
        }

        Task.detached {
            var found: [SearchResult] = []
            let fm = FileManager.default

            for root in resolvedRoots {
                searchDirectory(
                    at: root.url,
                    rootPath: root.rootPath,
                    query: query,
                    filter: currentFilter,
                    fileManager: fm,
                    into: &found
                )
            }

            // Cap results to prevent performance issues
            let capped = Array(found.prefix(200))

            await MainActor.run {
                self.results = capped
                self.isSearching = false
                for root in resolvedRoots {
                    root.url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }

    // MARK: - Helpers

    private func dismiss() {
        searchTask?.cancel()
        appState.showGlobalSearch = false
    }
}

// MARK: - File System Search (nonisolated)

/// Recursively searches directory contents for lines matching the query.
/// Runs on a background thread via Task.detached.
nonisolated private func searchDirectory(
    at url: URL,
    rootPath: String,
    query: String,
    filter: SearchFileFilter,
    fileManager fm: FileManager,
    into results: inout [SearchResult]
) {
    // Early exit if we already have plenty of results
    guard results.count < 200 else { return }

    guard let contents = try? fm.contentsOfDirectory(
        at: url,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
    ) else { return }

    for childURL in contents {
        let isDir = (try? childURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

        if isDir {
            // Skip common non-content directories
            let dirName = childURL.lastPathComponent
            if dirName == "node_modules" || dirName == ".git" || dirName == ".build" || dirName == "DerivedData" {
                continue
            }
            searchDirectory(at: childURL, rootPath: rootPath, query: query, filter: filter, fileManager: fm, into: &results)
        } else {
            let ext = childURL.pathExtension.lowercased()
            guard SearchFileFilter.searchableExtensions.contains(ext) else { continue }
            guard filter.matches(childURL) else { continue }

            // Read and search the file line by line
            guard let data = fm.contents(atPath: childURL.path),
                  let content = String(data: data, encoding: .utf8) else { continue }

            let lines = content.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                guard results.count < 200 else { return }
                if let range = line.range(of: query, options: .caseInsensitive) {
                    let relativePath = String(childURL.path.dropFirst(rootPath.count))
                    results.append(SearchResult(
                        fileURL: childURL,
                        fileName: childURL.lastPathComponent,
                        relativePath: relativePath,
                        lineNumber: index + 1,
                        lineContent: line,
                        matchRange: range
                    ))
                }
            }
        }
    }
}
