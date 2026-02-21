//
//  ContentView.swift
//  corral
//
//  Created by John Kreisher on 2/21/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var editorContext = EditorContext()

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 240, max: 400)
        } detail: {
            VStack(spacing: 0) {
                // Tab bar
                TabBarView()

                // Toolbar area — markdown or JSON depending on file type
                if let doc = appState.activeDocument {
                    if doc.fileURL?.pathExtension.lowercased() == "json" {
                        JsonToolbar(
                            text: Binding(
                                get: { doc.content },
                                set: { doc.content = $0; doc.markDirty() }
                            ),
                            onInsert: { block in
                                editorContext.insertBlock(block)
                            }
                        )
                        .background(Color(nsColor: .controlBackgroundColor))

                        Divider()
                    } else {
                        EditorToolbar(context: editorContext, editingMode: $appState.editingMode)
                            .background(Color(nsColor: .controlBackgroundColor))

                        Divider()
                    }
                }

                // Main editor area
                if let doc = appState.activeDocument {
                    MarkdownTextView(
                        text: Binding(
                            get: { doc.content },
                            set: { doc.content = $0; doc.markDirty() }
                        ),
                        document: doc,
                        editorContext: editorContext,
                        editingMode: appState.editingMode
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(doc.id)
                } else {
                    emptyEditorView
                }

                // Status bar
                if let doc = appState.activeDocument {
                    StatusBarView(document: doc)
                }

                // Terminal panel
                if appState.showTerminal {
                    Divider()
                    TerminalView(workingDirectory: resolveActiveBookmarkURL())
                        .frame(height: appState.terminalHeight)
                }
            }
        }
        .overlay {
            if appState.showFuzzyFinder {
                FuzzyFinderView()
            }
            if appState.showGlobalSearch {
                GlobalSearchView()
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers)
        }
        .onChange(of: appState.activeDocumentIndex) { _, _ in
            // Record recently opened file when switching documents
            if let url = appState.activeDocument?.fileURL {
                recordRecentFile(url: url, in: modelContext)
            }
        }
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

    private func resolveActiveBookmarkURL() -> URL? {
        guard let selectedID = appState.selectedBookmarkID else { return nil }
        return bookmarks.first { "\($0.persistentModelID)" == selectedID }?.resolveURL()
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    appState.openFile(url: url)
                    recordRecentFile(url: url, in: modelContext)
                    handled = true
                }
            }
        }
        return handled
    }
}

// MARK: - Tab Bar

struct TabBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(appState.openDocuments.enumerated()), id: \.element.id) { index, doc in
                    TabItemView(
                        document: doc,
                        isActive: index == appState.activeDocumentIndex,
                        onSelect: { appState.selectDocument(at: index) },
                        onClose: { appState.closeDocument(at: index) }
                    )
                }
            }
        }
        .frame(height: 32)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct TabItemView: View {
    let document: EditorDocument
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: document.fileType.iconName)
                .font(.caption2)
                .foregroundColor(document.fileType.iconColor)

            Text(document.fileName)
                .font(.caption)
                .lineLimit(1)

            if document.isDirty {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
            }

            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color(nsColor: .controlAccentColor).opacity(0.15) : Color.clear)
        .overlay(alignment: .bottom) {
            if isActive {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Close") { onClose() }
            Button("Close Others") {
                // Close all tabs except this one
            }
        }
    }
}

// MARK: - Status Bar

struct StatusBarView: View {
    let document: EditorDocument

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

            // Token count
            let tokenCount = TokenCounter.count(document.content)
            HStack(spacing: 4) {
                Image(systemName: "number")
                    .font(.caption2)
                Text("\(TokenCounter.formattedCount(tokenCount)) tokens")
                    .font(.caption2)
            }
            .foregroundColor(TokenCounter.colorForCount(tokenCount))

            Divider()
                .frame(height: 12)

            // Character count
            Text("\(document.content.count) chars")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Line count
            let lineCount = document.content.components(separatedBy: "\n").count
            Text("\(lineCount) lines")
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
