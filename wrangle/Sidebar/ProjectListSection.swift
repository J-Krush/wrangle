import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProjectListSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.displayOrder) private var projects: [Project]
    @Query private var intents: [Intent]
    @State private var editingProject: Project?
    @State private var showEditSheet = false
    @State private var sheetName = ""
    @State private var sheetColorHex = "#007AFF"
    @State private var draggingProjectID: String?
    @State private var dropTargetProjectID: String?

    var body: some View {
        ForEach(projects) { project in
            let count = intents.filter { $0.projectID == project.id }.count
            Button {
                appState.selectedProjectID = project.id
            } label: {
                ProjectRow(
                    project: project,
                    intentCount: count,
                    isSelected: appState.selectedProjectID == project.id
                )
            }
            .buttonStyle(.plain)
            .listRowBackground(projectRowBackground(projectID: project.id))
            .contextMenu { projectContextMenu(project) }
            .onDrag {
                draggingProjectID = project.id
                return NSItemProvider(object: project.id as NSString)
            }
            .onDrop(of: [UTType.text], isTargeted: dropBinding(for: project.id)) { providers in
                handleReorderDrop(providers: providers, targetID: project.id)
            }
        }

        if projects.isEmpty {
            Text("No projects yet")
                .font(.caption)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
        }

        // Edit sheet trigger
        Color.clear
            .frame(height: 0)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .sheet(isPresented: $showEditSheet) {
                ProjectEditSheet(name: $sheetName, colorHex: $sheetColorHex, isNew: false) {
                    guard let project = editingProject else { return }
                    let trimmed = sheetName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { project.name = trimmed }
                    project.colorHex = sheetColorHex
                    try? modelContext.save()
                    editingProject = nil

                }
            }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func projectContextMenu(_ project: Project) -> some View {
        Button("Edit...") {
            editingProject = project
            sheetName = project.name
            sheetColorHex = project.colorHex
            showEditSheet = true
        }
        Divider()
        Button("Delete Project", role: .destructive) {
            deleteProject(project)
        }
    }

    // MARK: - Reordering

    @ViewBuilder
    private func projectRowBackground(projectID: String) -> some View {
        let isDropTarget = dropTargetProjectID == projectID
            && draggingProjectID != nil
            && draggingProjectID != projectID
        ZStack(alignment: .top) {
            Color.clear
            if isDropTarget {
                Color.accentColor.frame(height: 2)
            }
        }
    }

    private func dropBinding(for projectID: String) -> Binding<Bool> {
        Binding(
            get: { dropTargetProjectID == projectID },
            set: { targeted in
                if targeted { dropTargetProjectID = projectID }
                else if dropTargetProjectID == projectID { dropTargetProjectID = nil }
            }
        )
    }

    private func handleReorderDrop(providers: [NSItemProvider], targetID: String) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let sourceID = item as? String else { return }
            Task { @MainActor in
                reorderProject(sourceID: sourceID, beforeTargetID: targetID)
                draggingProjectID = nil
                dropTargetProjectID = nil
            }
        }
        return true
    }

    private func reorderProject(sourceID: String, beforeTargetID: String) {
        var ordered = Array(projects)
        guard let sourceIndex = ordered.firstIndex(where: { $0.id == sourceID }) else { return }
        let source = ordered.remove(at: sourceIndex)
        if let targetIndex = ordered.firstIndex(where: { $0.id == beforeTargetID }) {
            ordered.insert(source, at: targetIndex)
        } else {
            ordered.append(source)
        }
        for (index, project) in ordered.enumerated() {
            project.displayOrder = index
        }
        try? modelContext.save()
    }

    // MARK: - Actions

    private func deleteProject(_ project: Project) {
        if appState.selectedProjectID == project.id {
            appState.selectedProjectID = nil
            appState.activeIntentID = nil
        }
        // Unlink bookmarks from this project (don't delete the bookmarks themselves)
        let projectID = project.id
        do {
            let descriptor = FetchDescriptor<BookmarkedDirectory>(
                predicate: #Predicate { $0.projectID == projectID }
            )
            let bookmarks = try modelContext.fetch(descriptor)
            for bookmark in bookmarks {
                bookmark.projectID = nil
            }
            // Delete associated intents
            let intentDescriptor = FetchDescriptor<Intent>(
                predicate: #Predicate { $0.projectID == projectID }
            )
            let projectIntents = try modelContext.fetch(intentDescriptor)
            for intent in projectIntents {
                modelContext.delete(intent)
            }
        } catch {}
        modelContext.delete(project)
        try? modelContext.save()
    }

    // MARK: - Colors

}
