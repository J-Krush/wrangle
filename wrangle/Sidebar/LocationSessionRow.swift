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
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.displayTitle)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if let subtitle = session.emulatorSubtitle {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                } icon: {
                    if session.isCustomIcon {
                        Image(session.iconName)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                            .foregroundStyle(isActive ? session.iconColor : Color.secondary)
                    } else {
                        Image(systemName: session.iconName)
                            .foregroundStyle(isActive ? session.iconColor : Color.secondary)
                            .symbolEffect(.pulse, options: .repeating, isActive: session.isWorking)
                    }
                }

                Spacer()

                if session.needsAttention {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, session.emulatorSubtitle != nil ? 2 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(session.displaySubtitle ?? session.displayTitle)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
        .listRowBackground(
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(session.iconColor.opacity(isActive ? 0.9 : 0.4))
                    .frame(width: 3)
                Spacer()
            }
            .background(isActive ? session.iconColor.opacity(0.12) : Color.clear)
        )
        .contextMenu {
            Button("Rename...") {
                renameText = session.displayTitle
                showRenameSheet = true
            }
            Divider()
            Button("Remove", role: .destructive) {
                session.stop()
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
