//
//  ContentView.swift
//  wrangle
//
//  Created by John Kreisher on 2/21/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

private struct DetailLeadingKey: PreferenceKey {
    static var defaultValue: CGFloat = 240
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentView: View {
    @State private var appState = AppState()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @State private var editorContext = EditorContext()

    /// Cached map: directory path -> (bookmarkID, bookmarkName)
    @State private var bookmarkPathCache: [(path: String, id: String, name: String, roomID: String?)] = []
    @Query private var rooms: [Room]

    private var windowTitle: String {
        if let roomID = appState.selectedRoomID,
           let room = rooms.first(where: { $0.id == roomID }) {
            return room.name
        }
        return "Wrangle"
    }

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            TrialBannerView()

            HStack(spacing: 0) {
                SidebarView()

                // Right side: tabs + detail
                VStack(spacing: 0) {
                    if appState.selectedRoomID != nil {
                        TitleBarTabStrip()
                    }
                    NotificationBannerView()

                ZStack {
                    // Keep all terminal NSViews alive to preserve process state and scrollback
                    // These must live outside the room/viewMode conditionals so switching
                    // rooms or going to project overview doesn't destroy the NSView hierarchy.
                    ForEach(appState.tabs) { tab in
                        if let session = tab.terminalSession {
                            let isActive = appState.selectedRoomID != nil
                                && appState.viewMode == .editor
                                && appState.activeTab?.id == tab.id
                            TerminalTabContentView(session: session)
                                .opacity(isActive ? 1 : 0)
                                .allowsHitTesting(isActive)
                                .zIndex(isActive ? 1 : 0)
                        }
                    }

                    // Keep all browser WKWebViews alive to preserve page state
                    ForEach(appState.tabs) { tab in
                        if let session = tab.browserSession {
                            let isActive = appState.selectedRoomID != nil
                                && appState.viewMode == .editor
                                && appState.activeTab?.id == tab.id
                            BrowserTabContentView(session: session)
                                .opacity(isActive ? 1 : 0)
                                .allowsHitTesting(isActive)
                                .zIndex(isActive ? 1 : 0)
                        }
                    }

                    if appState.selectedRoomID == nil {
                        // No room selected — show project overview
                        DashboardView()
                    } else {
                    switch appState.viewMode {
                    case .dashboard:
                        DashboardView()
                    case .canvas:
                        CanvasView()
                    case .editor:
                        // Document or empty view (renders on top when active tab is not a terminal/browser)
                        if let tab = appState.activeTab {
                            switch tab.content {
                            case .document(let doc):
                                VStack(spacing: 0) {
                                    documentContentView(doc)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                                    handleFileDrop(providers)
                                }
                                .transition(.identity)
                            case .terminal, .browser:
                                EmptyView()
                            }
                        } else {
                            DashboardView()
                        }
                    }
                    } // end if selectedRoomID != nil
                }
                .animation(nil, value: appState.activeTabIndex)
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: DetailLeadingKey.self,
                        value: geo.frame(in: .named("root")).minX
                    )
                }
            )
            .background(
                Color(nsColor: Theme.chromeBackground),
                ignoresSafeAreaEdges: .all
            )
            .alert(
                "Close Terminal?",
                isPresented: Binding(
                    get: { appState.showTerminalCloseConfirmation },
                    set: { if !$0 { appState.cancelCloseTab() } }
                )
            ) {
                Button("Cancel", role: .cancel) {
                    appState.cancelCloseTab()
                }
                Button("Close", role: .destructive) {
                    appState.confirmCloseTab()
                }
            } message: {
                if let index = appState.pendingCloseTabIndex,
                   index < appState.tabs.count,
                   let session = appState.tabs[index].terminalSession {
                    Text("The terminal session '\(session.displayTitle)' is still running. Are you sure?")
                } else {
                    Text("A terminal session is still running. Are you sure?")
                }
            }
            .alert(
                "Update Available",
                isPresented: Binding(
                    get: { coordinator.updateChecker.updateAvailable },
                    set: { if !$0 { coordinator.updateChecker.dismissUpdate() } }
                )
            ) {
                Button("Download") { coordinator.updateChecker.openDownloadPage() }
                Button("Not Now", role: .cancel) { coordinator.updateChecker.dismissUpdate() }
            } message: {
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
                Text("Wrangle v\(coordinator.updateChecker.latestVersion) is available. You're currently running v\(current).")
            }
            .alert(
                "You're Up to Date",
                isPresented: Binding(
                    get: { coordinator.updateChecker.showUpToDate },
                    set: { coordinator.updateChecker.showUpToDate = $0 }
                )
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
                Text("Wrangle v\(current) is the latest version.")
            }
        } // HStack
        } // outer VStack (trial banner + content)
        .background(
            Color(nsColor: Theme.chromeBackground),
            ignoresSafeAreaEdges: .all
        )
        .coordinateSpace(name: "root")
        .onPreferenceChange(DetailLeadingKey.self) { value in
            appState.detailAreaLeading = value
        }
        .overlay {
            if appState.showFuzzyFinder {
                FuzzyFinderView()
            }
            if appState.showGlobalSearch {
                GlobalSearchView()
            }
            LicenseGateView()
            NotificationPermissionView()
        }
        .navigationTitle(windowTitle)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button { appState.goBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                }
                .disabled(!appState.canGoBack)
                .help("Back (⌘[)")

                Button { appState.goForward() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .disabled(!appState.canGoForward)
                .help("Forward (⌘])")
            }

        }
        .background { WindowChromeConfigurator(appState: appState) }
        .frame(minWidth: 140, minHeight: 500)
        .onChange(of: appState.activeTabIndex) { _, _ in
            if let url = appState.activeDocument?.fileURL {
                recordRecentFile(url: url, in: modelContext)
                updateSelectedBookmarkCached(for: url)
                appState.selectedFileTreeURL = url
            } else {
                appState.selectedFileTreeURL = nil
            }
        }
        .onChange(of: bookmarks.count) { _, _ in
            rebuildBookmarkPathCache()
        }
        .onChange(of: coordinator.isAppForeground) { _, isForeground in
            if isForeground {
                Task { await coordinator.notificationManager.refreshStatus() }
            }
        }
        .onAppear {
            appState.coordinator = coordinator
            coordinator.register(appState)
            RoomMigration.runIfNeeded(modelContext: modelContext)
            rebuildBookmarkPathCache()
        }
        .onDisappear {
            // Stop all terminal sessions for this window
            for tab in appState.tabs {
                tab.terminalSession?.stop()
            }
            coordinator.unregister(appState)
        }
        .environment(appState)
        .focusedSceneValue(\.appState, appState)
    }

    // MARK: - Document Content View

    @ViewBuilder
    private func documentContentView(_ doc: EditorDocument) -> some View {
        // Toolbar area — file-type-specific toolbar
        let ext = doc.fileURL?.pathExtension.lowercased()
        if ext == "json" {
            JsonToolbar(
                text: Binding(
                    get: { doc.content },
                    set: { doc.content = $0; doc.markDirty(); appState.promotePreviewTab(for: doc.id) }
                ),
                onInsert: { block in
                    editorContext.insertBlock(block)
                }
            )
            .background(Color(nsColor: Theme.chromeBackground))

            Divider()
        } else if ["xml", "plist", "svg", "xsd", "xsl", "xslt"].contains(ext) {
            XmlToolbar(
                text: Binding(
                    get: { doc.content },
                    set: { doc.content = $0; doc.markDirty(); appState.promotePreviewTab(for: doc.id) }
                ),
                isPlist: ext == "plist",
                onInsert: { block in
                    editorContext.insertBlock(block)
                }
            )
            .background(Color(nsColor: Theme.chromeBackground))

            Divider()
        } else {
            EditorToolbar(context: editorContext, editingMode: Binding(
                get: { appState.editingMode },
                set: { appState.editingMode = $0 }
            ))
            .background(Color(nsColor: Theme.chromeBackground))

            Divider()
        }

        // Main editor area
        if let error = doc.loadError {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                Text("Could not load file")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                if let url = doc.fileURL {
                    Text(url.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            MarkdownTextView(
                text: Binding(
                    get: { doc.content },
                    set: { doc.content = $0; doc.markDirty(); appState.promotePreviewTab(for: doc.id) }
                ),
                document: doc,
                editorContext: editorContext,
                editingMode: appState.editingMode
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        // Status bar
        StatusBarView(document: doc)
    }

    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]

    private func rebuildBookmarkPathCache() {
        bookmarkPathCache = bookmarks.compactMap { bookmark in
            guard !bookmark.isFile, let dirURL = bookmark.resolveURL() else { return nil }
            let dirPath = dirURL.path(percentEncoded: false)
            let id = bookmark.persistentModelID.hashValue.description
            return (path: dirPath, id: id, name: bookmark.name, roomID: bookmark.roomID)
        }

        // Also populate the scoped URL cache on AppState for fallback resolution
        appState.resolvedBookmarkURLs = bookmarks.compactMap { bookmark in
            guard let url = bookmark.resolveURL() else { return nil }
            let path = url.path(percentEncoded: false)
            return (directoryPath: path, resolvedURL: url)
        }
    }

    private func updateSelectedBookmarkCached(for fileURL: URL) {
        let filePath = fileURL.path(percentEncoded: false)
        for entry in bookmarkPathCache {
            if filePath.hasPrefix(entry.path) {
                appState.selectedBookmarkID = entry.id
                appState.activeProjectName = entry.name
                if let roomID = entry.roomID {
                    appState.selectedRoomID = roomID
                }
                return
            }
        }
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    appState.openFile(url: url, scopedURL: url)
                    recordRecentFile(url: url, in: modelContext)
                    handled = true
                }
            }
        }
        return handled
    }
}

// MARK: - Status Bar

struct StatusBarView: View {
    let document: EditorDocument
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 16) {
            // File type badge
            HStack(spacing: 4) {
                Image(systemName: document.fileType.iconName)
                    .font(.caption2)
                    .foregroundColor(document.fileType.iconColor)
                Text(document.fileType.displayName)
                    .font(.caption2)
            }

            Divider()
                .frame(height: 12)

            // Token count (cached)
            HStack(spacing: 4) {
                Image(systemName: "number")
                    .font(.caption2)
                Text("\(TokenCounter.formattedCount(document.cachedTokenCount)) tokens")
                    .font(.caption2)
            }
            .foregroundColor(TokenCounter.colorForCount(document.cachedTokenCount))
            .help("Experimental: estimated via word count × 1.3 + special characters")

            Divider()
                .frame(height: 12)

            // Character count (cached)
            Text("\(document.cachedCharCount) chars")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Line count (cached)
            Text("\(document.cachedLineCount) lines")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // File path
            if let url = document.fileURL {
                Text(url.path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Menu {
                Button("Report Bug...") {
                    FeedbackHelper.openFeedback(.bug)
                }
                Button("Request Feature...") {
                    FeedbackHelper.openFeedback(.feature)
                }
            } label: {
                Image(systemName: "exclamationmark.bubble")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Send Feedback")
            .accessibilityLabel("Send feedback")

            Button {
                switch appState.appearanceMode {
                case .system: appState.appearanceMode = .dark
                case .dark:   appState.appearanceMode = .light
                case .light:  appState.appearanceMode = .system
                }
            } label: {
                Image(systemName: appearanceIcon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(appearanceTooltip)
            .accessibilityLabel(appearanceTooltip)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(Color(nsColor: Theme.chromeBackground))
    }

    private var appearanceIcon: String {
        switch appState.appearanceMode {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max.fill"
        case .dark:   "moon.fill"
        }
    }

    private var appearanceTooltip: String {
        switch appState.appearanceMode {
        case .system: "Appearance: System"
        case .light:  "Appearance: Light"
        case .dark:   "Appearance: Dark"
        }
    }
}
