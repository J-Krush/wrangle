//
//  URLSuggestionPopover.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

struct URLSuggestionPopover: View {
    let query: String
    let projectID: String?
    let onChoose: (URL) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var history: [BrowsingHistoryEntry] = []
    @State private var bookmarks: [BrowserBookmark] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if bookmarks.isEmpty && history.isEmpty {
                Text("No suggestions")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(10)
            } else {
                if !bookmarks.isEmpty {
                    sectionHeader("Bookmarks")
                    ForEach(bookmarks, id: \.id) { bookmark in
                        row(
                            favicon: bookmark.faviconData,
                            title: bookmark.title,
                            urlString: bookmark.urlString,
                            systemImage: "star.fill",
                            tint: .yellow
                        ) {
                            if let url = bookmark.url { onChoose(url) }
                        }
                    }
                }
                if !history.isEmpty {
                    sectionHeader("History")
                    ForEach(history, id: \.id) { entry in
                        row(
                            favicon: entry.faviconData,
                            title: entry.title,
                            urlString: entry.urlString,
                            systemImage: "clock",
                            tint: .secondary
                        ) {
                            if let url = entry.url { onChoose(url) }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 360, minHeight: 40, maxHeight: 320)
        .onAppear(perform: refresh)
        .onChange(of: query) { _, _ in refresh() }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    @ViewBuilder
    private func row(
        favicon: Data?,
        title: String,
        urlString: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let data = favicon, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 13, height: 13)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 10))
                        .foregroundStyle(tint)
                        .frame(width: 13)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Text(urlString)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func refresh() {
        let bookmarkStore = BookmarkStore(context: modelContext)
        let historyStore = HistoryStore(context: modelContext)
        let projectBookmarks = bookmarkStore.bookmarks(forProject: projectID)

        let lower = query.lowercased()
        if query.isEmpty {
            bookmarks = []
            history = Array(historyStore.all().prefix(8))
        } else {
            bookmarks = Array(projectBookmarks.filter { bookmark in
                bookmark.title.lowercased().contains(lower)
                    || bookmark.urlString.lowercased().contains(lower)
            }.prefix(4))
            history = historyStore.suggestions(matching: query, limit: 6)
        }
    }
}
