import SwiftUI

struct ScratchPadSection: View {
    @Environment(AppState.self) private var appState
    @State private var renamingURL: URL?
    @State private var renameText: String = ""
    @State private var hoveredURL: URL?
    @State private var pendingDelete: ScratchPadItem?

    private var visiblePads: [ScratchPadItem] {
        if let projectID = appState.selectedProjectID {
            return appState.scratchPadManager.scratchPads(forProject: projectID)
        }
        // Show unscoped (legacy) pads when no project is selected
        return appState.scratchPadManager.scratchPads.filter { $0.projectID == nil }
    }

    var body: some View {
        ForEach(visiblePads) { pad in
            if renamingURL == pad.url {
                renameRow(pad: pad)
            } else {
                padRow(pad: pad)
            }
        }
        // Phase 12 D-08: Delete-key path routes through an alert for accident
        // protection; context-menu Delete stays immediate (D-09).
        .alert(
            "Move '\(pendingDelete?.name ?? "")' to Trash?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { pad in
            Button("Move to Trash", role: .destructive) { deletePad(pad) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func padRow(pad: ScratchPadItem) -> some View {
        let isActive = appState.activeDocument?.fileURL == pad.url
        let isHovering = hoveredURL == pad.url
        return Button {
            appState.openFile(url: pad.url)
        } label: {
            Label {
                Text(pad.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } icon: {
                Image(systemName: "note.text")
                    .foregroundStyle(.yellow)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Theme.sidebarSelectionBackground(isSelected: isActive))
        .onHover { hovering in
            if hovering {
                hoveredURL = pad.url
            } else if hoveredURL == pad.url {
                hoveredURL = nil
            }
        }
        .contextMenu {
            Button("Rename...") {
                renameText = pad.name
                renamingURL = pad.url
            }
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([pad.url])
            }
            Divider()
            // D-09: context-menu Delete stays immediate — deliberate action.
            Button("Delete", role: .destructive) {
                deletePad(pad)
            }
        }
        // UIX-21: Return = rename, Delete = confirm alert (when hovered).
        .rowKeyboardCommands(
            enabled: isHovering,
            onReturn: {
                renameText = pad.name
                renamingURL = pad.url
            },
            onDelete: { pendingDelete = pad }
        )
    }

    private func renameRow(pad: ScratchPadItem) -> some View {
        TextField("Name", text: $renameText, onCommit: {
            commitRename(from: pad.url)
        })
        .textFieldStyle(.roundedBorder)
        .onExitCommand {
            renamingURL = nil
        }
    }

    private func commitRename(from url: URL) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            renamingURL = nil
            return
        }

        if let newURL = appState.scratchPadManager.renameScratchPad(at: url, to: trimmed) {
            // Update any open tab pointing to the old URL
            if let doc = appState.openDocuments.first(where: { $0.fileURL == url }) {
                doc.fileURL = newURL
            }
        }
        renamingURL = nil
    }

    private func deletePad(_ pad: ScratchPadItem) {
        // Close the tab if this file is open
        if let doc = appState.openDocuments.first(where: { $0.fileURL == pad.url }) {
            appState.closeDocument(doc)
        }
        appState.scratchPadManager.deleteScratchPad(at: pad.url)
    }
}
