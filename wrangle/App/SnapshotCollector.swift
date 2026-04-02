//
//  SnapshotCollector.swift
//  Wrangle
//
//  Assembles full workspace snapshots from AppState and sends them
//  to the Rust timeline engine. Handles both periodic (30s) and
//  event-driven snapshot capture.

import Foundation

@MainActor
@Observable
class SnapshotCollector {
    private var periodicTask: Task<Void, Never>?
    private weak var engineClient: EngineClient?
    weak var coordinator: AppCoordinator?
    private static let periodicInterval: Duration = .seconds(30)

    func start(engineClient: EngineClient) {
        self.engineClient = engineClient
        startPeriodicCapture()
    }

    func stop() {
        periodicTask?.cancel()
        periodicTask = nil
    }

    // MARK: - Event-Driven Capture

    /// Capture a snapshot immediately in response to a workspace event.
    func capture(from appState: AppState, eventType: String, notes: String? = nil) {
        guard let engineClient else { return }
        let snapshot = assembleSnapshot(from: appState, eventType: eventType, notes: notes)
        engineClient.recordSnapshot(snapshot)
    }

    // MARK: - Periodic Capture

    private func startPeriodicCapture() {
        periodicTask?.cancel()
        periodicTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.periodicInterval)
                guard !Task.isCancelled else { break }
                guard let self else { break }

                // Only capture if the app is in the foreground with a room selected
                guard let appState = self.findActiveAppState(),
                      appState.selectedRoomID != nil,
                      self.coordinator?.isAppForeground == true else { continue }

                self.capture(from: appState, eventType: "periodic")
            }
        }
    }

    /// Find the currently active AppState from the coordinator.
    /// Uses the first window state that has a selected room.
    private func findActiveAppState() -> AppState? {
        coordinator?.windowStates.values.first { $0.selectedRoomID != nil }
    }

    // MARK: - Snapshot Assembly

    func assembleSnapshot(
        from appState: AppState,
        eventType: String,
        notes: String? = nil
    ) -> WorkspaceSnapshot {
        let now = Int64(Date().timeIntervalSince1970 * 1000)

        let tabSnapshots = appState.visibleTabs.map { tab -> TabSnapshot in
            buildTabSnapshot(tab: tab, isActive: tab.id == appState.activeTab?.id)
        }

        let activeTabID = appState.activeTab?.id.uuidString

        // Build sidebar state
        let expandedBookmarks: [String]
        if let roomID = appState.selectedRoomID,
           let expanded = appState.roomExpandedBookmarks[roomID] {
            expandedBookmarks = Array(expanded)
        } else {
            expandedBookmarks = []
        }

        let sidebarState = SidebarSnapshot(
            expandedBookmarks: expandedBookmarks,
            selectedFile: appState.selectedFileTreeURL?.path
        )

        let workspace = WorkspaceState(
            tabs: tabSnapshots,
            activeTabID: activeTabID,
            sidebarState: sidebarState
        )

        return WorkspaceSnapshot(
            timestampMs: now,
            roomID: appState.selectedRoomID ?? "unknown",
            intentID: appState.activeIntentID,
            eventType: eventType,
            workspace: workspace,
            gitHead: nil, // TODO: read from git when available
            notes: notes
        )
    }

    private func buildTabSnapshot(tab: WorkspaceTab, isActive: Bool) -> TabSnapshot {
        switch tab.content {
        case .document(let doc):
            return TabSnapshot(
                id: tab.id.uuidString,
                kind: "document",
                filePath: doc.fileURL?.path,
                url: nil,
                title: doc.fileName,
                workingDir: nil,
                process: nil,
                metadata: [:],
                isActive: isActive
            )

        case .terminal(let session):
            var metadata: [String: String] = [:]
            if session.isClaude {
                metadata["agent_type"] = "claude"
                // Session ID will be populated when Claude session tracking is available
            }
            if session.isGemini {
                metadata["agent_type"] = "gemini"
            }
            if let intentID = session.intentID {
                metadata["intent_id"] = intentID
            }

            return TabSnapshot(
                id: tab.id.uuidString,
                kind: "terminal",
                filePath: nil,
                url: nil,
                title: session.displayTitle,
                workingDir: session.workingDirectory?.path,
                process: ProcessSnapshot(
                    pid: nil, // TerminalEmulator doesn't expose pid directly
                    command: session.isClaude ? "claude" : session.isGemini ? "gemini" : nil,
                    running: session.isRunning
                ),
                metadata: metadata,
                isActive: isActive
            )

        case .browser(let session):
            return TabSnapshot(
                id: tab.id.uuidString,
                kind: "browser",
                filePath: nil,
                url: session.activeTab?.url?.absoluteString,
                title: session.activeTab?.displayTitle,
                workingDir: nil,
                process: nil,
                metadata: [:],
                isActive: isActive
            )
        }
    }
}
