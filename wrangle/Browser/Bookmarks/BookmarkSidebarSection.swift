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
        let bookmarksByFolder = Dictionary(grouping: visibleBookmarks) { $0.folderID }
        let childFoldersByParent = Dictionary(grouping: visibleFolders) { $0.parentFolderID }

        // Unfiled bookmarks first, rendered inline
        if let unfiled = bookmarksByFolder[nil], !unfiled.isEmpty {
            ForEach(unfiled, id: \.id) { bookmark in
                BookmarkRow(bookmark: bookmark, edit: { editing = $0 })
            }
        }

        // Top-level folders, each may recurse
        let topLevelFolders = (childFoldersByParent[nil] ?? []).filter { folder in
            folderHasAnyBookmarks(folder,
                                  childFoldersByParent: childFoldersByParent,
                                  bookmarksByFolder: bookmarksByFolder)
        }
        ForEach(topLevelFolders, id: \.id) { folder in
            BookmarkFolderNode(
                folder: folder,
                childFoldersByParent: childFoldersByParent,
                bookmarksByFolder: bookmarksByFolder,
                onEdit: { editing = $0 }
            )
        }
    }

    private func folderHasAnyBookmarks(
        _ folder: BrowserBookmarkFolder,
        childFoldersByParent: [String?: [BrowserBookmarkFolder]],
        bookmarksByFolder: [String?: [BrowserBookmark]]
    ) -> Bool {
        if !(bookmarksByFolder[folder.id]?.isEmpty ?? true) { return true }
        for child in childFoldersByParent[folder.id] ?? [] {
            if folderHasAnyBookmarks(child,
                                     childFoldersByParent: childFoldersByParent,
                                     bookmarksByFolder: bookmarksByFolder) {
                return true
            }
        }
        return false
    }
}

// MARK: - Folder Node (recursive)

private struct BookmarkFolderNode: View {
    let folder: BrowserBookmarkFolder
    let childFoldersByParent: [String?: [BrowserBookmarkFolder]]
    let bookmarksByFolder: [String?: [BrowserBookmark]]
    let onEdit: (BrowserBookmark) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded: Bool = false

    private var directBookmarks: [BrowserBookmark] {
        bookmarksByFolder[folder.id] ?? []
    }

    private var childFolders: [BrowserBookmarkFolder] {
        (childFoldersByParent[folder.id] ?? []).filter { child in
            !(bookmarksByFolder[child.id]?.isEmpty ?? true)
                || !(childFoldersByParent[child.id]?.isEmpty ?? true)
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(directBookmarks, id: \.id) { bookmark in
                BookmarkRow(bookmark: bookmark, edit: onEdit)
            }
            ForEach(childFolders, id: \.id) { child in
                BookmarkFolderNode(
                    folder: child,
                    childFoldersByParent: childFoldersByParent,
                    bookmarksByFolder: bookmarksByFolder,
                    onEdit: onEdit
                )
            }
        } label: {
            Label {
                Text(folder.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } icon: {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .contextMenu {
            Button("Delete Folder", role: .destructive) {
                deleteFolder()
            }
        }
    }

    private func deleteFolder() {
        // Promote direct bookmarks to parent folder (move, don't delete them).
        for bookmark in directBookmarks {
            bookmark.folderID = folder.parentFolderID
        }
        modelContext.delete(folder)
        try? modelContext.save()
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
            openInNewTab()
        } label: {
            Label {
                Text(bookmark.title.isEmpty
                    ? (URL(string: bookmark.urlString)?.host() ?? bookmark.urlString)
                    : bookmark.title)
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
            Button("Open in New Tab") { openInNewTab() }
            Button("Open in Active Tab") { openInActive() }
            Divider()
            Button("Copy URL") { copyURL() }
            Button("Edit...") { edit(bookmark) }
            Divider()
            Button("Delete", role: .destructive) { delete() }
        }
        .modifier(DeleteKeyHandler(enabled: isHovering, action: delete))
    }

    private func openInNewTab() {
        guard let url = bookmark.url else { return }
        appState.openBrowser(url: url)
    }

    private func openInActive() {
        guard let url = bookmark.url else { return }
        if let session = appState.activeTab?.browserSession {
            session.activeTab?.pendingNavigation = .load(url)
        } else {
            appState.openBrowser(url: url)
        }
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
