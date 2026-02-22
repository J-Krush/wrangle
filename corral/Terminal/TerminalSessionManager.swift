//
//  TerminalSessionManager.swift
//  corral
//

import Foundation

@MainActor
@Observable
class TerminalSessionManager {
    var sessions: [String: TerminalEmulator] = [:]

    /// Returns existing session or creates a new one for the given bookmark ID.
    func getOrCreateSession(for bookmarkID: String, directory: URL?) -> TerminalEmulator {
        if let existing = sessions[bookmarkID] {
            return existing
        }
        let emulator = TerminalEmulator()
        emulator.workingDirectory = directory
        sessions[bookmarkID] = emulator
        return emulator
    }

    /// Stops and removes a specific session.
    func stopSession(_ id: String) {
        sessions[id]?.stop()
        sessions.removeValue(forKey: id)
    }

    /// Stops all running sessions.
    func stopAll() {
        for (_, emulator) in sessions {
            emulator.stop()
        }
        sessions.removeAll()
    }

    /// Restarts a session in its working directory.
    func restartSession(_ id: String, directory: URL?) {
        sessions[id]?.stop()
        sessions.removeValue(forKey: id)
        _ = getOrCreateSession(for: id, directory: directory)
    }

    /// IDs of all sessions that are currently running.
    var activeSessionIDs: [String] {
        sessions.filter { $0.value.isRunning }.map(\.key)
    }

    /// Whether there are any active sessions.
    var hasActiveSessions: Bool {
        sessions.values.contains { $0.isRunning }
    }
}
