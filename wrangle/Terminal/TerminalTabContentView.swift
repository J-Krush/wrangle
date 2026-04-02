//
//  TerminalTabContentView.swift
//  wrangle
//

import SwiftUI

struct TerminalTabContentView: View {
    let session: TerminalSession
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            SessionContextBar(session: session)

            // SwiftTerm handles both rendering and keyboard input.
            // Padding is applied inside TerminalContainerView via layout margins
            // so SwiftTerm's frame matches the reported terminal dimensions exactly.
            ZStack {
                SwiftTermView(session: session, isActive: appState.activeTab?.terminalSession?.id == session.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(Theme.current.terminalBackground))

                if session.isRestored && !session.isRunning {
                    restoredSessionOverlay
                }
            }

            terminalStatusBar
        }
        .background(Color(nsColor: Theme.chromeBackground))
    }

    // MARK: - Status Bar

    private var terminalStatusBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                if session.isCustomIcon {
                    Image(session.iconName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: session.isClaude ? 15 : 12, height: session.isClaude ? 15 : 12)
                        .foregroundStyle(session.iconColor)
                } else {
                    Image(systemName: session.iconName)
                        .font(.caption2)
                        .foregroundStyle(session.iconColor)
                }
                Text(session.isClaude ? "Claude Code" : (session.isGemini ? "Gemini Code" : "Terminal"))
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

            Button {
                switch appState.appearanceMode {
                case .system: appState.appearanceMode = .dark
                case .dark:   appState.appearanceMode = .light
                case .light:  appState.appearanceMode = .system
                }
            } label: {
                Image(systemName: appearanceIcon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(appearanceTooltip)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: Theme.chromeBackground))
    }

    // MARK: - Restored Session Overlay

    private var restoredSessionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: session.isClaude ? "arrow.clockwise.circle.fill" : "terminal.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Previous Session")
                .font(.headline)
                .foregroundStyle(.primary)

            if let claudeSID = session.claudeSessionID, session.isClaude {
                Button("Resume Claude Session") {
                    session.isRestored = false
                    session.pendingCommand = ClaudeCodeLauncher.resumeCommand(sessionID: claudeSID)
                    session.emulator.restart(in: session.workingDirectory)
                }
                .buttonStyle(.borderedProminent)
            }

            Button(session.isClaude ? "Start New Session" : "Start New Terminal") {
                session.isRestored = false
                if session.isClaude {
                    session.pendingCommand = ClaudeCodeLauncher.launchCommand()
                } else if session.isGemini {
                    session.pendingCommand = GeminiCodeLauncher.launchCommand()
                }
                session.emulator.restart(in: session.workingDirectory)
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }

    private var appearanceIcon: String {
        switch appState.appearanceMode {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max.fill"
        case .dark:   "moon.fill"
        }
    }

    private var appearanceTooltip: String {
        switch appState.appearanceMode {
        case .system: "Appearance: System"
        case .light:  "Appearance: Light"
        case .dark:   "Appearance: Dark"
        }
    }
}
