//
//  BrowserToolbar.swift
//  Wrangle
//

import SwiftUI

struct BrowserToolbar: View {
    let session: BrowserSession
    @State private var urlText: String = ""
    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            // Back
            Button {
                session.activeTab?.pendingNavigation = .goBack
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(session.activeTab?.canGoBack != true)
            .help("Back")

            // Forward
            Button {
                session.activeTab?.pendingNavigation = .goForward
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(session.activeTab?.canGoForward != true)
            .help("Forward")

            // Reload / Stop
            Button {
                if session.activeTab?.isLoading == true {
                    session.activeTab?.pendingNavigation = .stop
                } else {
                    session.activeTab?.pendingNavigation = .reload
                }
            } label: {
                Image(systemName: session.activeTab?.isLoading == true ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .help(session.activeTab?.isLoading == true ? "Stop" : "Reload")

            // URL field
            TextField("Enter URL or search", text: $urlText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .focused($isURLFieldFocused)
                .onSubmit {
                    navigateToInput()
                }
                .onChange(of: session.activeTab?.url) { _, newURL in
                    if !isURLFieldFocused {
                        urlText = newURL?.absoluteString ?? ""
                    }
                }
                .onAppear {
                    urlText = session.activeTab?.url?.absoluteString ?? ""
                }

            // DevTools toggle
            Button {
                session.isDevToolsVisible.toggle()
            } label: {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 11))
                    .foregroundStyle(session.isDevToolsVisible ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Developer Tools")

            // New tab
            Button {
                session.addTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .help("New Tab")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }

    private func navigateToInput() {
        let input = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        let url: URL?
        if input.hasPrefix("http://") || input.hasPrefix("https://") {
            url = URL(string: input)
        } else if input.contains(".") && !input.contains(" ") {
            url = URL(string: "https://\(input)")
        } else {
            // Treat as search query
            let encoded = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            url = URL(string: "https://www.google.com/search?q=\(encoded)")
        }

        if let url {
            session.activeTab?.pendingNavigation = .load(url)
        }
    }
}
