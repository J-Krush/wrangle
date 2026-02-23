//
//  TerminalSession.swift
//  wrangle
//

import Foundation
import SwiftUI

@MainActor
@Observable
class TerminalSession: Identifiable {
    let id = UUID()
    let emulator: TerminalEmulator
    let projectName: String
    let workingDirectory: URL?
    let bookmarkID: String?
    var isClaude: Bool
    var customTitle: String?

    /// Command to send after the shell process initializes (e.g., claude path).
    /// Consumed by SwiftTermView.Coordinator after process start.
    var pendingCommand: String?

    init(
        emulator: TerminalEmulator,
        projectName: String,
        workingDirectory: URL?,
        bookmarkID: String? = nil,
        isClaude: Bool = false
    ) {
        self.emulator = emulator
        self.projectName = projectName
        self.workingDirectory = workingDirectory
        self.bookmarkID = bookmarkID
        self.isClaude = isClaude
        updateDetectedClaudeFile()
    }

    var displayTitle: String {
        if let customTitle { return customTitle }
        if let dir = workingDirectory ?? emulator.workingDirectory {
            return dir.lastPathComponent
        }
        return projectName
    }

    var displaySubtitle: String? {
        guard let path = (workingDirectory ?? emulator.workingDirectory)?.path(percentEncoded: false) else { return nil }
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    var iconName: String {
        "terminal.fill"
    }

    var iconColor: Color {
        isClaude ? .orange : .mint
    }

    var isRunning: Bool {
        emulator.isRunning
    }

    /// Detected CLAUDE.md file in the working directory (updated asynchronously).
    var detectedClaudeFile: URL?

    /// Asynchronously scans the working directory for a CLAUDE.md file.
    func updateDetectedClaudeFile() {
        let dir = workingDirectory ?? emulator.workingDirectory
        guard let dir else {
            detectedClaudeFile = nil
            return
        }
        let candidates = ["CLAUDE.md", ".claude.md", ".claude/claude.md"]
        Task {
            let found = await Task.detached {
                candidates.lazy
                    .map { dir.appendingPathComponent($0) }
                    .first { FileManager.default.fileExists(atPath: $0.path) }
            }.value
            detectedClaudeFile = found
        }
    }

    func stop() {
        emulator.stop()
    }

    func restart() {
        emulator.restart(in: workingDirectory)
    }

    /// Called by SwiftTermView.Coordinator when the child process exits.
    func handleProcessExit() {
        // Process has exited — emulator.isRunning is already set to false by the coordinator.
        // Additional cleanup can be added here if needed.
    }
}
