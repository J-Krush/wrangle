//
//  NewBookmarkSheet.swift
//  Wrangle
//

import SwiftUI
import SwiftData

struct NewBookmarkSheet: View {
    let projectID: String?
    let prefillURL: String
    let prefillTitle: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String
    @State private var urlString: String
    @State private var folderID: String?
    @State private var folders: [BrowserBookmarkFolder] = []
    @FocusState private var titleFocused: Bool
    @FocusState private var urlFocused: Bool

    init(projectID: String?, prefillURL: String = "", prefillTitle: String = "") {
        self.projectID = projectID
        self.prefillURL = prefillURL
        self.prefillTitle = prefillTitle
        _title = State(initialValue: prefillTitle)
        _urlString = State(initialValue: prefillURL)
    }

    private var resolvedURL: URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && resolvedURL != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New Bookmark")
                .font(.headline)

            LabeledContent("Title") {
                TextField("e.g. Swift by Sundell", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .focused($titleFocused)
                    .onSubmit { save() }
            }

            LabeledContent("URL") {
                TextField("https://example.com", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .focused($urlFocused)
                    .onSubmit { save() }
            }

            LabeledContent("Folder") {
                Picker("Folder", selection: $folderID) {
                    Text("Unfiled").tag(String?.none)
                    ForEach(folders, id: \.id) { folder in
                        Text(folder.name).tag(String?.some(folder.id))
                    }
                }
                .labelsHidden()
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            loadFolders()
            if !prefillTitle.isEmpty {
                urlFocused = true       // title already filled; land cursor in URL
            } else {
                titleFocused = true     // existing behavior
            }
        }
    }

    private func loadFolders() {
        let store = BookmarkStore(context: modelContext)
        folders = store.folders(forProject: projectID)
    }

    private func save() {
        guard canSave, let url = resolvedURL else { return }
        let store = BookmarkStore(context: modelContext)
        store.addOrUpdate(
            title: title.trimmingCharacters(in: .whitespaces),
            url: url,
            folderID: folderID,
            projectID: projectID,
            favicon: nil
        )
        dismiss()
    }
}
