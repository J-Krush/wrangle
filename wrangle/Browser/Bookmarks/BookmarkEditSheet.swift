//
//  BookmarkEditSheet.swift
//  Wrangle
//

import SwiftUI
import SwiftData

struct BookmarkEditSheet: View {
    let bookmark: BrowserBookmark
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String
    @State private var urlString: String
    @State private var folderID: String?
    @State private var folders: [BrowserBookmarkFolder] = []

    init(bookmark: BrowserBookmark, onDone: @escaping () -> Void = {}) {
        self.bookmark = bookmark
        self.onDone = onDone
        self._title = State(initialValue: bookmark.title)
        self._urlString = State(initialValue: bookmark.urlString)
        self._folderID = State(initialValue: bookmark.folderID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Edit Bookmark")
                .font(.headline)

            LabeledContent("Title") {
                TextField("", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledContent("URL") {
                TextField("", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
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
                    .disabled(title.isEmpty || URL(string: urlString) == nil)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear { loadFolders() }
    }

    private func loadFolders() {
        let store = BookmarkStore(context: modelContext)
        folders = store.folders(forProject: bookmark.projectID)
    }

    private func save() {
        guard let url = URL(string: urlString) else { return }
        let store = BookmarkStore(context: modelContext)
        store.update(bookmark, title: title, url: url, folderID: folderID)
        onDone()
        dismiss()
    }
}
