//
//  BookmarksPopoverButton.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

struct BookmarksPopoverButton: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var showPopover: Bool = false

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            Image(systemName: "book")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Bookmarks")
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            BookmarksPopoverContent(
                onOpen: { url in
                    showPopover = false
                    navigate(to: url)
                },
                onImport: {
                    showPopover = false
                    appState.showBookmarkImport = true
                }
            )
            .frame(width: 380, height: 420)
        }
    }

    private func navigate(to url: URL) {
        // Default: open in a new workspace browser tab.
        appState.openBrowser(url: url)
    }
}

private struct BookmarksPopoverContent: View {
    let onOpen: (URL) -> Void
    let onImport: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrowserBookmark.dateAdded, order: .reverse) private var allBookmarks: [BrowserBookmark]
    @Query(sort: \BrowserBookmarkFolder.displayOrder) private var allFolders: [BrowserBookmarkFolder]
    @State private var filter: String = ""
    @State private var editing: BrowserBookmark?

    private var visibleBookmarks: [BrowserBookmark] {
        let projectID = appState.selectedProjectID
        let scoped = allBookmarks.filter { $0.projectID == projectID || $0.projectID == nil }
        guard !filter.isEmpty else { return scoped }
        let lower = filter.lowercased()
        return scoped.filter {
            $0.title.lowercased().contains(lower) || $0.urlString.lowercased().contains(lower)
        }
    }

    private var visibleFolders: [BrowserBookmarkFolder] {
        let projectID = appState.selectedProjectID
        return allFolders.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if visibleBookmarks.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .sheet(item: $editing) { bookmark in
            BookmarkEditSheet(bookmark: bookmark)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "book")
                .foregroundStyle(.secondary)
                .font(.system(size: 12))
            Text("Bookmarks")
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            TextField("Filter", text: $filter)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .frame(maxWidth: 160)
            Menu {
                Button("Import Bookmarks...") { onImport() }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 12))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(10)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "book")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text(filter.isEmpty ? "No bookmarks yet" : "No matches")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            if filter.isEmpty {
                Text("Star the current page, or import from another browser.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                Button("Import Bookmarks...") { onImport() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var list: some View {
        let grouped = Dictionary(grouping: visibleBookmarks) { $0.folderID }
        let unfiled = grouped[nil] ?? []
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !unfiled.isEmpty {
                    ForEach(unfiled, id: \.id) { bookmark in
                        BookmarkPopoverRow(bookmark: bookmark, onOpen: onOpen, edit: { editing = $0 })
                        Divider().padding(.leading, 28)
                    }
                }

                ForEach(visibleFolders, id: \.id) { folder in
                    if let items = grouped[folder.id], !items.isEmpty {
                        folderHeader(folder.name)
                        ForEach(items, id: \.id) { bookmark in
                            BookmarkPopoverRow(bookmark: bookmark, onOpen: onOpen, edit: { editing = $0 })
                            Divider().padding(.leading, 28)
                        }
                    }
                }
            }
        }
    }

    private func folderHeader(_ name: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 10))
            Text(name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: Theme.chromeBackground).opacity(0.5))
    }
}

private struct BookmarkPopoverRow: View {
    let bookmark: BrowserBookmark
    let onOpen: (URL) -> Void
    let edit: (BrowserBookmark) -> Void

    @Environment(\.modelContext) private var modelContext

    private var favicon: NSImage? {
        guard let data = bookmark.faviconData else { return nil }
        return NSImage(data: data)
    }

    var body: some View {
        Button {
            if let url = bookmark.url { onOpen(url) }
        } label: {
            HStack(spacing: 8) {
                if let favicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(bookmark.title.isEmpty ? (URL(string: bookmark.urlString)?.host() ?? bookmark.urlString) : bookmark.title)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Text(bookmark.urlString)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open") {
                if let url = bookmark.url { onOpen(url) }
            }
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(bookmark.urlString, forType: .string)
            }
            Button("Edit...") { edit(bookmark) }
            Divider()
            Button("Delete", role: .destructive) {
                let store = BookmarkStore(context: modelContext)
                store.remove(bookmark)
            }
        }
    }
}
