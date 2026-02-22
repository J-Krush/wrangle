//
//  SwiftTermView.swift
//  corral
//

@preconcurrency import SwiftTerm
import SwiftUI
import AppKit

/// Protocol allowing TerminalEmulator (state model) to delegate actions
/// to the SwiftTermView.Coordinator which owns the actual process.
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak terminalView] in
                    guard let data = command.data(using: .utf8) else { return }
                    terminalView?.process.send(data: ArraySlice(data))
                }
            }
        }

        func configureAppearance(_ terminalView: LocalProcessTerminalView) {
            let theme = Theme.current
            terminalView.nativeBackgroundColor = theme.terminalBackground
            terminalView.nativeForegroundColor = theme.terminalForeground
            terminalView.selectedTextBackgroundColor = theme.terminalSelection
            terminalView.caretColor = theme.terminalCursor
            terminalView.font = theme.terminalFont

            // Install 16 ANSI colors
            let stColors = theme.terminalAnsiColors.map { nsColor -> SwiftTerm.Color in
                let c = nsColor.usingColorSpace(.sRGB) ?? nsColor
                return SwiftTerm.Color(
                    red: UInt16(c.redComponent * 65535),
                    green: UInt16(c.greenComponent * 65535),
                    blue: UInt16(c.blueComponent * 65535)
                )
            }
            if stColors.count == 16 {
                terminalView.installColors(stColors)
            }
        }

        // MARK: - LocalProcessTerminalViewDelegate

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            session.emulator.title = title
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            if let dir = directory {
                session.emulator.workingDirectory = URL(fileURLWithPath: dir)
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            session.emulator.isRunning = false
            session.handleProcessExit()
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
