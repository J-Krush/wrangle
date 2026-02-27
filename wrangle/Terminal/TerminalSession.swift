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
    var isGemini: Bool
    var customTitle: String?
    var needsAttention: Bool = false
    var sessionContext: SessionContext?

    /// Command to send after the shell process initializes (e.g., claude path).
    /// Consumed by SwiftTermView.Coordinator after process start.
    var pendingCommand: String?

    init(
        emulator: TerminalEmulator,
        projectName: String,
        workingDirectory: URL?,
        bookmarkID: String? = nil,
        isClaude: Bool = false,
        isGemini: Bool = false
    ) {
        self.emulator = emulator
        self.projectName = projectName
        self.workingDirectory = workingDirectory
        self.bookmarkID = bookmarkID
        self.isClaude = isClaude
        self.isGemini = isGemini
        updateDetectedClaudeFile()
        refreshSessionContext()
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
        if isClaude { return "claude-logo" }
        if isGemini { return "google-g-logo" }
        return "terminal.fill"
    }
    
    var isCustomIcon: Bool {
        isClaude || isGemini
    }

    var iconColor: Color {
        if isClaude { return .orange }
        if isGemini { return .blue }
        return .mint
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

    func refreshSessionContext() {
        guard isClaude || isGemini else { return }
        if sessionContext == nil { sessionContext = SessionContext() }
        let dir = workingDirectory ?? emulator.workingDirectory
        sessionContext?.refresh(for: dir, isClaude: isClaude, isGemini: isGemini)
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
