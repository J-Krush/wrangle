import SwiftUI
import AppKit
import SwiftData
import UniformTypeIdentifiers

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @State private var filterText: String = ""
    @State private var activeFileTypeFilters: Set<FileTypeFilter> = []
    @State private var showFilterPopover = false
    @State private var rawDropTargeted = false
    @State private var dropState: DropState = .idle
    @State private var dropDebounceTask: Task<Void, Never>?

    enum DropState {
        case idle
        case hovering
    }

    var body: some View {
        List {
            ActiveTerminalsView()

            Section {
                BookmarkListView(filterText: filterText, activeFileTypeFilters: activeFileTypeFilters, isFinderDragActive: dropState == .hovering)
            } header: {
                HStack {
                    Text("Locations")
                    Spacer()
                    Button {
                        addLocation()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Add Location")
                }
                .padding(.trailing, 4)
            }
        }
        .onTapGesture {
            appState.selectedBookmarkID = nil
            appState.selectedFileTreeURL = nil
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top, spacing: 0) {
            sidebarSearchBar
        }
        .frame(minWidth: 200, idealWidth: 240)
        .overlay {
            if dropState == .hovering {
                dropOverlay
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.2), value: dropState == .hovering)
        .onDrop(of: [.fileURL], isTargeted: $rawDropTargeted) { providers in
            handleFinderDrop(providers)
        }
        .onChange(of: rawDropTargeted) { _, newValue in
            dropDebounceTask?.cancel()
            if newValue {
                dropState = .hovering
            } else {
                dropDebounceTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    guard !Task.isCancelled else { return }
                    if !rawDropTargeted {
                        dropState = .idle
                    }
                }
            }
        }
    }

    // MARK: - Search Bar

    private var sidebarSearchBar: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Filter files", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button {
                showFilterPopover.toggle()
            } label: {
                Image(systemName: activeFileTypeFilters.isEmpty
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
                    .foregroundStyle(activeFileTypeFilters.isEmpty ? Color.secondary : Color.accentColor)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showFilterPopover, arrowEdge: .bottom) {
                FileTypeFilterPopover(activeFilters: $activeFileTypeFilters)
            }
            .help("Filter by file type")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Drop Overlay

    private var dropOverlay: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.tint)
            Text("Drop to Add Location")
                .font(.headline)
            Text("Drag a folder here to add it as a location")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundStyle(.tint.opacity(0.5))
                .padding(8)
        )
        .allowsHitTesting(false)
    }

    // MARK: - Actions

    private func addLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a file or directory to add as a location"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

        do {
            let data = try SecurityScopedBookmark.create(for: url)
            let maxOrder = bookmarks.map(\.displayOrder).max() ?? -1
            let bookmark = BookmarkedDirectory(
                name: url.lastPathComponent,
                bookmarkData: data,
                displayOrder: maxOrder + 1,
                isFile: !isDir
            )
            modelContext.insert(bookmark)
            try? modelContext.save()

            let id = bookmark.persistentModelID.hashValue.description
            if isDir {
                appState.selectedBookmarkID = id
            } else {
                appState.openFile(url: url, scopedURL: url)
            }
        } catch {
            // Bookmark creation failed
        }
    }

    private func handleFinderDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                guard isDir else { return }

                // Deduplicate: skip if this directory is already bookmarked
                let urlPath = url.path(percentEncoded: false)
                for bookmark in bookmarks {
                    if let existingURL = bookmark.resolveURL(),
                       existingURL.path(percentEncoded: false) == urlPath {
                        return
                    }
                }

                Task { @MainActor in
                    do {
                        let bookmarkData = try SecurityScopedBookmark.create(for: url)
                        let maxOrder = bookmarks.map(\.displayOrder).max() ?? -1
                        let bookmark = BookmarkedDirectory(
                            name: url.lastPathComponent,
                            bookmarkData: bookmarkData,
                            displayOrder: maxOrder + 1,
                            isFile: false
                        )
                        modelContext.insert(bookmark)
                        try? modelContext.save()
                        appState.selectedBookmarkID = bookmark.persistentModelID.hashValue.description
                        handled = true
                    } catch {
                        // Bookmark creation failed
                    }
                }
            }
        }
        return handled
    }
}

// MARK: - File Type Filter Popover

struct FileTypeFilterPopover: View {
    @Binding var activeFilters: Set<FileTypeFilter>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("File Types")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if !activeFilters.isEmpty {
                    Button("Clear") {
                        activeFilters.removeAll()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ForEach(FileTypeFilter.allCases) { filter in
                Button {
                    if activeFilters.contains(filter) {
                        activeFilters.remove(filter)
                    } else {
                        activeFilters.insert(filter)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: filter.iconName)
                            .foregroundStyle(filter.iconColor)
                            .frame(width: 16)
                        Text(filter.displayName)
                            .font(.caption)
                        Spacer()
                        if activeFilters.contains(filter) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(activeFilters.contains(filter) ? Color.accentColor.opacity(0.1) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 6)
        .frame(width: 180)
    }
}
