//
//  ClaudeCodeLauncher.swift
//  corral
//
//  Created by John Kreisher on 2/21/26.
//

import Foundation

enum ClaudeCodeLauncher {
    /// Well-known installation paths for the Claude CLI
    private static let knownPaths: [String] = [
        "/usr/local/bin/claude",
        "/opt/homebrew/bin/claude",
        NSString("~/.local/bin/claude").expandingTildeInPath,
        NSString("~/.claude/local/claude").expandingTildeInPath
    ]

    /// Check if the `claude` CLI is installed at any known path.
    static func isInstalled() -> Bool {
        knownPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    /// Returns the first path where the `claude` binary exists, or nil if not found.
    static func claudePath() -> String? {
        knownPaths.first { FileManager.default.fileExists(atPath: $0) }
    }

    /// Returns the command string to launch Claude Code (including trailing newline).
    static func launchCommand() -> String {
        if let path = claudePath() {
            return "\(path)\n"
        } else {
            return "echo 'Claude Code CLI not found. Install it from https://claude.ai/cli'\n"
        }
    }

    /// Launches Claude Code in an already-running session by sending the command directly.
    static func launch(in session: TerminalSession) {
        session.emulator.title = "Claude Code"
        session.emulator.send(launchCommand())
    }
}
