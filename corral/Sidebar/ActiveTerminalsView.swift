//
//  ActiveTerminalsView.swift
//  corral
//

import SwiftUI
import SwiftData

struct ActiveTerminalsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let sessions = appState.openTerminalSessions
        if !sessions.isEmpty {
            Section("Sessions") {
                ForEach(sessions) { session in
                    ActiveTerminalRow(session: session)
                }
            }
        }
    }
}

private struct ActiveTerminalRow: View {
    let session: TerminalSession
    @Environment(AppState.self) private var appState
    @State private var showRenameSheet = false
    @State private var renameText = ""

    private var isActive: Bool {
        appState.activeTab?.terminalSession?.id == session.id
    }

    var body: some View {
        Button {
            if let index = appState.tabIndex(for: session) {
                appState.selectTab(at: index)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: session.iconName)
                    .foregroundStyle(isActive ? session.iconColor : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.displayTitle)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let subtitle = session.displaySubtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                }
                Spacer()
                if session.isRunning {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .buttonStyle(.plain)
        .help(session.displaySubtitle ?? session.displayTitle)
        .listRowBackground(
            isActive ? session.iconColor.opacity(0.12) : Color.clear
        )
        .contextMenu {
            Button("Rename...") {
                renameText = session.displayTitle
                showRenameSheet = true
            }

            Divider()

            if session.isRunning {
                Button("Stop") {
                    session.stop()
                }
            } else {
                Button("Restart") {
                    session.restart()
                }
            }

            Button("Close") {
                appState.closeTab(
                    appState.tabs.first(where: { $0.terminalSession?.id == session.id })!
                )
            }
        }
        .sheet(isPresented: $showRenameSheet) {
            VStack(spacing: 16) {
                Text("Rename Session")
                    .font(.headline)
                TextField("Title", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Cancel") {
                        showRenameSheet = false
                    }
                    .keyboardShortcut(.cancelAction)
                    Button("Rename") {
                        session.customTitle = renameText
                        showRenameSheet = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
}
