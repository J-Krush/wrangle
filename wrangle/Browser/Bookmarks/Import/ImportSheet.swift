//
//  ImportSheet.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

struct BookmarkImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var selectedSource: BookmarkImportSource = .chrome
    @State private var importedTree: ImportedFolder?
    @State private var errorMessage: String?
    @State private var showFDAHelp: Bool = false
    @State private var scopeToProject: Bool = true
    @State private var isImporting: Bool = false
    @State private var importResult: ImportResult?

    struct ImportResult {
        let added: Int
        let skipped: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Picker("Source", selection: $selectedSource) {
                ForEach(BookmarkImportSource.allCases) { source in
                    Label(source.label, systemImage: source.systemImage).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedSource) { _, _ in
                importedTree = nil
                errorMessage = nil
                importResult = nil
            }

            if let tree = importedTree {
                previewSection(tree: tree)
            } else if let message = errorMessage {
                errorSection(message: message)
            } else if let result = importResult {
                resultSection(result: result)
            } else {
                promptSection
            }

            footer
        }
        .padding(20)
        .frame(width: 520, height: 520)
    }

    // MARK: - Sub-sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Import Bookmarks")
                    .font(.title3.bold())
                Text("One-way import — re-run any time; duplicates are skipped.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var promptSection: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: selectedSource.systemImage)
                .font(.system(size: 42))
                .foregroundStyle(.tertiary)
            Text(selectedSource.label)
                .font(.headline)
            Text(promptText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
            Button("Scan \(selectedSource.label)") {
                runScan()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func previewSection(tree: ImportedFolder) -> some View {
        let total = tree.totalBookmarkCount()
        let selected = tree.totalBookmarkCount(selectedOnly: true)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Found \(total) bookmarks in \(tree.children.count) folders")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(selected) selected")
                    .font(.system(size: 11))
                    .foregroundStyle(selected > 0 ? Color.accentColor : .secondary)
            }

            Toggle(isOn: $scopeToProject) {
                Text("Scope to current project only")
                    .font(.system(size: 11))
            }
            .toggleStyle(.checkbox)
            .help(appState.selectedProjectID == nil
                ? "No project selected — bookmarks will be Global."
                : "Uncheck to create Global bookmarks visible in every project.")

            ScrollView {
                FolderTreeView(folder: tree, depth: 0)
            }
            .frame(maxHeight: .infinity)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func errorSection(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            Text("Couldn't Read \(selectedSource.label)")
                .font(.headline)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
            if showFDAHelp {
                Button("Open Full Disk Access Settings") {
                    openFullDiskAccessPane()
                }
                .buttonStyle(.borderedProminent)
                Text("After granting access, quit and relaunch Wrangle, then try again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else {
                Button("Retry") { runScan() }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func resultSection(result: ImportResult) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.green)
            Text("Import Complete")
                .font(.headline)
            Text("Added \(result.added). Skipped \(result.skipped) duplicate\(result.skipped == 1 ? "" : "s").")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack {
            if importedTree != nil {
                Button("Back") { importedTree = nil; errorMessage = nil }
            }
            Spacer()
            Button(importResult == nil ? "Cancel" : "Done") { dismiss() }
                .keyboardShortcut(.cancelAction)
            if importedTree != nil, importResult == nil {
                Button("Import") { runImport() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(isImporting)
            }
        }
    }

    // MARK: - Actions

    private var promptText: String {
        switch selectedSource {
        case .safari:
            return "Wrangle will read Safari's bookmark file directly. macOS may require Full Disk Access."
        case .chrome:
            return "Wrangle will read Chrome's bookmarks from your user Library."
        case .brave:
            return "Wrangle will read Brave's bookmarks from your user Library."
        case .firefox:
            return "Wrangle will copy Firefox's places.sqlite to a temp directory and read it (safe while Firefox is running)."
        }
    }

    private func runScan() {
        importResult = nil
        errorMessage = nil
        showFDAHelp = false
        importedTree = nil
        do {
            let tree: ImportedFolder
            switch selectedSource {
            case .safari:  tree = try SafariBookmarkImporter.importBookmarks()
            case .chrome:  tree = try ChromeBookmarkImporter.importBookmarks()
            case .brave:   tree = try BraveBookmarkImporter.importBookmarks()
            case .firefox: tree = try FirefoxBookmarkImporter.importBookmarks()
            }
            importedTree = tree
        } catch let error as BookmarkImportError {
            errorMessage = error.errorDescription
            showFDAHelp = error.suggestsFullDiskAccess
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runImport() {
        guard let tree = importedTree else { return }
        isImporting = true
        let store = BookmarkStore(context: modelContext)
        let scopedProjectID = scopeToProject ? appState.selectedProjectID : nil
        let flat = tree.flattenSelected()

        var added = 0
        var skipped = 0

        // Collect unique folder names (the last segment of each path) so we can
        // create BrowserBookmarkFolder entries to assign bookmarks to.
        var folderByName: [String: BrowserBookmarkFolder] = [:]
        for folder in store.folders(forProject: scopedProjectID) {
            folderByName[folder.name] = folder
        }

        for bookmark in flat {
            if store.isBookmarked(url: bookmark.url, projectID: scopedProjectID) {
                skipped += 1
                continue
            }
            let folderName = bookmark.folderPath.dropFirst().joined(separator: " › ")
            var folderID: String?
            if !folderName.isEmpty {
                let folder = folderByName[folderName]
                    ?? store.createFolder(name: folderName, projectID: scopedProjectID)
                folderByName[folderName] = folder
                folderID = folder.id
            }
            store.addOrUpdate(
                title: bookmark.title,
                url: bookmark.url,
                folderID: folderID,
                projectID: scopedProjectID,
                favicon: nil
            )
            added += 1
        }

        importedTree = nil
        importResult = ImportResult(added: added, skipped: skipped)
        isImporting = false
    }

    private func openFullDiskAccessPane() {
        let urlString = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Folder Tree

private struct FolderTreeView: View {
    @Bindable var folder: ImportedFolder
    let depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 6) {
                Toggle("", isOn: Binding(
                    get: { folder.isSelected },
                    set: { folder.setSelected($0) }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()

                Image(systemName: "folder")
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 11))
                Text(folder.name)
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Text("\(folder.totalBookmarkCount())")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, CGFloat(depth) * 14)
            .padding(.vertical, 2)

            ForEach(folder.children) { child in
                FolderTreeView(folder: child, depth: depth + 1)
            }

            if folder.isSelected && !folder.bookmarks.isEmpty {
                ForEach(folder.bookmarks) { bookmark in
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                        Text(bookmark.title)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.leading, CGFloat(depth + 1) * 14 + 20)
                    .padding(.vertical, 1)
                }
            }
        }
    }
}
