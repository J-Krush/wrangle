import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @Query(sort: \Project.displayOrder) private var projects: [Project]
    @Query private var allTodos: [TodoItem]

    @State private var projectInfos: [ProjectInfo] = []
    @State private var refreshTask: Task<Void, Never>?
    @State private var draggingProjectID: String?
    @State private var dropTargetProjectID: String?

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Projects")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("\(projectInfos.count) projects · \(activeAgentCount) agents active")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 32)

            // Project grid
            if projectInfos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(projectInfos) { project in
                            ProjectCardView(project: project)
                                .onTapGesture {
                                    navigateToProject(project)
                                }
                                .overlay(alignment: .leading) {
                                    if let projectID = project.projectID,
                                       dropTargetProjectID == projectID,
                                       draggingProjectID != nil,
                                       draggingProjectID != projectID {
                                        Color.accentColor
                                            .frame(width: 3)
                                            .clipShape(Capsule())
                                            .offset(x: -8)
                                    }
                                }
                                .onDrag {
                                    if let projectID = project.projectID {
                                        draggingProjectID = projectID
                                        return NSItemProvider(object: projectID as NSString)
                                    }
                                    return NSItemProvider()
                                }
                                .onDrop(of: [UTType.text], isTargeted: dropBinding(for: project.projectID)) { providers in
                                    guard let targetID = project.projectID else { return false }
                                    return handleReorderDrop(providers: providers, targetID: targetID)
                                }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: Theme.chromeBackground))
        .onAppear {
            buildProjectInfos()
            startGitRefresh()
        }
        .onDisappear {
            refreshTask?.cancel()
        }
        .onChange(of: bookmarks.count) { _, _ in
            buildProjectInfos()
            startGitRefresh()
        }
        .onChange(of: projects.count) { _, _ in
            buildProjectInfos()
            startGitRefresh()
        }
        .onChange(of: allTodos.count) { _, _ in
            buildProjectInfos()
        }
    }

    private var activeAgentCount: Int {
        projectInfos.filter(\.hasRunningAgent).count
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No projects yet")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Add a project to see it here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func buildProjectInfos() {
        projectInfos = projects.map { project -> ProjectInfo in
            let projectBookmarks = bookmarks.filter { $0.projectID == project.id && !$0.isFile }
            let allSessions = projectBookmarks.flatMap { bookmark in
                let bookmarkID = bookmark.persistentModelID.hashValue.description
                return appState.tabs.compactMap(\.terminalSession).filter { $0.bookmarkID == bookmarkID }
            }
            let agentStatus = resolveAgentStatus(allSessions)
            let primaryBookmark = projectBookmarks.first
            let primaryBookmarkID = primaryBookmark.map { $0.persistentModelID.hashValue.description } ?? ""

            let projectTodos = allTodos.filter { $0.projectID == project.id }
            let todoTotal = projectTodos.count
            let todoDone = projectTodos.filter(\.isCompleted).count

            return ProjectInfo(
                id: project.id,
                name: project.name,
                url: primaryBookmark?.resolveURL(),
                bookmarkID: primaryBookmarkID,
                projectID: project.id,
                terminalSessions: allSessions,
                agentStatus: agentStatus,
                todoTotal: todoTotal > 0 ? todoTotal : nil,
                todoDone: todoDone > 0 ? todoDone : nil,
                lastActivity: project.dateCreated
            )
        }
    }

    private func resolveAgentStatus(_ sessions: [TerminalSession]) -> AgentStatus {
        let agentSessions = sessions.filter { ($0.isClaude || $0.isGemini) && $0.isRunning }
        let waitingCount = agentSessions.filter(\.needsAttention).count
        let runningCount = agentSessions.count - waitingCount

        if runningCount > 0 {
            return .running(count: runningCount + waitingCount)
        }
        if waitingCount > 0 {
            return .waiting(count: waitingCount)
        }
        if sessions.contains(where: \.isRunning) {
            return .idle
        }
        return .none
    }

    private func startGitRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            for i in projectInfos.indices {
                guard !Task.isCancelled else { return }
                guard let url = projectInfos[i].url else { continue }
                let (branch, changes) = await fetchGitInfo(for: url)
                guard !Task.isCancelled else { return }
                projectInfos[i].gitBranch = branch
                projectInfos[i].uncommittedCount = changes
            }
        }
    }

    private func fetchGitInfo(for url: URL) async -> (String?, Int?) {
        await Task.detached {
            let path = url.path(percentEncoded: false)
            let branch = try? shellOutput("git -C \"\(path)\" rev-parse --abbrev-ref HEAD 2>/dev/null")
            let status = try? shellOutput("git -C \"\(path)\" status --porcelain 2>/dev/null")
            let changeCount = status?.components(separatedBy: "\n").filter { !$0.isEmpty }.count
            return (branch?.trimmingCharacters(in: .whitespacesAndNewlines), changeCount)
        }.value
    }


    // MARK: - Reordering

    private func dropBinding(for projectID: String?) -> Binding<Bool> {
        Binding(
            get: { projectID != nil && dropTargetProjectID == projectID },
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
        buildProjectInfos()
    }

    // MARK: - Navigation

    private func navigateToProject(_ project: ProjectInfo) {
        if let projectID = project.projectID {
            appState.switchToProject(projectID)
        }
        if !project.bookmarkID.isEmpty {
            appState.selectedBookmarkID = project.bookmarkID
        }
    }
}

// MARK: - Shell Helper

nonisolated func shellOutput(_ command: String) throws -> String {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", command]
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}
