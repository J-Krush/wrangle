import SwiftUI
import SwiftData

struct ProjectDetailSection: View {
    let projectID: String
    let scrollProxy: ScrollViewProxy
    let filterText: String
    let activeFileTypeFilters: Set<FileTypeFilter>
    let isFinderDragActive: Bool
    let showActiveSessionsOnly: Bool
    var onAddLocation: (() -> Void)?

    @Environment(AppState.self) private var appState
    @Query private var projects: [Project]

    private var project: Project? {
        projects.first { $0.id == projectID }
    }

    var body: some View {
        Section {
            Button {
                appState.showAllProjects()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Projects")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
        }

        if let project {
            Section {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: project.colorHex) ?? .blue)
                        .frame(width: 10, height: 10)
                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                .listRowBackground(Color.clear)
            }
        }

        Section("Intents") {
            IntentListView(projectID: projectID)
        }

        Section("Locations") {
            ProjectBookmarkListView(
                projectID: projectID,
                scrollProxy: scrollProxy,
                filterText: filterText,
                activeFileTypeFilters: activeFileTypeFilters,
                isFinderDragActive: isFinderDragActive,
                showActiveSessionsOnly: showActiveSessionsOnly,
                onAddLocation: onAddLocation
            )
        }
    }
}
