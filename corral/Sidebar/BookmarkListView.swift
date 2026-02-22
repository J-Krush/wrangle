import SwiftUI
import SwiftData

struct BookmarkListView: View {
    let filterText: String
    let isFinderDragActive: Bool
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
    @State private var draggingBookmarkID: String?
    @State private var lastFileBookmarkClickTime: Date = .distantPast
    @State private var lastFileBookmarkClickID: String?

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
            let bookmarkID = bookmark.persistentModelID.hashValue.description
            let isSelected = appState.selectedBookmarkID == bookmarkID

            if bookmark.isFile {
                fileBookmarkRow(bookmark)
                    .listRowBackground(Theme.sidebarSelectionBackground(isSelected: isSelected))
                    .draggable(bookmarkID) { dragPreview(bookmark: bookmark) }
                    .dropDestination(for: String.self) { droppedIDs, _ in
                        guard let sourceID = droppedIDs.first else { return false }
                        reorderBookmark(sourceID: sourceID, beforeTargetID: bookmarkID)
                        draggingBookmarkID = nil
                        return true
                    }
            } else {
                DisclosureGroup(isExpanded: expansionBinding(for: bookmarkID)) {
                    FileTreeContent(bookmark: bookmark, filterText: filterText)
                } label: {
                    Label {
                        Text(bookmark.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } icon: {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(colorFromHex(bookmark.iconColorHex))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let binding = expansionBinding(for: bookmarkID)
                        binding.wrappedValue.toggle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .listRowBackground(Theme.sidebarSelectionBackground(isSelected: isSelected))
                .help(bookmark.resolveURL()?.path(percentEncoded: false) ?? bookmark.name)
                .opacity(isFinderDragActive ? 0.3 : 1.0)
                .draggable(bookmarkID) { dragPreview(bookmark: bookmark) }
                .dropDestination(for: String.self) { droppedIDs, _ in
                    guard let sourceID = droppedIDs.first else { return false }
                    reorderBookmark(sourceID: sourceID, beforeTargetID: bookmarkID)
                    draggingBookmarkID = nil
                    return true
                }
                .contextMenu { bookmarkContextMenu(bookmark) }
            }
        }
        .sheet(isPresented: $showRenameSheet) { renameSheet }
        .sheet(isPresented: $showColorPicker) { colorPickerSheet }
    }

    // MARK: - Bindings

    private func expansionBinding(for bookmarkID: String) -> Binding<Bool> {
        Binding(
            get: { expandedBookmarks.contains(bookmarkID) },
            set: { newValue in
                if newValue {
                    expandedBookmarks.insert(bookmarkID)
                    appState.selectedBookmarkID = bookmarkID
                    appState.selectedFileTreeURL = nil
                } else {
                    expandedBookmarks.remove(bookmarkID)
                }
            }
        )
    }

    // MARK: - Drag Preview

    private func dragPreview(bookmark: BookmarkedDirectory) -> some View {
        HStack(spacing: 8) {
            Image(systemName: bookmark.isFile ? "doc.fill" : "folder.fill")
            Text(bookmark.name)
        }
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            draggingBookmarkID = bookmark.persistentModelID.hashValue.description
            expandedBookmarks.removeAll()
        }
    }

    // MARK: - Bookmark Rows

    private func fileBookmarkRow(_ bookmark: BookmarkedDirectory) -> some View {
        Button {
            handleFileBookmarkClick(bookmark)
        } label: {
            Label {
                Text(bookmark.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } icon: {
                Image(systemName: "doc.fill")
                    .foregroundStyle(colorFromHex(bookmark.iconColorHex))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isFinderDragActive ? 0.3 : 1.0)
        .help(bookmark.resolveURL()?.path(percentEncoded: false) ?? bookmark.name)
        .contextMenu { bookmarkContextMenu(bookmark) }
    }

    private func handleFileBookmarkClick(_ bookmark: BookmarkedDirectory) {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        let now = Date()
        let isDoubleClick = lastFileBookmarkClickID == bookmarkID
            && now.timeIntervalSince(lastFileBookmarkClickTime) < 0.3

        appState.selectedBookmarkID = bookmarkID

        if isDoubleClick {
            if let url = bookmark.resolveURL() {
                appState.openFile(url: url, scopedURL: url)
                if let doc = appState.activeDocument {
                    appState.promotePreviewTab(for: doc.id)
                }
            }
        } else {
            if let url = bookmark.resolveURL() {
                appState.openFileAsPreview(url: url, scopedURL: url)
            }
        }

        lastFileBookmarkClickTime = now
        lastFileBookmarkClickID = bookmarkID
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func bookmarkContextMenu(_ bookmark: BookmarkedDirectory) -> some View {
        if !bookmark.isFile {
            Button("Open Terminal") {
                openTerminal(for: bookmark)
            }

            if ClaudeCodeLauncher.isInstalled() {
                Button("Launch Claude Code") {
                    launchClaude(for: bookmark)
                }
            }

            let editors = ExternalEditorLauncher.availableEditors()
            if !editors.isEmpty {
                Menu("Open in...") {
                    ForEach(editors, id: \.bundleID) { editor in
                        Button(editor.name) {
                            if let url = bookmark.resolveURL() {
                                ExternalEditorLauncher.open(directory: url, withBundleID: editor.bundleID)
                            }
                        }
                    }
                    Divider()
                    Button("Finder") {
                        if let url = bookmark.resolveURL() {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                        }
                    }
                }
            }

            Divider()
        }

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

    private func openTerminal(for bookmark: BookmarkedDirectory) {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        let dir = bookmark.resolveURL()
        appState.openTerminal(
            projectName: bookmark.name,
            directory: dir,
            bookmarkID: bookmarkID,
            launchClaude: false
        )
    }

    private func launchClaude(for bookmark: BookmarkedDirectory) {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        let dir = bookmark.resolveURL()
        appState.openTerminal(
            projectName: bookmark.name,
            directory: dir,
            bookmarkID: bookmarkID,
            launchClaude: true
        )
    }

    // MARK: - Rename Sheet

    private var renameSheet: some View {
        VStack(spacing: 16) {
            Text("Rename Location")
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

    private func removeBookmark(_ bookmark: BookmarkedDirectory) {
        let id = bookmark.persistentModelID.hashValue.description
        if appState.selectedBookmarkID == id {
            appState.selectedBookmarkID = nil
        }
        expandedBookmarks.remove(id)
        modelContext.delete(bookmark)
        try? modelContext.save()
    }

    private func reorderBookmark(sourceID: String, beforeTargetID: String) {
        guard sourceID != beforeTargetID else { return }
        var ordered = bookmarks
        guard let sourceIndex = ordered.firstIndex(where: { $0.persistentModelID.hashValue.description == sourceID }),
              let targetIndex = ordered.firstIndex(where: { $0.persistentModelID.hashValue.description == beforeTargetID }) else {
            return
        }
        let item = ordered.remove(at: sourceIndex)
        let insertIndex = sourceIndex < targetIndex ? targetIndex : targetIndex
        ordered.insert(item, at: insertIndex)
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
