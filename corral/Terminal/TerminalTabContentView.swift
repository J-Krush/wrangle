//
//  TerminalTabContentView.swift
//  corral
//

import SwiftUI

struct TerminalTabContentView: View {
    let session: TerminalSession
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            contextHeader

            Divider()

            // SwiftTerm handles both rendering and keyboard input
            SwiftTermView(session: session)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            terminalStatusBar
        }
        .background(Theme.current.editorBackgroundColor)
    }

    // MARK: - Context Header

    private var contextHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: session.iconName)
                .font(.title3)
                .foregroundStyle(session.iconColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                if let subtitle = session.displaySubtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }

            Spacer()

            if let claudeFile = session.detectedClaudeFile {
                Button {
                    appState.openFile(url: claudeFile)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                        Text("CLAUDE.md")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15))
                    .cornerRadius(4)
                }
                .buttonStyle(.borderless)
                .help("Open CLAUDE.md")
            }

            if session.isRunning {
                Button {
                    session.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .help("Stop terminal")
            } else {
                Button {
                    session.restart()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Restart terminal")
            }

            // Trash button — immediately stops and closes tab
            Button {
                session.stop()
                if let index = appState.tabIndex(for: session) {
                    appState.closeTab(at: index)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Close terminal")

            if !session.isClaude && ClaudeCodeLauncher.isInstalled() {
                Button {
                    ClaudeCodeLauncher.launch(in: session)
                    session.isClaude = true
                } label: {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.borderless)
                .help("Launch Claude Code")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Status Bar

    private var terminalStatusBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: session.iconName)
                    .font(.caption2)
                    .foregroundStyle(session.iconColor)
                Text(session.isClaude ? "Claude Code" : "Terminal")
                    .font(.caption2)
            }

            Divider()
                .frame(height: 12)

            HStack(spacing: 4) {
                Circle()
                    .fill(session.isRunning ? .green : .gray)
                    .frame(width: 6, height: 6)
                Text(session.isRunning ? "Running" : "Stopped")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let path = session.displaySubtitle {
                Text(path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Theme.current.editorBackgroundColor)
    }
}
