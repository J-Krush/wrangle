//
//  BookmarkSidebarSection.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

struct BookmarkSidebarSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrowserBookmark.dateAdded, order: .reverse) private var allBookmarks: [BrowserBookmark]
    @Query(sort: \BrowserBookmarkFolder.displayOrder) private var allFolders: [BrowserBookmarkFolder]
    @State private var editing: BrowserBookmark?

    private var visibleBookmarks: [BrowserBookmark] {
        let projectID = appState.selectedProjectID
        return allBookmarks.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    private var visibleFolders: [BrowserBookmarkFolder] {
        let projectID = appState.selectedProjectID
        return allFolders.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    var body: some View {
        Section {
            if visibleBookmarks.isEmpty {
                emptyState
            } else {
                content
            }
        } header: {
            HStack {
                Text("Bookmarks")
                Spacer()
                if !visibleBookmarks.isEmpty {
                    Text("\(visibleBookmarks.count)")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Menu {
                    Button("Import Bookmarks...") {
                        appState.showBookmarkImport = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Bookmark actions")
            }
        }
        .sheet(item: $editing) { bookmark in
            BookmarkEditSheet(bookmark: bookmark)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        Text("No bookmarks yet")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var content: some View {
        // Unfiled first, then each folder in order
        let grouped = Dictionary(grouping: visibleBookmarks) { $0.folderID }
        let unfiled = grouped[nil] ?? []

        if !unfiled.isEmpty {
            ForEach(unfiled, id: \.id) { bookmark in
                BookmarkRow(bookmark: bookmark, edit: { editing = $0 })
            }
        }

        ForEach(visibleFolders, id: \.id) { folder in
            if let bookmarksInFolder = grouped[folder.id], !bookmarksInFolder.isEmpty {
                DisclosureGroup(folder.name) {
                    ForEach(bookmarksInFolder, id: \.id) { bookmark in
                        BookmarkRow(bookmark: bookmark, edit: { editing = $0 })
                    }
                }
                .font(.system(size: 11, weight: .medium))
            }
        }
    }
}

// MARK: - Bookmark Row

private struct BookmarkRow: View {
    let bookmark: BrowserBookmark
    let edit: (BrowserBookmark) -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var isHovering: Bool = false

    private var favicon: NSImage? {
        guard let data = bookmark.faviconData else { return nil }
        return NSImage(data: data)
    }

    var body: some View {
        Button {
            openInActive()
        } label: {
            Label {
                Text(bookmark.title.isEmpty ? (URL(string: bookmark.urlString)?.host() ?? bookmark.urlString) : bookmark.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } icon: {
                if let favicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .frame(width: 13, height: 13)
                } else {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(bookmark.urlString)
        .contextMenu {
            Button("Open in Active Tab") { openInActive() }
            Button("Open in New Tab") { openInNewTab() }
            Divider()
            Button("Copy URL") { copyURL() }
            Button("Edit...") { edit(bookmark) }
            Divider()
            Button("Delete", role: .destructive) { delete() }
        }
        .modifier(DeleteKeyHandler(enabled: isHovering, action: delete))
    }

    private func openInActive() {
        guard let url = bookmark.url else { return }
        if let session = appState.activeTab?.browserSession {
            session.activeTab?.pendingNavigation = .load(url)
        } else {
            appState.openBrowser(url: url)
        }
    }

    private func openInNewTab() {
        guard let url = bookmark.url else { return }
        appState.openBrowser(url: url)
    }

    private func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(bookmark.urlString, forType: .string)
    }

    private func delete() {
        let store = BookmarkStore(context: modelContext)
        store.remove(bookmark)
    }
}

// MARK: - Delete Key Handler

private struct DeleteKeyHandler: ViewModifier {
    let enabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content.focusable(enabled).onKeyPress(.delete) {
            if enabled {
                action()
                return .handled
            }
            return .ignored
        }
    }
}
