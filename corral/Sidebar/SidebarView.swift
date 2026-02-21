import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @State private var filterText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Filter files...", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            List {
                Section("Bookmarks") {
                    BookmarkListView(filterText: filterText)
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 200, idealWidth: 240)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    appState.newDocument()
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .help("New File (Cmd+N)")

                RecentFilesButton()
            }
        }
    }
}
