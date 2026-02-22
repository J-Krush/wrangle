import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @State private var filterText: String = ""
    @State private var rawDropTargeted = false
    @State private var isDropTargeted = false
    @State private var hideOverlayTask: Task<Void, Never>?

    var body: some View {
        List {
            ActiveTerminalsView()

            Section {
                BookmarkListView(filterText: filterText, isFinderDragActive: isDropTargeted)
            } header: {
                HStack {
                    Text("Locations")
                    Spacer()
                    Button {
                        appState.newDocument()
                    } label: {
                        Image(systemName: "doc.badge.plus")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("New File (Cmd+N)")

                    RecentFilesButton()

                    Button {
                        addLocation()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Add Location")
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $filterText, placement: .sidebar, prompt: "Filter files")
        .frame(minWidth: 200, idealWidth: 240)
        .overlay {
            if isDropTargeted {
                dropOverlay
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.2), value: isDropTargeted)
        .onDrop(of: [.fileURL], isTargeted: $rawDropTargeted) { providers in
            handleFinderDrop(providers)
        }
        .onChange(of: rawDropTargeted) { _, newValue in
            hideOverlayTask?.cancel()
            if newValue {
                isDropTargeted = true
            } else {
                hideOverlayTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    guard !Task.isCancelled else { return }
                    if !rawDropTargeted {
                        isDropTargeted = false
                    }
                }
            }
        }
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

                DispatchQueue.main.async {
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
