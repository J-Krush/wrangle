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
    @State private var bookmarkPathCache: [(path: String, id: String, name: String)] = []

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 240, max: 400)
        } detail: {
            VStack(spacing: 0) {
                ZStack {
                    // Keep all terminal NSViews alive to preserve process state and scrollback
                    ForEach(appState.tabs) { tab in
                        if let session = tab.terminalSession {
                            TerminalTabContentView(session: session)
                                .opacity(appState.activeTab?.id == tab.id ? 1 : 0)
                                .allowsHitTesting(appState.activeTab?.id == tab.id)
                                .zIndex(appState.activeTab?.id == tab.id ? 1 : 0)
                        }
                    }

                    // Document or empty view (renders on top when active tab is not a terminal)
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
                        case .terminal:
                            EmptyView()
                        }
                    } else {
                        emptyEditorView
                    }
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: DetailLeadingKey.self,
                        value: geo.frame(in: .named("root")).minX
                    )
                }
            )
            .background(Color(nsColor: Theme.chromeBackground), ignoresSafeAreaEdges: .all)
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
        }
        .coordinateSpace(name: "root")
        .onPreferenceChange(DetailLeadingKey.self) { value in
            appState.detailAreaLeading = value
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .overlay {
            if appState.showFuzzyFinder {
                FuzzyFinderView()
            }
            if appState.showGlobalSearch {
                GlobalSearchView()
            }
        }
        .navigationTitle(appState.activeTab?.displayName ?? "Wrangle")
        .background { TitleBarAccessoryInstaller(appState: appState, modelContainer: modelContext.container) }
        .frame(minWidth: 800, minHeight: 500)
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
        .onAppear {
            appState.coordinator = coordinator
            coordinator.register(appState)
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
        // Toolbar area — markdown or JSON depending on file type
        if doc.fileURL?.pathExtension.lowercased() == "json" {
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

    private var emptyEditorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Open a file to get started")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Cmd+O to open \u{2022} Cmd+N for new file \u{2022} Cmd+P to quick open")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]

    private func rebuildBookmarkPathCache() {
        bookmarkPathCache = bookmarks.compactMap { bookmark in
            guard !bookmark.isFile, let dirURL = bookmark.resolveURL() else { return nil }
            let dirPath = dirURL.path(percentEncoded: false)
            let id = bookmark.persistentModelID.hashValue.description
            return (path: dirPath, id: id, name: bookmark.name)
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
