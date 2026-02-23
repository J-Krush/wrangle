import SwiftUI
import SwiftData

struct RecentFilesMenuContent: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecentFile.lastOpened, order: .reverse) private var recentFiles: [RecentFile]

    var body: some View {
        Menu("Open Recent") {
            ForEach(Array(recentFiles.prefix(20)), id: \.urlString) { recentFile in
                if let url = recentFile.url {
                    Button(url.lastPathComponent) {
                        appState.openFile(url: url)
                    }
                }
            }

            if !recentFiles.isEmpty {
                Divider()
                Button("Clear Menu") {
                    clearRecents()
                }
            }
        }
    }

    private func clearRecents() {
        for file in recentFiles {
            modelContext.delete(file)
        }
        try? modelContext.save()
    }
}

// MARK: - RecentFileRow

struct RecentFileRow: View {
    let url: URL
    let date: Date
    let onOpen: () -> Void

    @State private var isHovering = false

    private var fileType: FileType {
        FileType.detect(from: url)
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 8) {
                Image(systemName: fileType.iconName)
                    .font(.caption)
                    .foregroundColor(fileType.iconColor)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .lineLimit(1)
                    Text(url.deletingLastPathComponent().path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                Spacer()

                Text(relativeDate(date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sidebar Row

struct RecentFileSidebarRow: View {
    let url: URL
    let date: Date
    let onOpen: () -> Void
    @Environment(AppState.self) private var appState
    private var fileType: FileType {
        FileType.detect(from: url)
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 6) {
                Image(systemName: fileType.iconName)
                    .foregroundColor(fileType.iconColor)
                    .frame(width: 16)
                Text(url.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper

/// Records a file open in the recent files list.
/// Call this from wherever the modelContext is available.
func recordRecentFile(url: URL, in modelContext: ModelContext) {
    let urlString = url.absoluteString
    let descriptor = FetchDescriptor<RecentFile>(
        predicate: #Predicate { $0.urlString == urlString }
    )

    if let existing = try? modelContext.fetch(descriptor).first {
        existing.lastOpened = Date()
    } else {
        let recent = RecentFile(urlString: url.absoluteString, lastOpened: .now)
        modelContext.insert(recent)

        // Trim to 20 entries
        let allDescriptor = FetchDescriptor<RecentFile>(
            sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
        )
        if let all = try? modelContext.fetch(allDescriptor), all.count > 20 {
            for file in all.dropFirst(20) {
                modelContext.delete(file)
            }
        }
    }

    try? modelContext.save()
}
