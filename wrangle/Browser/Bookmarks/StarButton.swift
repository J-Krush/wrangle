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
    @State private var refreshTick: Int = 0

    private var currentURL: URL? {
        session.activeTab?.url
    }

    private var projectID: String? {
        appState.selectedProjectID
    }

    private var store: BookmarkStore {
        BookmarkStore(context: modelContext)
    }

    private var isBookmarked: Bool {
        _ = refreshTick
        guard let url = currentURL else { return false }
        return store.isBookmarked(url: url, projectID: projectID)
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
        .onChange(of: currentURL) { _, _ in refreshTick &+= 1 }
    }

    private func toggle() {
        guard let tab = session.activeTab, let url = tab.url else { return }
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
        refreshTick &+= 1
    }
}
