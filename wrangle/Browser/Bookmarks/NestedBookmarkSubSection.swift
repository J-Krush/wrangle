//
//  NestedBookmarkSubSection.swift
//  Wrangle
//
//  Nested Bookmarks sub-section rendered inside BrowserSessionsSection (sidebar).
//  Hides itself when no bookmarks exist for the active project (D-02/D-09/UIX-13).
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct NestedBookmarkSubSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrowserBookmark.dateAdded, order: .reverse) private var allBookmarks: [BrowserBookmark]
    @Query(sort: \BrowserBookmarkFolder.displayOrder) private var allFolders: [BrowserBookmarkFolder]
    @State private var editing: BrowserBookmark?
    // D-05: new key; independent from sidebar.browsers.expanded
    @AppStorage("sidebar.browsers.bookmarks.expanded") private var isExpanded: Bool = true

    private var visibleBookmarks: [BrowserBookmark] {
        let projectID = appState.selectedProjectID
        return allBookmarks.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    private var visibleFolders: [BrowserBookmarkFolder] {
        let projectID = appState.selectedProjectID
        return allFolders.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    var body: some View {
        // .sheet attached to a Group so the edit sheet stays mounted for the whole sub-section scope.
        Group {
            // D-02/D-09/UIX-13: hide-when-empty at the sub-section level
            if !visibleBookmarks.isEmpty {
                // Sub-header: chevron + "Bookmarks" + count-only-when-collapsed (D-04).
                Button {
                    withAnimation(.snappy(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        Text("Bookmarks")
                        // D-04: count rendered only when collapsed
                        if !isExpanded {
                            Text("\(visibleBookmarks.count)")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onDrop(of: [.text], delegate: BookmarkFolderDropDelegate(
                    targetFolderID: nil,
                    modelContext: modelContext
                ))

                if isExpanded {
                    content
                }
            }
        }
        .sheet(item: $editing) { bookmark in
            BookmarkEditSheet(bookmark: bookmark)
        }
    }

    @ViewBuilder
    private var content: some View {
        // D-06: unfiled bookmarks first (inline, no wrapper folder), then top-level folders.
        let bookmarksByFolder = Dictionary(grouping: visibleBookmarks) { $0.folderID }
        let childFoldersByParent = Dictionary(grouping: visibleFolders) { $0.parentFolderID }

        if let unfiled = bookmarksByFolder[nil], !unfiled.isEmpty {
            ForEach(unfiled, id: \.id) { bookmark in
                BookmarkRow(bookmark: bookmark, edit: { editing = $0 })
            }
        }

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
            Button {
                withAnimation(.snappy(duration: 0.15)) {
                    isExpanded.toggle()
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
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button("Delete Folder and All Bookmarks", role: .destructive) {
                deleteRecursively()
            }
            Button("Delete Folder Only (Keep Bookmarks)") {
                deleteKeepingBookmarks()
            }
        }
        .onDrop(of: [.text], delegate: BookmarkFolderDropDelegate(
            targetFolderID: folder.id,
            modelContext: modelContext
        ))
    }

    /// Delete this folder, all nested subfolders, and every bookmark contained
    /// (directly or transitively). Matches user expectation of "remove folder".
    private func deleteRecursively() {
        var foldersToDelete: [BrowserBookmarkFolder] = [folder]
        var bookmarksToDelete: [BrowserBookmark] = []
        var queue: [BrowserBookmarkFolder] = [folder]
        while let current = queue.popLast() {
            bookmarksToDelete.append(contentsOf: bookmarksByFolder[current.id] ?? [])
            for child in childFoldersByParent[current.id] ?? [] {
                foldersToDelete.append(child)
                queue.append(child)
            }
        }
        for bookmark in bookmarksToDelete {
            modelContext.delete(bookmark)
        }
        for target in foldersToDelete {
            modelContext.delete(target)
        }
        try? modelContext.save()
    }

    /// Delete just this folder; move its direct bookmarks to the parent folder
    /// (child folders keep their structure and are reparented).
    private func deleteKeepingBookmarks() {
        for bookmark in directBookmarks {
            bookmark.folderID = folder.parentFolderID
        }
        for child in childFoldersByParent[folder.id] ?? [] {
            child.parentFolderID = folder.parentFolderID
        }
        modelContext.delete(folder)
        try? modelContext.save()
    }
}

// MARK: - Drop Delegate

/// Accepts a bookmark-ID string drag payload and reparents the bookmark into
/// the target folder (or unfiled when `targetFolderID == nil`).
private struct BookmarkFolderDropDelegate: DropDelegate {
    let targetFolderID: String?
    let modelContext: ModelContext

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.text])
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        let target = targetFolderID
        let ctx = modelContext
        _ = provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let idString = object as? String else { return }
            Task { @MainActor in
                let descriptor = FetchDescriptor<BrowserBookmark>()
                guard let all = try? ctx.fetch(descriptor),
                      let bookmark = all.first(where: { $0.id == idString }) else { return }
                bookmark.folderID = target
                try? ctx.save()
            }
        }
        return true
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
        .onDrag {
            NSItemProvider(object: bookmark.id as NSString)
        }
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
