//
//  BrowserFindBar.swift
//  Wrangle
//

import SwiftUI
import WebKit

struct BrowserFindBar: View {
    let session: BrowserSession
    @Binding var isVisible: Bool
    @Binding var query: String
    @FocusState private var isFocused: Bool
    @State private var lastResult: WKFindResult?
    @State private var caseSensitive: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            TextField("Find on page", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($isFocused)
                .onSubmit { findNext() }
                .onChange(of: query) { _, _ in findNext(fromStart: true) }

            if let result = lastResult {
                Text(result.matchFound ? "Match" : "No matches")
                    .font(.system(size: 10))
                    .foregroundStyle(result.matchFound ? Color.secondary : Color.red)
            }

            Button {
                caseSensitive.toggle()
                findNext(fromStart: true)
            } label: {
                Text("Aa")
                    .font(.system(size: 11, weight: caseSensitive ? .semibold : .regular))
                    .foregroundStyle(caseSensitive ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Case sensitive")

            Button {
                findPrevious()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(query.isEmpty)
            .help("Previous")
            .keyboardShortcut(.upArrow, modifiers: [])

            Button {
                findNext()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(query.isEmpty)
            .help("Next")
            .keyboardShortcut(.downArrow, modifiers: [])

            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.thinMaterial)
        .overlay(Rectangle().fill(.separator).frame(height: 1), alignment: .bottom)
        .onAppear { isFocused = true }
    }

    // MARK: - Actions

    private func findNext(fromStart: Bool = false) {
        runFind(backwards: false)
    }

    private func findPrevious() {
        runFind(backwards: true)
    }

    private func runFind(backwards: Bool) {
        guard let tab = session.activeTab,
              let webView = session.controller?.webView(for: tab),
              !query.isEmpty else {
            lastResult = nil
            return
        }
        let config = WKFindConfiguration()
        config.backwards = backwards
        config.caseSensitive = caseSensitive
        config.wraps = true
        let snapshot = query
        Task { @MainActor in
            do {
                let result = try await webView.find(snapshot, configuration: config)
                if snapshot == query {
                    lastResult = result
                }
            } catch {
                lastResult = nil
            }
        }
    }

    private func close() {
        query = ""
        lastResult = nil
        isVisible = false
    }
}
