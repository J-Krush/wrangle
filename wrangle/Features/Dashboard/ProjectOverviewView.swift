//
//  ProjectOverviewView.swift
//  Wrangle
//

import SwiftUI
import SwiftData

/// Per-project overview tab showing active sessions, open tabs, and project info.
struct ProjectOverviewView: View {
    let projectID: String
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @Query(sort: \Project.displayOrder) private var projects: [Project]
    @Query(sort: \BrowserBookmark.dateAdded, order: .reverse) private var browserBookmarks: [BrowserBookmark]

    @Query private var incompleteTodos: [TodoItem]
    @Query private var completedTodos: [TodoItem]
    @State private var showTerminalPicker = false
    @State private var activeLocationMenuID: String?
    @State private var pendingLaunchClaude = false
    @State private var pendingLaunchGemini = false
    @State private var pendingDangerousMode = false
    @State private var newTodoTitle = ""
    @State private var showCompleted = false
    @FocusState private var isAddTodoFocused: Bool
    @State private var locationBranches: [String: (branch: String?, changes: Int?)] = [:]
    @State private var gitRefreshTask: Task<Void, Never>?

    init(projectID: String) {
        self.projectID = projectID
        _incompleteTodos = Query(
            filter: #Predicate<TodoItem> { todo in
                todo.projectID == projectID && !todo.isCompleted
            },
            sort: \TodoItem.displayOrder
        )
        _completedTodos = Query(
            filter: #Predicate<TodoItem> { todo in
                todo.projectID == projectID && todo.isCompleted
            },
            sort: \TodoItem.dateCompleted,
            order: .reverse
        )
    }

    private var project: Project? {
        projects.first { $0.id == projectID }
    }

    private var projectBookmarks: [BookmarkedDirectory] {
        bookmarks.filter { $0.projectID == projectID && !$0.isFile }
    }

    private var projectTabs: [WorkspaceTab] {
        appState.tabs.filter { $0.projectID == projectID && !$0.isProjectOverview }
    }

    private var terminalSessions: [WorkspaceTab] {
        projectTabs.filter(\.isTerminal)
    }

    private var browserTabs: [WorkspaceTab] {
        projectTabs.filter(\.isBrowser)
    }

    private var documentTabs: [WorkspaceTab] {
        projectTabs.filter { $0.document != nil }
    }

    private var projectBrowserBookmarks: [BrowserBookmark] {
        browserBookmarks.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    // D-12: trigger condition for the empty-hero. Todos are NOT factored in —
    // Todos always renders at top (primary capture surface); the hero sits below it.
    private var isProjectContentEmpty: Bool {
        terminalSessions.isEmpty
            && browserTabs.isEmpty
            && documentTabs.isEmpty
            && projectBrowserBookmarks.isEmpty
            && projectBookmarks.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                todosSection
                // UIX-14 / D-12/D-13/D-14: single overview-level empty hero when every non-Todos source is empty.
                if isProjectContentEmpty {
                    emptyHero
                }
                if !terminalSessions.isEmpty { sessionsSection }
                // UIX-11-overview / D-20: Browsers card renders when tabs OR bookmarks present.
                if !browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty { browsersSection }
                if !documentTabs.isEmpty { documentsSection }
                // UIX-12-overview / D-15 body-level: Locations card renders only when ≥1 location.
                if !projectBookmarks.isEmpty { locationsSection }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: Theme.chromeBackground))
        .onTapGesture {
            isAddTodoFocused = false
        }
        .onAppear { startGitPolling() }
        .onDisappear { gitRefreshTask?.cancel() }
        .popover(isPresented: $showTerminalPicker, arrowEdge: .bottom) {
            TerminalDirectoryPicker(
                launchClaude: pendingLaunchClaude,
                launchGemini: pendingLaunchGemini,
                projectID: projectID
            ) { name, url, bookmarkID in
                appState.openTerminal(
                    projectName: name,
                    directory: url,
                    bookmarkID: bookmarkID,
                    launchClaude: pendingLaunchClaude,
                    launchGemini: pendingLaunchGemini,
                    dangerousMode: pendingDangerousMode
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Text(project?.name ?? "Project")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                newButton
            }

            // Stats
            HStack(spacing: 16) {
                statBadge(count: terminalSessions.count, label: "terminals", icon: "terminal", color: .mint)
                statBadge(count: browserTabs.count, label: browserTabs.count == 1 ? "browser" : "browsers", icon: "globe", color: .blue)
                statBadge(count: projectBrowserBookmarks.count, label: "bookmarks", icon: "star.fill", color: .yellow)
                statBadge(count: projectBookmarks.count, label: "locations", icon: "folder.fill", color: .gray)
                if !(incompleteTodos.isEmpty && completedTodos.isEmpty) {
                    todoStatBadge
                }
            }
        }
    }

    private var newButton: some View {
        // Shared creation menu — identical content across sidebar, overview, and tab strip.
        // Replaces the blue `New` pill (D-05 / D-12); visual treatment matches sidebar `+`.
        UnifiedAddMenu()
    }

    private func popoverButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 12))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func statBadge(count: Int, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var todoStatBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(completedTodos.count)/\(incompleteTodos.count + completedTodos.count)")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("todos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Todos

    private var todosSection: some View {
        // D-B: Todos intentionally has no `count:` — stat badge in overview header
        // already surfaces the count, and Todos is the primary capture surface.
        CollapsibleVStackSection("Todos", storageKey: OverviewStorageKeys.todosExpanded(projectID)) {
            VStack(alignment: .leading, spacing: 12) {
            // Add new todo
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.body)
                TextField("Add a todo...", text: $newTodoTitle)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isAddTodoFocused)
                    .onSubmit { addTodo() }
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: Theme.sidebarBackground).opacity(0.5))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
            }

            // Incomplete todos
            ForEach(incompleteTodos, id: \.id) { todo in
                TodoRowView(todo: todo)
            }

            // Completed section
            if !completedTodos.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        showCompleted.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(showCompleted ? 90 : 0))
                            Text("\(completedTodos.count) completed")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if showCompleted {
                        ForEach(completedTodos, id: \.id) { todo in
                            TodoRowView(todo: todo)
                        }
                    }
                }
            }
            }
            .padding(.bottom, 8)
        }
    }

    private func addTodo() {
        let title = newTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let maxOrder = incompleteTodos.map(\.displayOrder).max() ?? -1
        let todo = TodoItem(title: title, projectID: projectID, displayOrder: maxOrder + 1)
        modelContext.insert(todo)
        newTodoTitle = ""
    }

    // MARK: - Sessions

    private var sessionsSection: some View {
        CollapsibleVStackSection(
            "Terminal Sessions",
            storageKey: OverviewStorageKeys.sessionsExpanded(projectID),
            count: terminalSessions.count
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 12)], spacing: 12) {
                ForEach(terminalSessions) { tab in
                    sessionCard(tab)
                }
            }
        }
    }

    private func sessionCard(_ tab: WorkspaceTab) -> some View {
        Button {
            navigateToTab(tab)
        } label: {
            HStack(spacing: 12) {
                if let session = tab.terminalSession {
                    Group {
                        if session.isCustomIcon {
                            Image(session.iconName)
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: session.iconName)
                                .font(.title3)
                        }
                    }
                    .foregroundStyle(session.iconColor)
                    .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.displayTitle)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            if session.needsAttention {
                                Circle()
                                    .fill(.yellow)
                                    .frame(width: 6, height: 6)
                                Text("Waiting for input")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if !(session.isClaude || session.isGemini) {
                                Circle()
                                    .fill(session.isRunning ? .green : .gray)
                                    .frame(width: 6, height: 6)
                                Text(session.isRunning ? "Active" : "Stopped")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let subtitle = session.displaySubtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.head)
                            }
                        }
                    }

                    Spacer()

                    if session.needsAttention {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .modifier(CardStyle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Go To") { navigateToTab(tab) }
            Divider()
            Button("Close") { closeTab(tab) }
        }
    }

    // MARK: - Empty Hero

    private var emptyHero: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Nothing here yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("Press + to add your first Scratch Pad, Browser, Bookmark, or Location.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Browsers

    private var browsersSection: some View {
        // Phase 12 D-A6: count = tabs only; nested Bookmarks shows its own count.
        CollapsibleVStackSection(
            "Browsers",
            storageKey: OverviewStorageKeys.browsersExpanded(projectID),
            count: browserTabs.count
        ) {
            // D-18/D-19: tab grid renders only when tabs exist.
            if !browserTabs.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 12)], spacing: 12) {
                    ForEach(browserTabs) { tab in
                        Button { navigateToTab(tab) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 32)
                                Text(tab.displayName)
                                    .font(.body)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .modifier(CardStyle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Go To") { navigateToTab(tab) }
                            Divider()
                            Button("Close") { closeTab(tab) }
                        }
                    }
                }
            }

            // UIX-15 / D-16/D-17/D-18: nested Bookmarks sub-section — renders only when bookmarks exist.
            // Key: per-project, independent from the outer overview.browsers.expanded.{projectID} key (D-21).
            if !projectBrowserBookmarks.isEmpty {
                CollapsibleVStackSection(
                    "Bookmarks",
                    storageKey: OverviewStorageKeys.browserBookmarksExpanded(projectID),
                    count: projectBrowserBookmarks.count
                ) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 12)], spacing: 12) {
                        ForEach(projectBrowserBookmarks.prefix(12), id: \.id) { bookmark in
                            Button {
                                guard let url = bookmark.url else { return }
                                appState.openBrowser(url: url)
                            } label: {
                                HStack(spacing: 12) {
                                    if let data = bookmark.faviconData, let image = NSImage(data: data) {
                                        Image(nsImage: image)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .frame(width: 32)
                                    } else {
                                        Image(systemName: "globe")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                            .frame(width: 32)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bookmark.title.isEmpty
                                            ? (URL(string: bookmark.urlString)?.host() ?? bookmark.urlString)
                                            : bookmark.title)
                                            .font(.body)
                                            .lineLimit(1)
                                        Text(URL(string: bookmark.urlString)?.host() ?? bookmark.urlString)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .modifier(CardStyle())
                            }
                            .buttonStyle(.plain)
                            .help(bookmark.urlString)
                            .contextMenu {
                                Button("Open") {
                                    if let url = bookmark.url { appState.openBrowser(url: url) }
                                }
                                Button("Copy URL") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(bookmark.urlString, forType: .string)
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    let store = BookmarkStore(context: modelContext)
                                    store.remove(bookmark)
                                }
                            }
                        }
                    }

                    if projectBrowserBookmarks.count > 12 {
                        Text("Showing 12 of \(projectBrowserBookmarks.count). Use the sidebar for the full list.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Documents

    private var documentsSection: some View {
        CollapsibleVStackSection(
            "Open Files",
            storageKey: OverviewStorageKeys.documentsExpanded(projectID),
            count: documentTabs.count
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 12)], spacing: 12) {
                ForEach(documentTabs) { tab in
                    Button { navigateToTab(tab) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tab.iconName)
                                .font(.title3)
                                .foregroundStyle(tab.iconColor)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tab.displayName)
                                    .font(.body)
                                    .lineLimit(1)
                                if tab.isDirty {
                                    Text("Unsaved changes")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }
                            Spacer()
                        }
                        .modifier(CardStyle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Go To") { navigateToTab(tab) }
                        if let url = tab.document?.fileURL {
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                        Divider()
                        Button("Close") { closeTab(tab) }
                    }
                }
            }
        }
    }

    // MARK: - Locations

    private var locationsSection: some View {
        // D-15: inline empty-state row deleted. Section is gated at the body level
        // by `if !projectBookmarks.isEmpty` — reaching here means non-empty.
        CollapsibleVStackSection(
            "Locations",
            storageKey: OverviewStorageKeys.locationsExpanded(projectID),
            count: projectBookmarks.count
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 12)], spacing: 12) {
                ForEach(projectBookmarks) { bookmark in
                    locationCard(bookmark)
                }
            }
        }
    }

    private func locationCard(_ bookmark: BookmarkedDirectory) -> some View {
        let bid = bookmark.persistentModelID.hashValue.description
        return Button {
            appState.selectedBookmarkID = bid
            activeLocationMenuID = bid
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(bookmark.name)
                        .font(.body)
                        .lineLimit(1)
                    if let url = bookmark.resolveURL() {
                        Text(tildePath(url))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                }

                Spacer()

                if let info = locationBranches[bid] {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(info.branch ?? "—")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let count = info.changes, count > 0 {
                            Text("\(count) changes")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .modifier(CardStyle())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: Binding(
                get: { activeLocationMenuID == bid },
                set: { if !$0 { activeLocationMenuID = nil } }
            ),
            arrowEdge: .bottom
        ) {
            VStack(alignment: .leading, spacing: 0) {
                popoverButton("Open Terminal", icon: "terminal", color: .mint) {
                    activeLocationMenuID = nil
                    openInLocation(bookmark, claude: false, gemini: false)
                }
                popoverButton("Launch Claude Code", icon: "brain.head.profile", color: .orange) {
                    activeLocationMenuID = nil
                    openInLocation(bookmark, claude: true, gemini: false)
                }
                popoverButton("Launch Gemini Code", icon: "sparkles", color: .blue) {
                    activeLocationMenuID = nil
                    openInLocation(bookmark, claude: false, gemini: true)
                }
                Divider().padding(.vertical, 4)
                popoverButton("Claude (Skip Permissions)", icon: "exclamationmark.triangle.fill", color: .yellow) {
                    activeLocationMenuID = nil
                    openInLocation(bookmark, claude: true, gemini: false, dangerous: true)
                }
                Divider().padding(.vertical, 4)
                popoverButton("Reveal in Finder", icon: "folder", color: .gray) {
                    activeLocationMenuID = nil
                    if let url = bookmark.resolveURL() {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .padding(6)
            .frame(width: 220)
        }
    }

    // MARK: - Git Info

    private func startGitPolling() {
        gitRefreshTask?.cancel()
        gitRefreshTask = Task {
            while !Task.isCancelled {
                await fetchLocationBranches()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    private func fetchLocationBranches() async {
        for bookmark in projectBookmarks {
            guard !Task.isCancelled else { return }
            guard let url = bookmark.resolveURL() else { continue }
            let bid = bookmark.persistentModelID.hashValue.description
            let path = url.path(percentEncoded: false)
            let result = await Task.detached {
                let branch = try? shellOutput("git -C \"\(path)\" rev-parse --abbrev-ref HEAD 2>/dev/null")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let status = try? shellOutput("git -C \"\(path)\" status --porcelain 2>/dev/null")
                let changes = status?.components(separatedBy: "\n").filter { !$0.isEmpty }.count
                return (branch: branch, changes: changes)
            }.value
            locationBranches[bid] = result
        }
    }

    // MARK: - Actions

    private func launchInProject(claude: Bool, gemini: Bool) {
        pendingLaunchClaude = claude
        pendingLaunchGemini = gemini
        pendingDangerousMode = false
        if projectBookmarks.count == 1, let bookmark = projectBookmarks.first,
           let url = bookmark.resolveURL() {
            let bookmarkID = bookmark.persistentModelID.hashValue.description
            appState.openTerminal(projectName: bookmark.name, directory: url, bookmarkID: bookmarkID, launchClaude: claude, launchGemini: gemini)
        } else {
            showTerminalPicker = true
        }
    }

    private func openInLocation(_ bookmark: BookmarkedDirectory, claude: Bool, gemini: Bool, dangerous: Bool = false) {
        guard let url = bookmark.resolveURL() else { return }
        let bookmarkID = bookmark.persistentModelID.hashValue.description
        appState.openTerminal(projectName: bookmark.name, directory: url, bookmarkID: bookmarkID, launchClaude: claude, launchGemini: gemini, dangerousMode: dangerous)
    }

    private func navigateToTab(_ tab: WorkspaceTab) {
        if let index = appState.tabs.firstIndex(where: { $0.id == tab.id }) {
            appState.activeTabIndex = index
        }
    }

    private func closeTab(_ tab: WorkspaceTab) {
        if let index = appState.tabs.firstIndex(where: { $0.id == tab.id }) {
            appState.requestCloseTab(at: index)
        }
    }

    private func tildePath(_ url: URL) -> String {
        let path = url.path(percentEncoded: false)
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func addLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select a directory to add as a location"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try SecurityScopedBookmark.create(for: url)
            let maxOrder = bookmarks.map(\.displayOrder).max() ?? -1
            let bookmark = BookmarkedDirectory(
                name: url.lastPathComponent,
                bookmarkData: data,
                displayOrder: maxOrder + 1,
                isFile: false
            )
            bookmark.projectID = projectID
            modelContext.insert(bookmark)
            try? modelContext.save()
            appState.selectedBookmarkID = bookmark.persistentModelID.hashValue.description
        } catch {
            // Bookmark creation failed
        }
    }
}

// MARK: - Card Style Modifier

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: Theme.sidebarBackground).opacity(0.8))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            }
    }
}
