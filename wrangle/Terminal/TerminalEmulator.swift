//
//  TerminalEmulator.swift
//  wrangle
//
//  Created by John Kreisher on 2/21/26.
//

import Foundation

/// Lightweight state model for a terminal session.
/// The actual PTY process is managed by SwiftTermView.Coordinator
/// which conforms to TerminalProcessController.
@MainActor
@Observable
class TerminalEmulator {
    var isRunning: Bool = false
    var workingDirectory: URL?
    var title: String?

    /// Bridge to the SwiftTermView.Coordinator that owns the actual process.
    /// Set during SwiftTermView.makeNSView.
    weak var processController: TerminalProcessController?

    func send(_ input: String) {
        processController?.sendString(input)
    }

    func stop() {
        processController?.terminateProcess()
        isRunning = false
    }

    func restart(in directory: URL? = nil) {
        let dir = directory ?? workingDirectory
        processController?.restartProcess(in: dir)
    }
}
