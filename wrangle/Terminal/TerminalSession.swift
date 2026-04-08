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
    var intentID: String?
    var isClaude: Bool
    var isGemini: Bool
    var customTitle: String?
    var needsAttention: Bool = false
    var sessionContext: SessionContext?

    /// Whether this session was restored from a previous app launch (not yet running).
    var isRestored: Bool = false

    /// Claude Code's internal session ID, captured from hook events. Used for `claude --resume`.
    var claudeSessionID: String?

    /// Whether this session was auto-detected as Claude (vs. explicitly launched)
    var wasAutoDetected: Bool = false

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

    private static let genericShells: Set<String> = ["bash", "zsh", "sh", "fish", "tcsh", "csh", "ksh", "dash"]

    var displayTitle: String {
        if let customTitle { return customTitle }
        if let title = sanitizedEmulatorTitle {
            return title
        }
        if let dir = workingDirectory ?? emulator.workingDirectory {
            return dir.lastPathComponent
        }
        return projectName
    }

    /// Returns the emulator's title as a subtitle when it differs from the display title
    /// and isn't a generic shell name. Captures plan names set via OSC escape sequences.
    var emulatorSubtitle: String? {
        guard isClaude || isGemini,
              let title = sanitizedEmulatorTitle,
              title != displayTitle else { return nil }
        return title
    }

    private var sanitizedEmulatorTitle: String? {
        guard let title = emulator.title, !title.isEmpty,
              !Self.genericShells.contains(title.lowercased()) else { return nil }
        guard isClaude || isGemini else { return title }
        let cleaned = title
            .replacingOccurrences(of: "✻ ", with: "")
            .replacingOccurrences(of: "✻", with: "")
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? nil : cleaned
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
        if isClaude { return "claude-logo-svg" }
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

    /// Upgrades a raw terminal session to a Claude Code session.
    func upgradeToClaudeSession() {
        guard !isClaude else { return }
        isClaude = true
        wasAutoDetected = true
        updateDetectedClaudeFile()
        refreshSessionContext()
    }

    /// Reverts an auto-detected Claude session back to a plain terminal.
    func downgradeFromClaudeSession() {
        guard wasAutoDetected else { return }
        isClaude = false
        wasAutoDetected = false
        sessionContext = nil
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
