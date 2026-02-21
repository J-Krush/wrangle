import SwiftUI
import SwiftData

struct BookmarkListView: View {
    let filterText: String
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]

    @State private var expandedBookmarks: Set<String> = []
    @State private var renamingBookmark: BookmarkedDirectory?
    @State private var renameText: String = ""
    @State private var showRenameSheet = false
    @State private var showColorPicker = false
    @State private var colorPickerBookmark: BookmarkedDirectory?
    @State private var selectedColor: Color = .blue

    private let availableColors: [(String, Color)] = [
        ("#007AFF", .blue),
        ("#FF3B30", .red),
        ("#FF9500", .orange),
        ("#FFCC00", .yellow),
        ("#34C759", .green),
        ("#AF52DE", .purple),
        ("#FF2D55", .pink),
        ("#8E8E93", .gray),
    ]

    var body: some View {
        ForEach(bookmarks) { bookmark in
            bookmarkRow(bookmark)
        }
        .onMove(perform: reorderBookmarks)

        addBookmarkButton
            .sheet(isPresented: $showRenameSheet) {
                renameSheet
            }
            .sheet(isPresented: $showColorPicker) {
                colorPickerSheet
            }
    }

    // MARK: - Bookmark Row

    @ViewBuilder
    private func bookmarkRow(_ bookmark: BookmarkedDirectory) -> some View {
        if bookmark.isFile {
            fileBookmarkRow(bookmark)
        } else {
            directoryBookmarkRow(bookmark)
        }
    }

    private func directoryBookmarkRow(_ bookmark: BookmarkedDirectory) -> some View {
        let bookmarkID = bookmark.persistentModelID.hashValue.description

        return DisclosureGroup(
            isExpanded: Binding(
                get: { expandedBookmarks.contains(bookmarkID) },
                set: { isExpanded in
                    if isExpanded {
                        expandedBookmarks.insert(bookmarkID)
                        appState.selectedBookmarkID = bookmarkID
                    } else {
                        expandedBookmarks.remove(bookmarkID)
                    }
                }
            )
        ) {
            FileTreeContent(bookmark: bookmark, filterText: filterText)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(colorFromHex(bookmark.iconColorHex))
                Text(bookmark.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .contextMenu {
            bookmarkContextMenu(bookmark)
        }
    }

    private func fileBookmarkRow(_ bookmark: BookmarkedDirectory) -> some View {
        Button {
            if let url = bookmark.resolveURL() {
                appState.openFile(url: url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .foregroundStyle(colorFromHex(bookmark.iconColorHex))
                Text(bookmark.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            bookmarkContextMenu(bookmark)
        }
    }

    @ViewBuilder
    private func bookmarkContextMenu(_ bookmark: BookmarkedDirectory) -> some View {
        Button("Rename...") {
            renamingBookmark = bookmark
            renameText = bookmark.name
            showRenameSheet = true
        }
        if !bookmark.isFile {
            Button("Change Color...") {
                colorPickerBookmark = bookmark
                selectedColor = colorFromHex(bookmark.iconColorHex)
                showColorPicker = true
            }
        }
        Divider()
        Button("Remove", role: .destructive) {
            removeBookmark(bookmark)
        }
    }

    // MARK: - Add Bookmark

    private var addBookmarkButton: some View {
        Button {
            addBookmark()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                Text("Add Bookmark")
            }
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rename Sheet

    private var renameSheet: some View {
        VStack(spacing: 16) {
            Text("Rename Bookmark")
                .font(.headline)
            TextField("Name", text: $renameText)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") {
                    showRenameSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename") {
                    renamingBookmark?.name = renameText
                    showRenameSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }

    // MARK: - Color Picker Sheet

    private var colorPickerSheet: some View {
        VStack(spacing: 16) {
            Text("Choose Color")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 4), spacing: 12) {
                ForEach(availableColors, id: \.0) { hex, color in
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: colorPickerBookmark?.iconColorHex == hex ? 2 : 0)
                        )
                        .onTapGesture {
                            colorPickerBookmark?.iconColorHex = hex
                            showColorPicker = false
                        }
                }
            }
            Button("Cancel") {
                showColorPicker = false
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(width: 220)
    }

    // MARK: - Actions

    private func addBookmark() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a file or directory to bookmark"

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
                expandedBookmarks.insert(id)
                appState.selectedBookmarkID = id
            } else {
                appState.openFile(url: url)
            }
        } catch {
            // Bookmark creation failed
        }
    }

    private func removeBookmark(_ bookmark: BookmarkedDirectory) {
        let id = bookmark.persistentModelID.hashValue.description
        if appState.selectedBookmarkID == id {
            appState.selectedBookmarkID = nil
        }
        expandedBookmarks.remove(id)
        modelContext.delete(bookmark)
        try? modelContext.save()
    }

    private func reorderBookmarks(from source: IndexSet, to destination: Int) {
        var ordered = bookmarks
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, bookmark) in ordered.enumerated() {
            bookmark.displayOrder = index
        }
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func colorFromHex(_ hex: String) -> Color {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        guard hexString.count == 6,
              let value = UInt64(hexString, radix: 16) else {
            return .blue
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}
