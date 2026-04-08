//
//  BrowserTabContentView.swift
//  Wrangle
//

import SwiftUI

struct BrowserTabContentView: View {
    let session: BrowserSession
    @Environment(AppState.self) private var appState

    private var isActive: Bool {
        appState.activeTab?.browserSession?.id == session.id
    }

    var body: some View {
        VStack(spacing: 0) {
            // Internal tab bar (only show if multiple tabs)
            if session.tabs.count > 1 {
                BrowserInternalTabBar(session: session)
                Divider()
            }

            // Toolbar with address bar
            BrowserToolbar(session: session)
            Divider()

            // Progress bar
            if let tab = session.activeTab, tab.isLoading {
                ProgressView(value: tab.estimatedProgress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .frame(height: 2)
            }

            // WebView
            BrowserWebView(session: session, isActive: isActive)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // DevTools panel
            if session.isDevToolsVisible {
                Divider()
                DevToolsPanel(session: session)
                    .frame(height: session.devToolsHeight)
            }

            // Status bar
            Divider()
            BrowserStatusBar(session: session)
        }
        .background(Color(nsColor: Theme.chromeBackground))
    }
}
