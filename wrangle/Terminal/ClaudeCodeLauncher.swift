//
//  ClaudeCodeLauncher.swift
//  wrangle
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
            return """
            echo ""
            echo "Claude Code CLI not found."
            echo "To install it using npm, run:"
            echo "  npm install -g @anthropic-ai/claude-code"
            echo ""
            echo "Or using Homebrew:"
            echo "  brew install anthropic-ai/claude-code/claude-code"
            echo ""
            echo "For more information, visit: https://claude.ai/cli"
            echo ""
            \n
            """
        }
    }

    /// Launches Claude Code in an already-running session by sending the command directly.
    static func launch(in session: TerminalSession) {
        session.emulator.send(launchCommand())
    }
}

enum GeminiCodeLauncher {
    /// Well-known installation paths for the Gemini CLI
    private static let knownPaths: [String] = [
        "/usr/local/bin/gemini",
        "/opt/homebrew/bin/gemini",
        NSString("~/.local/bin/gemini").expandingTildeInPath,
        NSString("~/.gemini/local/gemini").expandingTildeInPath
    ]

    /// Check if the `gemini` CLI is installed at any known path.
    static func isInstalled() -> Bool {
        knownPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    /// Returns the first path where the `gemini` binary exists, or nil if not found.
    static func geminiPath() -> String? {
        knownPaths.first { FileManager.default.fileExists(atPath: $0) }
    }

    /// Returns the command string to launch Gemini Code (including trailing newline).
    static func launchCommand() -> String {
        if let path = geminiPath() {
            return "\(path)\n"
        } else {
            return """
            echo ""
            echo "Gemini Code CLI not found."
            echo "To install it using npm, run:"
            echo "  npm install -g @google/gemini-cli"
            echo ""
            echo "For more information, visit: https://github.com/google-gemini/gemini-cli"
            echo ""
            \n
            """
        }
    }

    /// Launches Gemini Code in an already-running session by sending the command directly.
    static func launch(in session: TerminalSession) {
        session.emulator.send(launchCommand())
    }
}
