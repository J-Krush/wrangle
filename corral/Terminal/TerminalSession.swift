//
//  TerminalSession.swift
//  corral
//

import Foundation
import SwiftUI

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
    }

    var displayTitle: String {
        if let customTitle { return customTitle }
        if isClaude { return "Claude Code" }
        return emulator.title ?? projectName
    }

    var displaySubtitle: String? {
        (workingDirectory ?? emulator.workingDirectory)?.path(percentEncoded: false)
    }

    var iconName: String {
        isClaude ? "brain.head.profile" : "terminal.fill"
    }

    var iconColor: Color {
        isClaude ? .orange : .mint
    }

    var isRunning: Bool {
        emulator.isRunning
    }

    /// Scans the working directory for a CLAUDE.md file.
    var detectedClaudeFile: URL? {
        guard let dir = workingDirectory ?? emulator.workingDirectory else { return nil }
        let candidates = ["CLAUDE.md", ".claude.md", ".claude/claude.md"]
        for name in candidates {
            let url = dir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
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
