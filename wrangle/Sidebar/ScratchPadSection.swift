import SwiftUI

struct ScratchPadSection: View {
    @Environment(AppState.self) private var appState
    @State private var renamingURL: URL?
    @State private var renameText: String = ""

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
    }

    private func padRow(pad: ScratchPadItem) -> some View {
        let isActive = appState.activeDocument?.fileURL == pad.url
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
        .contextMenu {
            Button("Rename...") {
                renameText = pad.name
                renamingURL = pad.url
            }
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([pad.url])
            }
            Divider()
            Button("Delete", role: .destructive) {
                deletePad(pad)
            }
        }
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
