import SwiftUI
import SwiftData

struct ProjectRailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.displayOrder) private var projects: [Project]
    @State private var showNewProjectSheet = false
    @State private var showEditProjectSheet = false
    @State private var editingProject: Project?
    @State private var sheetName = ""
    @State private var sheetColorHex = "#007AFF"
    @State private var draggingProjectID: String?
    @State private var dropTargetProjectID: String?

    var body: some View {
        VStack(spacing: 0) {
            // Sidebar toggle
            sidebarToggleButton
                .padding(.top, 8)
                .padding(.bottom, 4)

            Divider()
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    projectOverviewButton
                    ForEach(projects) { project in
                        projectButton(project)
                    }
                    addButton
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .frame(width: 52)
        .background(Color(nsColor: Theme.chromeBackground))
        .onAppear { appState.orderedProjectIDs = projects.map(\.id) }
        .onChange(of: projects.map(\.id)) { _, ids in
            appState.orderedProjectIDs = ids
        }
        .sheet(isPresented: $showNewProjectSheet) {
            ProjectEditSheet(name: $sheetName, colorHex: $sheetColorHex, isNew: true) {
                commitNewProject()
            }
        }
        .sheet(isPresented: $showEditProjectSheet) {
            ProjectEditSheet(name: $sheetName, colorHex: $sheetColorHex, isNew: false) {
                commitEditProject()
            }
        }
    }

    // MARK: - Project Overview Button

    private var projectOverviewButton: some View {
        Button {
            appState.showAllProjects()
        } label: {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(appState.selectedProjectID == nil ? .primary : .secondary)
                .frame(width: 32, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("All Projects")
    }

    // MARK: - Sidebar Toggle

    private var sidebarToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.isSidebarVisible.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(appState.isSidebarVisible ? .primary : .secondary)
                .frame(width: 32, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(appState.isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")
    }

    // MARK: - Project Button

    private func projectButton(_ project: Project) -> some View {
        let isSelected = appState.selectedProjectID == project.id
        let initials = projectInitials(project.name)
        let color = Color(hex: project.colorHex) ?? .blue
        let projectTabs = appState.tabs.filter { $0.projectID == project.id }
        let hasAttention = projectTabs.contains { $0.terminalSession?.needsAttention == true }

        return Button {
            if appState.selectedProjectID != project.id {
                appState.switchToProject(project.id)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: isSelected ? 12 : 20)
                    .fill(isSelected ? color : color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(initials)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 40, height: 40)

                if hasAttention {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color(nsColor: Theme.chromeBackground), lineWidth: 2))
                        .offset(x: 2, y: -2)
                }
            }
            .padding(4)
        }
        .buttonStyle(.plain)
        .help(project.name)
        .contextMenu {
            projectContextMenu(project)
        }
        .overlay(alignment: .top) {
            if dropTargetProjectID == project.id && draggingProjectID != nil && draggingProjectID != project.id {
                Color.accentColor
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .offset(y: -5)
            }
        }
        .draggable(ProjectDragPayload(id: project.id)) {
            Text(initials)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(color, in: RoundedRectangle(cornerRadius: 12))
        }
        .dropDestination(for: ProjectDragPayload.self) { items, _ in
            guard let source = items.first, source.id != project.id else { return false }
            reorderProject(sourceID: source.id, beforeTargetID: project.id)
            draggingProjectID = nil
            dropTargetProjectID = nil
            return true
        } isTargeted: { targeted in
            if targeted {
                dropTargetProjectID = project.id
                if draggingProjectID == nil { draggingProjectID = "?" }
            } else if dropTargetProjectID == project.id {
                dropTargetProjectID = nil
            }
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            sheetName = ""
            sheetColorHex = "#007AFF"
            showNewProjectSheet = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 40, height: 40)

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .help("New Project")
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func projectContextMenu(_ project: Project) -> some View {
        Button("Edit...") {
            editingProject = project
            sheetName = project.name
            sheetColorHex = project.colorHex
            showEditProjectSheet = true
        }
        Divider()
        Button("Delete Project", role: .destructive) {
            deleteProject(project)
        }
    }

    // MARK: - Actions

    private func commitNewProject() {
        let name = sheetName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let maxOrder = projects.map(\.displayOrder).max() ?? -1
        let project = Project(name: name, displayOrder: maxOrder + 1)
        project.colorHex = sheetColorHex
        modelContext.insert(project)
        try? modelContext.save()
        appState.switchToProject(project.id)

    }

    private func commitEditProject() {
        let name = sheetName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let project = editingProject else { return }
        project.name = name
        project.colorHex = sheetColorHex
        try? modelContext.save()
        editingProject = nil

    }

    private func deleteProject(_ project: Project) {
        if appState.selectedProjectID == project.id {
            appState.selectedProjectID = nil
            appState.activeIntentID = nil
        }
        let projectID = project.id
        do {
            let bookmarkDesc = FetchDescriptor<BookmarkedDirectory>(
                predicate: #Predicate { $0.projectID == projectID }
            )
            for bookmark in try modelContext.fetch(bookmarkDesc) {
                bookmark.projectID = nil
            }
            let intentDesc = FetchDescriptor<Intent>(
                predicate: #Predicate { $0.projectID == projectID }
            )
            for intent in try modelContext.fetch(intentDesc) {
                modelContext.delete(intent)
            }
        } catch {}
        modelContext.delete(project)
        try? modelContext.save()
    }

    // MARK: - Reordering

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

    // MARK: - Helpers

    private func projectInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

}
