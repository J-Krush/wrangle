//
//  LocationBrowserRow.swift
//  Wrangle
//

import SwiftUI

struct LocationBrowserRow: View {
    let session: BrowserSession
    @Environment(AppState.self) private var appState

    private var isActive: Bool {
        appState.activeTab?.browserSession?.id == session.id
    }

    var body: some View {
        Button {
            if let index = appState.tabIndex(for: session) {
                appState.selectTab(at: index)
            }
        } label: {
            Label {
                Text(session.displayTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(isActive ? .primary : .secondary)
            } icon: {
                Image(systemName: session.iconName)
                    .foregroundStyle(session.iconColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Theme.sidebarSelectionBackground(isSelected: isActive))
        .contextMenu {
            Button("Close") {
                if let index = appState.tabIndex(for: session) {
                    appState.closeTab(at: index)
                }
            }
        }
    }
}
