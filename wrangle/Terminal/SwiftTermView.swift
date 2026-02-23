//
//  SwiftTermView.swift
//  wrangle
//

@preconcurrency import SwiftTerm
import SwiftUI
import AppKit

/// Protocol allowing TerminalEmulator (state model) to delegate actions
/// to the SwiftTermView.Coordinator which owns the actual process.
@MainActor
protocol TerminalProcessController: AnyObject {
    func terminateProcess()
    func restartProcess(in directory: URL?)
    func sendString(_ string: String)
}

struct SwiftTermView: NSViewRepresentable {
    let session: TerminalSession

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        terminalView.processDelegate = context.coordinator
        context.coordinator.terminalView = terminalView

        // Apply theme
        context.coordinator.configureAppearance(terminalView)

        // Start the shell process
        context.coordinator.startProcess(in: terminalView)

        return terminalView
    }

    func updateNSView(_ terminalView: LocalProcessTerminalView, context: Context) {
        context.coordinator.configureAppearance(terminalView)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate, TerminalProcessController {
        let session: TerminalSession
        weak var terminalView: LocalProcessTerminalView?

        init(session: TerminalSession) {
            self.session = session
            super.init()
            session.emulator.processController = self
        }

        // MARK: - Process Lifecycle

        func startProcess(in terminalView: LocalProcessTerminalView) {
            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

            // Build environment inheriting parent's env
            var env = ProcessInfo.processInfo.environment
            env["TERM"] = "xterm-256color"
            env["LANG"] = "en_US.UTF-8"
            let envStrings = env.map { "\($0.key)=\($0.value)" }

            let currentDir = session.workingDirectory?.path(percentEncoded: false)

            terminalView.startProcess(
                executable: shell,
                args: ["-l"],
                environment: envStrings,
                currentDirectory: currentDir
            )

            session.emulator.isRunning = true

            // Send pending command (e.g., Claude Code launch) after shell initializes
            if let command = session.pendingCommand {
                session.pendingCommand = nil
                Task { @MainActor [weak terminalView] in
                    try? await Task.sleep(for: .milliseconds(500))
                    guard let data = command.data(using: .utf8) else { return }
                    terminalView?.process.send(data: ArraySlice(data))
                }
            }
        }

        func configureAppearance(_ terminalView: LocalProcessTerminalView) {
            let theme = Theme.current
            terminalView.nativeBackgroundColor = theme.terminalBackground
            terminalView.selectedTextBackgroundColor = theme.terminalSelection
            terminalView.caretColor = theme.terminalCursor
            terminalView.font = theme.terminalFont
        }

        // MARK: - LocalProcessTerminalViewDelegate

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            Task { @MainActor in
                session.emulator.title = title
            }
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            guard let dir = directory else { return }
            Task { @MainActor in
                session.emulator.workingDirectory = URL(fileURLWithPath: dir)
                session.updateDetectedClaudeFile()
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            Task { @MainActor in
                session.emulator.isRunning = false
                session.handleProcessExit()
            }
        }

        // MARK: - TerminalProcessController

        func terminateProcess() {
            terminalView?.terminate()
        }

        func restartProcess(in directory: URL?) {
            terminateProcess()
            if let directory {
                session.emulator.workingDirectory = directory
            }
            if let tv = terminalView {
                startProcess(in: tv)
            }
        }

        func sendString(_ string: String) {
            guard let data = string.data(using: .utf8) else { return }
            terminalView?.process.send(data: ArraySlice(data))
        }
    }
}
