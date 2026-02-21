import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum EditingMode: String, CaseIterable {
    case writing
    case dev
}

@Observable
class AppState {
    var openDocuments: [EditorDocument]
    var activeDocumentIndex: Int
    var selectedBookmarkID: String?
    var showFuzzyFinder: Bool = false
    var showGlobalSearch: Bool = false
    var showTerminal: Bool = false
    var terminalHeight: CGFloat = 200
    var searchQuery: String = ""
    var sidebarWidth: CGFloat = 240
    var editingMode: EditingMode = .writing
    var starredFileURLs: Set<String> = []

    var activeDocument: EditorDocument? {
        guard activeDocumentIndex >= 0, activeDocumentIndex < openDocuments.count else {
            return nil
        }
        return openDocuments[activeDocumentIndex]
    }

    init() {
        let blank = EditorDocument()
        self.openDocuments = [blank]
        self.activeDocumentIndex = 0
    }

    func openFile(url: URL) {
        // Check if this file is already open
        if let existingIndex = openDocuments.firstIndex(where: { $0.fileURL == url }) {
            activeDocumentIndex = existingIndex
            return
        }

        let document = EditorDocument(fileURL: url)
        do {
            try document.load()
        } catch {
            // Still add the document even if load fails — content will be empty
        }
        openDocuments.append(document)
        activeDocumentIndex = openDocuments.count - 1
    }

    func newDocument() {
        let panel = NSSavePanel()
        panel.title = "New File"
        panel.nameFieldStringValue = "Untitled.md"
        panel.allowedContentTypes = [.plainText, .json, .yaml]
        panel.allowsOtherFileTypes = true
        panel.isExtensionHidden = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Create the file on disk (empty)
        FileManager.default.createFile(atPath: url.path, contents: nil)

        let document = EditorDocument(fileURL: url)
        openDocuments.append(document)
        activeDocumentIndex = openDocuments.count - 1
    }

    func closeDocument(at index: Int) {
        guard index >= 0, index < openDocuments.count else { return }
        openDocuments.remove(at: index)

        if openDocuments.isEmpty {
            // Always keep at least one document open
            newDocument()
        } else if activeDocumentIndex >= openDocuments.count {
            activeDocumentIndex = openDocuments.count - 1
        } else if activeDocumentIndex > index {
            activeDocumentIndex -= 1
        }
    }

    func closeDocument(_ document: EditorDocument) {
        if let index = openDocuments.firstIndex(where: { $0.id == document.id }) {
            closeDocument(at: index)
        }
    }

    func saveActiveDocument() throws {
        guard let document = activeDocument else { return }
        try document.save()
    }

    func selectDocument(at index: Int) {
        guard index >= 0, index < openDocuments.count else { return }
        activeDocumentIndex = index
    }
}
