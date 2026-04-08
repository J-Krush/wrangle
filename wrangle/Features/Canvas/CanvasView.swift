import SwiftUI
import SwiftData

struct CanvasView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]

    @State private var canvasState = CanvasState()
    @State private var projectInfos: [ProjectInfo] = []
    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            canvasToolbar
            Divider()
            canvasContent
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
    }

    // MARK: - Toolbar

    private var canvasToolbar: some View {
        HStack {
            Text("Canvas")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            // Zoom controls
            HStack(spacing: 8) {
                Button { canvasState.zoomOut() } label: {
                    Image(systemName: "minus")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Text("\(canvasState.zoomPercentage)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 36)

                Button { canvasState.zoomIn() } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 14)

                Button { canvasState.resetZoom() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Reset zoom & position")
            }

            Spacer()

            Text("\(projectInfos.count) projects")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: Theme.chromeBackground))
    }

    // MARK: - Canvas

    private var canvasContent: some View {
        GeometryReader { geo in
            ZStack {
                // Dot grid background
                canvasGrid(in: geo.size)

                // Project tiles
                ForEach(Array(projectInfos.enumerated()), id: \.element.id) { index, project in
                    let pos = canvasState.position(
                        for: project.id,
                        index: index,
                        total: projectInfos.count
                    )
                    CanvasProjectTile(
                        project: project,
                        position: pos,
                        onDragEnd: { newPos in
                            canvasState.updatePosition(for: project.id, to: newPos)
                        },
                        onDoubleTap: {
                            navigateToProject(project)
                        }
                    )
                }
            }
            .scaleEffect(canvasState.zoom)
            .offset(
                x: canvasState.panOffset.x,
                y: canvasState.panOffset.y
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        canvasState.zoom = min(2.0, max(0.3, canvasState.lastZoom * value))
                    }
                    .onEnded { _ in
                        canvasState.lastZoom = canvasState.zoom
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .modifiers(.command)
                    .onChanged { value in
                        canvasState.panOffset = CGPoint(
                            x: canvasState.lastPanOffset.x + value.translation.width,
                            y: canvasState.lastPanOffset.y + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        canvasState.lastPanOffset = canvasState.panOffset
                    }
            )
            .clipped()

            // Minimap
            minimapView(canvasSize: geo.size)
        }
        .background(canvasBackground)
    }

    private var canvasBackground: some View {
        Color(nsColor: NSColor(srgbRed: 26/255, green: 26/255, blue: 26/255, alpha: 1))
    }

    private func canvasGrid(in size: CGSize) -> some View {
        Canvas { context, size in
            let spacing: CGFloat = 24
            let dotSize: CGFloat = 1.5
            let color = Color.white.opacity(0.06)

            for x in stride(from: 0, to: size.width * 3, by: spacing) {
                for y in stride(from: 0, to: size.height * 3, by: spacing) {
                    let rect = CGRect(
                        x: x - size.width,
                        y: y - size.height,
                        width: dotSize,
                        height: dotSize
                    )
                    context.fill(Circle().path(in: rect), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Minimap

    private func minimapView(canvasSize: CGSize) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                minimapContent(canvasSize: canvasSize)
                    .frame(width: 120, height: 80)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    }
                    .padding(12)
            }
        }
    }

    private func minimapContent(canvasSize: CGSize) -> some View {
        GeometryReader { geo in
            let scale: CGFloat = 0.06
            ZStack {
                ForEach(Array(projectInfos.enumerated()), id: \.element.id) { index, project in
                    let pos = canvasState.position(
                        for: project.id,
                        index: index,
                        total: projectInfos.count
                    )
                    RoundedRectangle(cornerRadius: 1)
                        .fill(project.hasRunningAgent ? project.agentStatus.dotColor : Color.gray)
                        .frame(width: 18 * scale * 100, height: 11 * scale * 100)
                        .position(x: pos.x * scale + geo.size.width / 2,
                                  y: pos.y * scale + geo.size.height / 2)
                }

                // Viewport indicator
                RoundedRectangle(cornerRadius: 1)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                    .frame(
                        width: canvasSize.width * scale / canvasState.zoom,
                        height: canvasSize.height * scale / canvasState.zoom
                    )
                    .position(
                        x: geo.size.width / 2 - canvasState.panOffset.x * scale,
                        y: geo.size.height / 2 - canvasState.panOffset.y * scale
                    )
            }
        }
    }

    // MARK: - Data

    private func buildProjectInfos() {
        projectInfos = bookmarks.compactMap { bookmark -> ProjectInfo? in
            guard !bookmark.isFile else { return nil }
            let bookmarkID = bookmark.persistentModelID.hashValue.description
            let sessions = appState.terminalSessions(for: bookmarkID)
            let agentStatus = resolveAgentStatus(sessions)

            return ProjectInfo(
                id: bookmarkID,
                name: bookmark.displayName,
                url: bookmark.resolveURL(),
                bookmarkID: bookmarkID,
                projectID: bookmark.projectID,
                terminalSessions: sessions,
                agentStatus: agentStatus,
                lastActivity: bookmark.dateAdded
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
            let branch = try? canvasShellOutput("git -C \"\(path)\" rev-parse --abbrev-ref HEAD 2>/dev/null")
            let status = try? canvasShellOutput("git -C \"\(path)\" status --porcelain 2>/dev/null")
            let changeCount = status?.components(separatedBy: "\n").filter { !$0.isEmpty }.count
            return (branch?.trimmingCharacters(in: .whitespacesAndNewlines), changeCount)
        }.value
    }

    private func navigateToProject(_ project: ProjectInfo) {
        appState.selectedBookmarkID = project.bookmarkID
        appState.selectedProjectID = project.projectID
        appState.viewMode = .editor
    }
}

nonisolated private func canvasShellOutput(_ command: String) throws -> String {
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
