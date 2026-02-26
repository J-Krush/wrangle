import SwiftUI

/// Compact session row displayed inline under a location's DisclosureGroup.
struct LocationSessionRow: View {
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
            HStack(spacing: 6) {
                Group {
                    if session.isCustomIcon {
                        Image(session.iconName)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                            .foregroundStyle(isActive ? session.iconColor : Color.secondary)
                    } else {
                        Image(systemName: session.iconName)
                            .font(.caption2)
                            .foregroundStyle(isActive ? session.iconColor : Color.secondary)
                    }
                }
                .frame(width: 16, alignment: .center)

                Text(session.displayTitle)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if session.needsAttention {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
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
                Button("Stop") { session.stop() }
            } else {
                Button("Restart") { session.restart() }
            }
            Button("Close") {
                if let tab = appState.tabs.first(where: { $0.terminalSession?.id == session.id }) {
                    appState.closeTab(tab)
                }
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
