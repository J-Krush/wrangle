import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BookmarkListView: View {
    let filterText: String
    let activeFileTypeFilters: Set<FileTypeFilter>
    let isFinderDragActive: Bool
    let showActiveSessionsOnly: Bool
    var onAddLocation: (() -> Void)?
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]

    // H-2: Consolidated sheet state
    enum SheetState: Equatable {
        case none
        case renaming(BookmarkedDirectory, text: String)

        static func == (lhs: SheetState, rhs: SheetState) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none): return true
            case (.renaming(let a, _), .renaming(let b, _)):
                return a.persistentModelID == b.persistentModelID
            default: return false
            }
        }
    }

    @State private var activeSheet: SheetState = .none
    @State private var expandedBookmarks: Set<String> = []
    @State private var renameText: String = ""
    @State private var draggingBookmarkID: String?
    @State private var dropTargetBookmarkID: String?

    private var showRenameSheet: Binding<Bool> {
        Binding(
            get: { if case .renaming = activeSheet { return true }; return false },
            set: { if !$0 { activeSheet = .none } }
        )
    }

    private func shouldShowFileBookmark(_ bookmark: BookmarkedDirectory) -> Bool {
        guard !activeFileTypeFilters.isEmpty, let url = bookmark.resolveURL() else { return true }
        let ft = FileType.detect(from: url)
        return activeFileTypeFilters.contains(where: { $0.matchingFileTypes.contains(ft) })
    }

    var body: some View {
        ForEach(bookmarks) { bookmark in
            let bookmarkID = bookmark.persistentModelID.hashValue.description
            let isSelected = appState.selectedBookmarkID == bookmarkID && appState.selectedFileTreeURL == nil
            let sessions = appState.terminalSessions(for: bookmarkID)
            // Sessions-only mode: active sessions toggle ON with no file type filters
            let sessionsOnlyMode = showActiveSessionsOnly && activeFileTypeFilters.isEmpty

            if bookmark.isFile {
                if !sessionsOnlyMode && shouldShowFileBookmark(bookmark) {
                    let isFileSelected = appState.activeDocument?.fileURL == bookmark.resolveURL()
                    fileBookmarkRow(bookmark)
                        .listRowBackground(reorderBackground(isSelected: isFileSelected, bookmarkID: bookmarkID))
                        .onDrag {
                            draggingBookmarkID = bookmarkID
                            return NSItemProvider(object: bookmarkID as NSString)
                        }
                        .onDrop(of: [UTType.text], isTargeted: dropTargetBinding(for: bookmarkID)) { providers in
                            handleReorderDrop(providers: providers, targetID: bookmarkID)
                        }
                }
            } else if sessionsOnlyMode {
                // Sessions-only: show locations that have active sessions, sessions only
                if !sessions.isEmpty {
                    DisclosureGroup(isExpanded: expansionBinding(for: bookmarkID)) {
                        ForEach(sessions) { session in
                            LocationSessionRow(session: session)
                        }
                    } label: {
                        LocationHeaderLabel(
                            bookmark: bookmark,
                            sessions: sessions,
                            onToggle: { toggleExpansion(bookmarkID: bookmarkID) }
                        )
                    }
                    .listRowBackground(reorderBackground(isSelected: isSelected, bookmarkID: bookmarkID))
                    .help(bookmark.resolveURL()?.path(percentEncoded: false) ?? bookmark.name)
                    .contextMenu { bookmarkContextMenu(bookmark) }
                }
            } else {
                // Normal view: sessions + filtered file tree (handles both filters composing)
                DisclosureGroup(isExpanded: expansionBinding(for: bookmarkID)) {
                    ForEach(sessions) { session in
                        LocationSessionRow(session: session)
                    }
                    FileTreeContent(bookmark: bookmark, filterText: filterText, activeFileTypeFilters: activeFileTypeFilters)
                } label: {
                    LocationHeaderLabel(
                        bookmark: bookmark,
                        sessions: sessions,
                        onToggle: { toggleExpansion(bookmarkID: bookmarkID) }
                    )
                }
                .listRowBackground(reorderBackground(isSelected: isSelected, bookmarkID: bookmarkID))
                .help(bookmark.resolveURL()?.path(percentEncoded: false) ?? bookmark.name)
                .opacity(isFinderDragActive ? 0.3 : 1.0)
                .contextMenu { bookmarkContextMenu(bookmark) }
                .onDrag {
                    draggingBookmarkID = bookmarkID
                    expandedBookmarks.remove(bookmarkID)
                    return NSItemProvider(object: bookmarkID as NSString)
                }
                .onDrop(of: [UTType.text], isTargeted: dropTargetBinding(for: bookmarkID)) { providers in
                    handleReorderDrop(providers: providers, targetID: bookmarkID)
                }
            }
        }

        // Invisible drop target for end-of-list reorder
        Color.clear
            .frame(height: 20)
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .listRowBackground(reorderEndBackground())
            .listRowSeparator(.hidden)
            .onDrop(of: [UTType.text], isTargeted: dropTargetBinding(for: Self.endOfListID)) { providers in
                handleReorderDrop(providers: providers, targetID: Self.endOfListID)
            }

        Color.clear
            .frame(minHeight: 500)
            .frame(maxWidth: .infinity)
            .overlay {
                RightClickMenuArea(
                    onLeftClick: {
                        appState.selectedBookmarkID = nil
                        appState.selectedFileTreeURL = nil
                    },
                    onAddLocation: { onAddLocation?() }
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .sheet(isPresented: showRenameSheet) { renameSheet }
            .onChange(of: appState.activeTabIndex) { _, _ in
                guard let session = appState.activeTab?.terminalSession,
                      let bookmarkID = session.bookmarkID else { return }
                expandedBookmarks.insert(bookmarkID)
            }
            .onChange(of: showActiveSessionsOnly) { _, isActive in
                if isActive {
                    for bookmark in bookmarks where !bookmark.isFile {
                        let id = bookmark.persistentModelID.hashValue.description
                        if !appState.terminalSessions(for: id).isEmpty {
                            expandedBookmarks.insert(id)
                        }
                    }
                }
            }
            .onChange(of: appState.revealFileURL) { _, revealURL in
                guard let revealURL else { return }
                let filePath = revealURL.path(percentEncoded: false)
                for bookmark in bookmarks where !bookmark.isFile {
                    guard let resolvedURL = bookmark.resolveURL() else { continue }
                    let dirPath = resolvedURL.path(percentEncoded: false)
                    if filePath.hasPrefix(dirPath) {
                        let bookmarkID = bookmark.persistentModelID.hashValue.description
                        expandedBookmarks.insert(bookmarkID)
                        appState.selectedBookmarkID = bookmarkID
                        appState.selectedFileTreeURL = revealURL
                        break
                    }
                }
            }
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

    private func toggleExpansion(bookmarkID: String) {
        appState.selectedBookmarkID = bookmarkID
        appState.selectedFileTreeURL = nil
        if expandedBookmarks.contains(bookmarkID) {
            expandedBookmarks.remove(bookmarkID)
        } else {
            expandedBookmarks.insert(bookmarkID)
        }
    }

    // MARK: - Bookmark Rows

    private func fileBookmarkRow(_ bookmark: BookmarkedDirectory) -> some View {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        return Button {
            appState.selectedBookmarkID = bookmarkID
            if let url = bookmark.resolveURL() {
                // If already open as preview, promote to full tab
                if let existingIndex = appState.tabs.firstIndex(where: { $0.document?.fileURL == url }),
                   appState.previewTabID == appState.tabs[existingIndex].id {
                    appState.openFile(url: url, scopedURL: url)
                    if let doc = appState.activeDocument {
                        appState.promotePreviewTab(for: doc.id)
                    }
                } else {
                    appState.openFileAsPreview(url: url, scopedURL: url)
                }
            }
        } label: {
            Label {
                Text(bookmark.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } icon: {
                Image(systemName: "doc.fill")
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isFinderDragActive ? 0.3 : 1.0)
        .help(bookmark.resolveURL()?.path(percentEncoded: false) ?? bookmark.name)
        .contextMenu { bookmarkContextMenu(bookmark) }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func bookmarkContextMenu(_ bookmark: BookmarkedDirectory) -> some View {
        if !bookmark.isFile {
            Button("Open Terminal") {
                openTerminal(for: bookmark)
            }

            Button("Launch Claude Code") {
                launchClaude(for: bookmark)
            }

            Button("Launch Gemini Code") {
                launchGemini(for: bookmark)
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
            renameText = bookmark.name
            activeSheet = .renaming(bookmark, text: bookmark.name)
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

    private func launchGemini(for bookmark: BookmarkedDirectory) {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        let dir = bookmark.resolveURL()
        appState.openTerminal(
            projectName: bookmark.name,
            directory: dir,
            bookmarkID: bookmarkID,
            launchGemini: true
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
                    activeSheet = .none
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename") {
                    if case .renaming(let bookmark, _) = activeSheet {
                        bookmark.name = renameText
                    }
                    activeSheet = .none
                }
                .keyboardShortcut(.defaultAction)
                .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }

    // MARK: - Drag & Drop Reordering

    private static let endOfListID = "__end_of_list__"

    @ViewBuilder
    private func reorderBackground(isSelected: Bool, bookmarkID: String) -> some View {
        let isDropTarget = dropTargetBookmarkID == bookmarkID
            && draggingBookmarkID != nil
            && draggingBookmarkID != bookmarkID

        ZStack(alignment: .top) {
            Theme.sidebarSelectionBackground(isSelected: isSelected)
            if isDropTarget {
                Color.accentColor
                    .frame(height: 2)
            }
        }
    }

    @ViewBuilder
    private func reorderEndBackground() -> some View {
        let isDropTarget = dropTargetBookmarkID == Self.endOfListID && draggingBookmarkID != nil

        if isDropTarget {
            VStack { Color.accentColor.frame(height: 2); Spacer() }
        } else {
            Color.clear
        }
    }

    private func dropTargetBinding(for bookmarkID: String) -> Binding<Bool> {
        Binding(
            get: { dropTargetBookmarkID == bookmarkID },
            set: { isTargeted in
                if isTargeted {
                    dropTargetBookmarkID = bookmarkID
                } else if dropTargetBookmarkID == bookmarkID {
                    dropTargetBookmarkID = nil
                }
            }
        )
    }

    private func handleReorderDrop(providers: [NSItemProvider], targetID: String) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let sourceID = item as? String else { return }
            Task { @MainActor in
                reorderBookmark(sourceID: sourceID, beforeTargetID: targetID)
                draggingBookmarkID = nil
                dropTargetBookmarkID = nil
            }
        }
        return true
    }

    private func reorderBookmark(sourceID: String, beforeTargetID: String) {
        var ordered = Array(bookmarks)
        guard let sourceIndex = ordered.firstIndex(where: {
            $0.persistentModelID.hashValue.description == sourceID
        }) else { return }

        let source = ordered.remove(at: sourceIndex)

        if beforeTargetID == Self.endOfListID {
            ordered.append(source)
        } else if let targetIndex = ordered.firstIndex(where: {
            $0.persistentModelID.hashValue.description == beforeTargetID
        }) {
            ordered.insert(source, at: targetIndex)
        } else {
            ordered.append(source)
        }

        for (index, bookmark) in ordered.enumerated() {
            bookmark.displayOrder = index
        }
        try? modelContext.save()
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

}

// MARK: - Location Header Label

private struct LocationHeaderLabel: View {
    let bookmark: BookmarkedDirectory
    let sessions: [TerminalSession]
    let onToggle: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onToggle) {
                Label {
                    Text(bookmark.name)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } icon: {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !sessions.isEmpty {
                let hasAttention = sessions.contains { $0.needsAttention }
                Text("\(sessions.count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(hasAttention ? Color.green.opacity(0.25) : Color.secondary.opacity(0.15))
                    )
                    .foregroundStyle(hasAttention ? .green : .secondary)
            }

            SessionAddButton(bookmark: bookmark, hasActiveSessions: !sessions.isEmpty)
                .opacity(isHovering || !sessions.isEmpty ? 1 : 0)
                .allowsHitTesting(isHovering || !sessions.isEmpty)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .onHover { isHovering = $0 }
    }
}

// MARK: - Session Add Button

private struct SessionAddButton: View {
    let bookmark: BookmarkedDirectory
    let hasActiveSessions: Bool
    @Environment(AppState.self) private var appState

    var body: some View {
        Menu {
            Button("New Terminal") { openTerminal() }
            Button("New Claude Code Session") { launchClaude() }
            Button("New Gemini Code Session") { launchGemini() }
            Divider()
            Button {
                launchClaudeDangerous()
            } label: {
                Label {
                    Text("Claude (Skip Permissions)")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
            }
            .help("Runs claude --dangerously-skip-permissions. Use with caution — this bypasses all permission prompts.")
        } label: {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .contentShape(Rectangle())
        .tint(hasActiveSessions
            ? Color.purple
            : Color(red: 0.578, green: 0.578, blue: 0.578, opacity: 1.0))
        .menuIndicator(.hidden)
        .help("New Session")
    }

    private func openTerminal() {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        let dir = bookmark.resolveURL()
        appState.openTerminal(
            projectName: bookmark.name,
            directory: dir,
            bookmarkID: bookmarkID
        )
    }

    private func launchClaude() {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        let dir = bookmark.resolveURL()
        appState.openTerminal(
            projectName: bookmark.name,
            directory: dir,
            bookmarkID: bookmarkID,
            launchClaude: true
        )
    }

    private func launchGemini() {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        let dir = bookmark.resolveURL()
        appState.openTerminal(
            projectName: bookmark.name,
            directory: dir,
            bookmarkID: bookmarkID,
            launchGemini: true
        )
    }

    private func launchClaudeDangerous() {
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        let dir = bookmark.resolveURL()
        appState.openTerminal(
            projectName: bookmark.name,
            directory: dir,
            bookmarkID: bookmarkID,
            launchClaude: true,
            dangerousMode: true
        )
    }
}

// MARK: - Right-Click Menu (no highlight)

private struct RightClickMenuArea: NSViewRepresentable {
    var onLeftClick: () -> Void
    var onAddLocation: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ClickableView(coordinator: context.coordinator)
        let menu = NSMenu()
        let item = NSMenuItem(title: "Add Location...", action: #selector(Coordinator.addLocation), keyEquivalent: "")
        item.target = context.coordinator
        menu.addItem(item)
        view.menu = menu
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onLeftClick = onLeftClick
        context.coordinator.onAddLocation = onAddLocation
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLeftClick: onLeftClick, onAddLocation: onAddLocation)
    }

    class ClickableView: NSView {
        weak var coordinator: Coordinator?

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override func mouseDown(with event: NSEvent) {
            coordinator?.onLeftClick()
        }
    }

    class Coordinator: NSObject {
        var onLeftClick: () -> Void
        var onAddLocation: () -> Void

        init(onLeftClick: @escaping () -> Void, onAddLocation: @escaping () -> Void) {
            self.onLeftClick = onLeftClick
            self.onAddLocation = onAddLocation
        }

        @objc func addLocation() {
            onAddLocation()
        }
    }
}

#Preview{
    SessionAddButton(bookmark: BookmarkedDirectory(name: "Wrangle", bookmarkData: Data()), hasActiveSessions: false)
}
