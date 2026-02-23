//
//  TerminalDirectoryPicker.swift
//  wrangle
//

import SwiftUI
import SwiftData

struct TerminalDirectoryPicker: View {
    let launchClaude: Bool
    let onSelect: (String, URL, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<BookmarkedDirectory> { !$0.isFile },
        sort: \BookmarkedDirectory.displayOrder
    ) private var bookmarks: [BookmarkedDirectory]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(launchClaude ? "Open Claude Code in..." : "Open Terminal in...")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()

            if bookmarks.isEmpty {
                Text("No bookmarked directories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(bookmarks) { bookmark in
                            if let url = bookmark.resolveURL(refreshIfStale: false) {
                                Button {
                                    onSelect(bookmark.name, url, bookmark.persistentModelID.hashValue.description)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "folder.fill")
                                            .foregroundStyle(Color(hex: bookmark.iconColorHex) ?? .blue)
                                            .font(.caption)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(bookmark.name)
                                                .font(.system(size: 12, weight: .medium))
                                                .lineLimit(1)
                                            Text(tildePath(url))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.head)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 240)
            }

            Divider()

            Button {
                browseForDirectory()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                        .font(.caption)
                    Text("Browse...")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
        .frame(width: 260)
    }

    private func tildePath(_ url: URL) -> String {
        let path = url.path(percentEncoded: false)
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func browseForDirectory() {
        let panel = NSOpenPanel()
        panel.title = launchClaude ? "Choose directory for Claude Code" : "Choose directory for Terminal"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let name = url.lastPathComponent
        onSelect(name, url, nil)
        dismiss()
    }
}

// MARK: - Color hex init helper

private extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        guard hexString.count == 6 else { return nil }
        var rgb: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgb) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
