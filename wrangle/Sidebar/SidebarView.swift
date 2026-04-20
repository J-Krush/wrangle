import SwiftUI
import AppKit
import SwiftData
import UniformTypeIdentifiers

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @Query(sort: \Project.displayOrder) private var projects: [Project]
    @State private var activeFileTypeFilters: Set<FileTypeFilter> = []
    @State private var showFilterPopover = false
    @State private var rawDropTargeted = false
    @State private var dropState: DropState = .idle
    @State private var dropDebounceTask: Task<Void, Never>?
    @State private var isSearchExpanded = false
    @FocusState private var isSearchFieldFocused: Bool
    @AppStorage("sidebar.locations.expanded") private var isLocationsExpanded: Bool = true
    @AppStorage("sidebar.scratchPads.expanded") private var isScratchPadsExpanded: Bool = true

    enum DropState {
        case idle
        case hovering
    }

    @State private var startWidth: CGFloat?

    var body: some View {
        @Bindable var appState = appState
        HStack(spacing: 0) {
            // Project rail — always visible
            ProjectRailView()

            // Content card — toggleable
            if appState.isSidebarVisible {
                VStack(spacing: 0) {
                    ScrollViewReader { scrollProxy in
                        List {
                            if let projectID = appState.selectedProjectID {
                                overviewRow(projectID: projectID)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 2, trailing: 4))
                                    .listRowBackground(
                                        Theme.sidebarSelectionBackground(isSelected: appState.activeTab?.projectOverviewID == projectID)
                                    )

                                BrowserSessionsSection()
                                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))

                                if !appState.scratchPadManager.scratchPads(forProject: projectID).isEmpty {
                                    Section {
                                        if isScratchPadsExpanded {
                                            ScratchPadSection()
                                        }
                                    } header: {
                                        SidebarSectionHeader(
                                            title: "Scratch Pads",
                                            isExpanded: $isScratchPadsExpanded
                                        )
                                    }
                                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                                }

                                BookmarkSidebarSection()
                                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))

                                Section {
                                    if isLocationsExpanded {
                                        ProjectBookmarkListView(
                                            projectID: projectID,
                                            scrollProxy: scrollProxy,
                                            filterText: appState.sidebarFilterText,
                                            activeFileTypeFilters: activeFileTypeFilters,
                                            isFinderDragActive: dropState == .hovering,
                                            showActiveSessionsOnly: appState.showActiveSessionsOnly,
                                            onAddLocation: addLocation
                                        )
                                    }
                                } header: {
                                    SidebarSectionHeader(
                                        title: "Locations",
                                        isExpanded: $isLocationsExpanded
                                    )
                                }
                                .id(projectID)
                                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))

                                OrphanedSessionsSection()
                                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                            } else {
                                Section {
                                    Text("Select a project to get started")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .environment(\.defaultMinListRowHeight, 20)
                    .environment(\.sidebarRowSize, .small)
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: .infinity)
                    sidebarBottomBar
                }
                .frame(maxHeight: .infinity)
                .frame(width: appState.sidebarWidth)
                .frame(minWidth: 140, maxWidth: 400)
                .background(Color(nsColor: Theme.sidebarBackground), in: RoundedRectangle(cornerRadius: 8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(4)
                .overlay(alignment: .trailing) {
                    // Resize handle
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 5)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering { NSCursor.resizeLeftRight.push() }
                            else { NSCursor.pop() }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    if startWidth == nil { startWidth = appState.sidebarWidth }
                                    appState.sidebarWidth = max(140, min(400, (startWidth ?? 200) + value.translation.width))
                                }
                                .onEnded { _ in startWidth = nil }
                        )
                }
                .overlay {
                    if dropState == .hovering {
                        dropOverlay
                            .transition(.opacity)
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: $rawDropTargeted) { providers in
                    handleFinderDrop(providers)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .clipped()
        .background(Color(nsColor: Theme.chromeBackground))
        .fixedSize(horizontal: true, vertical: false)
        .animation(.smooth(duration: 0.2), value: dropState == .hovering)
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

    // MARK: - Bottom Bar

    private var sidebarBottomBar: some View {
        @Bindable var appState = appState
        return VStack(spacing: 0) {
            Divider()

            if isSearchExpanded {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    TextField("Filter files", text: $appState.sidebarFilterText)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .focused($isSearchFieldFocused)
                    if !appState.sidebarFilterText.isEmpty {
                        Button {
                            appState.sidebarFilterText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear filter")
                    }
                    Button {
                        toggleSearch()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close search")
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 8)
                .padding(.top, 6)
            }

            HStack(spacing: 4) {
                UnifiedAddMenu()

                Spacer()

                if !isSearchExpanded {
                    toolbarButton(
                        icon: "magnifyingglass",
                        isActive: !appState.sidebarFilterText.isEmpty,
                        activeColor: .accentColor
                    ) {
                        toggleSearch()
                    }
                    .help("Search files")
                    .accessibilityLabel("Search files")
                }

                toolbarButton(
                    icon: activeFileTypeFilters.isEmpty
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill",
                    isActive: !activeFileTypeFilters.isEmpty,
                    activeColor: .accentColor
                ) {
                    showFilterPopover.toggle()
                }
                .popover(isPresented: $showFilterPopover, arrowEdge: .top) {
                    FileTypeFilterPopover(activeFilters: $activeFileTypeFilters)
                }
                .help("Filter by file type")
                .accessibilityLabel("Filter by file type")

                toolbarButton(
                    icon: appState.showActiveSessionsOnly ? "terminal.fill" : "terminal",
                    isActive: appState.showActiveSessionsOnly,
                    activeColor: .accentColor
                ) {
                    appState.showActiveSessionsOnly.toggle()
                }
                .help("Show Active Sessions")
                .accessibilityLabel("Show active sessions")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(nsColor: Theme.sidebarBackground))
        .animation(.snappy(duration: 0.2), value: isSearchExpanded)
    }

    private func toolbarButton(
        icon: String, isActive: Bool, activeColor: Color, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isActive ? activeColor : .secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    // MARK: - Overview Row

    private func overviewRow(projectID: String) -> some View {
        let isActive = appState.activeTab?.projectOverviewID == projectID
        return Button {
            if let index = appState.tabs.firstIndex(where: { $0.projectOverviewID == projectID }) {
                appState.selectTab(at: index)
            }
        } label: {
            Label {
                Text("Overview")
                    .lineLimit(1)
            } icon: {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func toggleSearch() {
        if isSearchExpanded {
            appState.sidebarFilterText = ""
            isSearchExpanded = false
        } else {
            isSearchExpanded = true
            Task {
                try? await Task.sleep(for: .milliseconds(50))
                isSearchFieldFocused = true
            }
        }
    }

    private func addLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
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
            // If drilled into a project, assign the new bookmark to it.
            // Otherwise create a new project for this bookmark.
            if let projectID = appState.selectedProjectID {
                bookmark.projectID = projectID
            } else {
                let maxProjectOrder = projects.map(\.displayOrder).max() ?? -1
                let project = Project(
                    name: url.lastPathComponent,
                    displayOrder: maxProjectOrder + 1
                )
                modelContext.insert(project)
                bookmark.projectID = project.id
            }
            modelContext.insert(bookmark)
            try? modelContext.save()

            let id = bookmark.persistentModelID.hashValue.description
            if isDir {
                appState.selectedBookmarkID = id
                // Auto-drill into the project if we just created one at the top level
                if appState.selectedProjectID == nil, let projectID = bookmark.projectID {
                    appState.selectedProjectID = projectID
                }
            } else {
                appState.openFile(url: url, scopedURL: url)
            }
        } catch {
            // Bookmark creation failed
        }
    }

    private func handleFinderDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                guard isDir else { return }

                Task { @MainActor in
                    // Deduplicate: skip if this directory is already bookmarked
                    let urlPath = url.path(percentEncoded: false)
                    for bookmark in bookmarks {
                        if let existingURL = bookmark.resolveURL(),
                           existingURL.path(percentEncoded: false) == urlPath {
                            return
                        }
                    }

                    do {
                        let bookmarkData = try SecurityScopedBookmark.create(for: url)
                        let maxOrder = bookmarks.map(\.displayOrder).max() ?? -1
                        let bookmark = BookmarkedDirectory(
                            name: url.lastPathComponent,
                            bookmarkData: bookmarkData,
                            displayOrder: maxOrder + 1,
                            isFile: false
                        )
                        if let projectID = appState.selectedProjectID {
                            bookmark.projectID = projectID
                        } else {
                            let maxProjectOrder = projects.map(\.displayOrder).max() ?? -1
                            let project = Project(name: url.lastPathComponent, displayOrder: maxProjectOrder + 1)
                            modelContext.insert(project)
                            bookmark.projectID = project.id
                        }
                        modelContext.insert(bookmark)
                        try? modelContext.save()
                        appState.selectedBookmarkID = bookmark.persistentModelID.hashValue.description
                        if appState.selectedProjectID == nil, let projectID = bookmark.projectID {
                            appState.selectedProjectID = projectID
                        }
                    } catch {
                        // Bookmark creation failed
                    }
                }
            }
        }
        return true
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

// MARK: - Spaces Section

private struct SpacesSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.viewMode = .dashboard
        } label: {
            Label("All Projects", systemImage: "square.grid.2x2")
        }
        .listRowBackground(
            Theme.sidebarSelectionBackground(isSelected: appState.viewMode == .dashboard)
        )

        Button {
            appState.viewMode = .canvas
        } label: {
            Label("Canvas", systemImage: "rectangle.3.group")
        }
        .listRowBackground(
            Theme.sidebarSelectionBackground(isSelected: appState.viewMode == .canvas)
        )
    }
}

// MARK: - Browser Sessions Section

private struct BrowserSessionsSection: View {
    @Environment(AppState.self) private var appState
    @AppStorage("sidebar.browsers.expanded") private var isExpanded: Bool = true

    var body: some View {
        let browsers = appState.projectBrowserSessions
        if !browsers.isEmpty {
            Section {
                if isExpanded {
                    ForEach(browsers) { session in
                        LocationBrowserRow(session: session)
                    }
                }
            } header: {
                SidebarSectionHeader(title: "Browsers", isExpanded: $isExpanded)
            }
        }
    }
}

// MARK: - Orphaned Sessions Section

private struct OrphanedSessionsSection: View {
    @Environment(AppState.self) private var appState
    @AppStorage("sidebar.otherSessions.expanded") private var isExpanded: Bool = true

    var body: some View {
        let orphaned = appState.orphanedTerminalSessions
        if !orphaned.isEmpty {
            Section {
                if isExpanded {
                    ForEach(orphaned) { session in
                        LocationSessionRow(session: session)
                    }
                }
            } header: {
                SidebarSectionHeader(title: "Other Sessions", isExpanded: $isExpanded)
            }
        }
    }
}
