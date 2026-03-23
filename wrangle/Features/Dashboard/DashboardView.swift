import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @Query(sort: \Room.displayOrder) private var rooms: [Room]

    @State private var projectInfos: [ProjectInfo] = []
    @State private var refreshTask: Task<Void, Never>?

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
        .onChange(of: rooms.count) { _, _ in
            buildProjectInfos()
            startGitRefresh()
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
            Text("Add a location in the sidebar to see it here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func buildProjectInfos() {
        projectInfos = rooms.map { room -> ProjectInfo in
            let roomBookmarks = bookmarks.filter { $0.roomID == room.id && !$0.isFile }
            let allSessions = roomBookmarks.flatMap { bookmark in
                let bookmarkID = bookmark.persistentModelID.hashValue.description
                return appState.tabs.compactMap(\.terminalSession).filter { $0.bookmarkID == bookmarkID }
            }
            let agentStatus = resolveAgentStatus(allSessions)
            let primaryBookmark = roomBookmarks.first
            let primaryBookmarkID = primaryBookmark.map { $0.persistentModelID.hashValue.description } ?? ""

            return ProjectInfo(
                id: room.id,
                name: room.name,
                url: primaryBookmark?.resolveURL(),
                bookmarkID: primaryBookmarkID,
                roomID: room.id,
                terminalSessions: allSessions,
                agentStatus: agentStatus,
                lastActivity: room.dateCreated
            )
        }
    }

    private func resolveAgentStatus(_ sessions: [TerminalSession]) -> AgentStatus {
        // Check for Claude/Gemini sessions first
        for session in sessions {
            if (session.isClaude || session.isGemini) && session.isRunning {
                if session.needsAttention {
                    return .waiting
                }
                return .running(0) // Duration would need process start tracking
            }
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

    // MARK: - Navigation

    private func navigateToProject(_ project: ProjectInfo) {
        if let roomID = project.roomID {
            appState.switchToRoom(roomID)
        }
        if !project.bookmarkID.isEmpty {
            appState.selectedBookmarkID = project.bookmarkID
        }
    }
}

// MARK: - Shell Helper

nonisolated private func shellOutput(_ command: String) throws -> String {
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
