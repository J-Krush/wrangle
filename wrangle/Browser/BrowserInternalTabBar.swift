//
//  BrowserInternalTabBar.swift
//  Wrangle
//

import SwiftUI

struct BrowserInternalTabBar: View {
    let session: BrowserSession
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(session.tabs.enumerated()), id: \.element.id) { index, tab in
                    BrowserInternalTabItem(
                        tab: tab,
                        isActive: index == session.activeTabIndex,
                        onSelect: { session.selectTab(at: index) },
                        onClose: { session.closeTab(at: index) }
                    )
                    .contextMenu {
                        Button("Close Tab") {
                            session.closeTab(at: index)
                        }
                        Button("Close Other Tabs") {
                            closeOtherTabs(keeping: index)
                        }
                        .disabled(session.tabs.count <= 1)
                        Divider()
                        Button("Duplicate Tab") {
                            session.addTab(url: tab.url)
                        }
                        Button("Pop Out to Workspace Tab") {
                            appState.popOutBrowserTab(tab, from: session)
                        }
                    }

                    if index < session.tabs.count - 1 {
                        Divider()
                            .frame(height: 16)
                    }
                }

                // New tab button
                Button {
                    session.addTab()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("New Tab")
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 30)
        .background(Color(nsColor: Theme.chromeBackground))
    }

    private func closeOtherTabs(keeping index: Int) {
        let tabToKeep = session.tabs[index]
        let indicesToRemove = session.tabs.indices.filter { $0 != index }.reversed()
        for i in indicesToRemove {
            session.tabs.remove(at: i)
        }
        session.activeTabIndex = 0
        _ = tabToKeep // Silence unused warning
    }
}

// MARK: - Tab Item

private struct BrowserInternalTabItem: View {
    let tab: BrowserTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 4) {
                // Favicon
                if let favicon = tab.favicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                // Title
                Text(tab.displayTitle)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .frame(maxWidth: 120)

                // Loading indicator
                if tab.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.6)
                }

                // Close button
                if isHovering || isActive {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isActive
                    ? Color(nsColor: Theme.sidebarBackground)
                    : (isHovering ? Color.white.opacity(0.05) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
