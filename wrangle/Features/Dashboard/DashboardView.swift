import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @Query(sort: \Room.displayOrder) private var rooms: [Room]

    @State private var projectInfos: [ProjectInfo] = []
    @State private var refreshTask: Task<Void, Never>?
    @State private var draggingRoomID: String?
    @State private var dropTargetRoomID: String?

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
                                    if let roomID = project.roomID,
                                       dropTargetRoomID == roomID,
                                       draggingRoomID != nil,
                                       draggingRoomID != roomID {
                                        Color.accentColor
                                            .frame(width: 3)
                                            .clipShape(Capsule())
                                            .offset(x: -8)
                                    }
                                }
                                .onDrag {
                                    if let roomID = project.roomID {
                                        draggingRoomID = roomID
                                        return NSItemProvider(object: roomID as NSString)
                                    }
                                    return NSItemProvider()
                                }
                                .onDrop(of: [UTType.text], isTargeted: dropBinding(for: project.roomID)) { providers in
                                    guard let targetID = project.roomID else { return false }
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
                let (todoTotal, todoDone) = await fetchTodoInfo(for: url)
                guard !Task.isCancelled else { return }
                projectInfos[i].gitBranch = branch
                projectInfos[i].uncommittedCount = changes
                projectInfos[i].todoTotal = todoTotal
                projectInfos[i].todoDone = todoDone
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

    private static let todoPattern = try! NSRegularExpression(pattern: #"^\s*-\s*\[( |x|X)\]"#, options: .anchorsMatchLines)

    private func fetchTodoInfo(for url: URL) async -> (Int?, Int?) {
        let pattern = Self.todoPattern
        return await Task.detached {
            let fm = FileManager.default
            var files: [URL] = []

            // Scan root-level .md files
            if let rootContents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: []) {
                for fileURL in rootContents {
                    let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    if !isDir && fileURL.pathExtension.lowercased() == "md" {
                        files.append(fileURL)
                    }
                }
            }

            // Scan .planning/ directory if it exists
            let planningDir = url.appendingPathComponent(".planning")
            if let planningContents = try? fm.contentsOfDirectory(at: planningDir, includingPropertiesForKeys: nil, options: []) {
                for fileURL in planningContents where fileURL.pathExtension.lowercased() == "md" {
                    files.append(fileURL)
                }
            }

            var total = 0
            var done = 0
            let maxSize: UInt64 = 100_000

            for file in files {
                guard let attrs = try? fm.attributesOfItem(atPath: file.path),
                      let size = attrs[.size] as? UInt64,
                      size <= maxSize,
                      let content = try? String(contentsOf: file, encoding: .utf8) else { continue }

                let range = NSRange(content.startIndex..., in: content)
                let matches = pattern.matches(in: content, range: range)
                total += matches.count
                for match in matches {
                    if let checkRange = Range(match.range(at: 1), in: content) {
                        let check = content[checkRange]
                        if check == "x" || check == "X" { done += 1 }
                    }
                }
            }

            return total > 0 ? (total, done) : (nil, nil)
        }.value
    }

    // MARK: - Reordering

    private func dropBinding(for roomID: String?) -> Binding<Bool> {
        Binding(
            get: { roomID != nil && dropTargetRoomID == roomID },
            set: { targeted in
                if targeted { dropTargetRoomID = roomID }
                else if dropTargetRoomID == roomID { dropTargetRoomID = nil }
            }
        )
    }

    private func handleReorderDrop(providers: [NSItemProvider], targetID: String) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let sourceID = item as? String else { return }
            Task { @MainActor in
                reorderRoom(sourceID: sourceID, beforeTargetID: targetID)
                draggingRoomID = nil
                dropTargetRoomID = nil
            }
        }
        return true
    }

    private func reorderRoom(sourceID: String, beforeTargetID: String) {
        var ordered = Array(rooms)
        guard let sourceIndex = ordered.firstIndex(where: { $0.id == sourceID }) else { return }
        let source = ordered.remove(at: sourceIndex)
        if let targetIndex = ordered.firstIndex(where: { $0.id == beforeTargetID }) {
            ordered.insert(source, at: targetIndex)
        } else {
            ordered.append(source)
        }
        for (index, room) in ordered.enumerated() {
            room.displayOrder = index
        }
        try? modelContext.save()
        buildProjectInfos()
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
