//
//  StarButton.swift
//  Wrangle
//

import SwiftUI
import SwiftData

struct StarButton: View {
    let session: BrowserSession
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    // @Query observes the bookmark collection — any add/remove (toggle, import,
    // Remove All, external delete) invalidates the view and re-computes the
    // star state. Replaces the prior manual refreshTick pattern that only
    // caught URL changes + local clicks.
    @Query private var allBookmarks: [BrowserBookmark]

    private var currentURL: URL? {
        session.activeTab?.url
    }

    private var projectID: String? {
        appState.selectedProjectID
    }

    private var isBookmarked: Bool {
        guard let url = currentURL else { return false }
        let key = BrowserBookmark.normalizedKey(for: url.absoluteString)
        return allBookmarks.contains { bookmark in
            BrowserBookmark.normalizedKey(for: bookmark.urlString) == key
                && bookmark.projectID == projectID
        }
    }

    var body: some View {
        Button {
            toggle()
        } label: {
            Image(systemName: isBookmarked ? "star.fill" : "star")
                .font(.system(size: 11))
                .foregroundStyle(isBookmarked ? Color.yellow : Color.secondary)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(currentURL == nil)
        .help(isBookmarked ? "Remove Bookmark" : "Bookmark this Page")
    }

    private func toggle() {
        guard let tab = session.activeTab, let url = tab.url else { return }
        let store = BookmarkStore(context: modelContext)
        if let existing = store.existing(url: url, projectID: projectID) {
            store.remove(existing)
        } else {
            let title = tab.title.isEmpty ? (url.host() ?? url.absoluteString) : tab.title
            store.addOrUpdate(
                title: title,
                url: url,
                projectID: projectID,
                favicon: tab.favicon
            )
        }
    }
}
