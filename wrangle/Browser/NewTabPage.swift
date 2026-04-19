//
//  NewTabPage.swift
//  Wrangle
//

import SwiftUI

struct NewTabPage: View {
    let session: BrowserSession
    @State private var urlText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "globe")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)

            Text("New Tab")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                TextField("Enter URL or search", text: $urlText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isFocused)
                    .onSubmit { navigate() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
            .frame(maxWidth: 480)
            .padding(.horizontal, 24)

            bookmarksSection

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: Theme.chromeBackground))
        .onAppear { isFocused = true }
    }

    @ViewBuilder
    private var bookmarksSection: some View {
        // Placeholder for bookmarks grid — wired up in Phase 5.
        Text("Type a URL to get started")
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
    }

    private func navigate() {
        let input = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        let url = Self.resolveURL(from: input)
        guard let url else { return }

        guard let tab = session.activeTab else { return }
        tab.url = url
        tab.pendingNavigation = .load(url)
    }

    static func resolveURL(from input: String) -> URL? {
        if input.hasPrefix("http://") || input.hasPrefix("https://") {
            return URL(string: input)
        }
        if input.hasPrefix("localhost") || input.hasPrefix("127.0.0.1") || input.hasPrefix("[::1]") {
            return URL(string: "http://\(input)")
        }
        if input.contains(".") && !input.contains(" ") {
            return URL(string: "https://\(input)")
        }
        let encoded = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
        return URL(string: "https://www.google.com/search?q=\(encoded)")
    }
}
