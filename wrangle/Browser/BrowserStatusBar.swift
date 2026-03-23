//
//  BrowserStatusBar.swift
//  Wrangle
//

import SwiftUI

struct BrowserStatusBar: View {
    let session: BrowserSession
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 16) {
            // Browser badge
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text("Browser")
                    .font(.caption2)
            }

            Divider()
                .frame(height: 12)

            // Domain
            if let host = session.activeTab?.url?.host() {
                Text(host)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Loading indicator
            if session.activeTab?.isLoading == true {
                ProgressView()
                    .controlSize(.mini)
            }

            Spacer()

            // Full URL
            if let url = session.activeTab?.url {
                Text(url.absoluteString)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Appearance toggle
            Button {
                switch appState.appearanceMode {
                case .system: appState.appearanceMode = .dark
                case .dark:   appState.appearanceMode = .light
                case .light:  appState.appearanceMode = .system
                }
            } label: {
                Image(systemName: appearanceIcon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(appearanceTooltip)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(Color(nsColor: Theme.chromeBackground))
    }

    private var appearanceIcon: String {
        switch appState.appearanceMode {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max.fill"
        case .dark:   "moon.fill"
        }
    }

    private var appearanceTooltip: String {
        switch appState.appearanceMode {
        case .system: "Appearance: System"
        case .light:  "Appearance: Light"
        case .dark:   "Appearance: Dark"
        }
    }
}
