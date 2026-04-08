//
//  TerminalStateStore.swift
//  Wrangle
//

import Foundation

// MARK: - Codable State

struct TerminalSessionState: Codable {
    let wrangleSessionID: String
    let claudeSessionID: String?
    let projectName: String
    let workingDirectoryPath: String?
    let bookmarkID: String?
    let intentID: String?
    let isClaude: Bool
    let isGemini: Bool
    let customTitle: String?
    let emulatorTitle: String?
}

struct TerminalProjectState: Codable {
    let sessions: [TerminalSessionState]
}

// MARK: - State Store

enum TerminalStateStore {

    private static func key(for projectID: String) -> String {
        "terminal-state-\(projectID)"
    }

    static func save(sessions: [TerminalSession], forProject projectID: String) {
        let sessionStates = sessions.map { session in
            TerminalSessionState(
                wrangleSessionID: session.id.uuidString,
                claudeSessionID: session.claudeSessionID,
                projectName: session.projectName,
                workingDirectoryPath: (session.workingDirectory ?? session.emulator.workingDirectory)?.path(percentEncoded: false),
                bookmarkID: session.bookmarkID,
                intentID: session.intentID,
                isClaude: session.isClaude,
                isGemini: session.isGemini,
                customTitle: session.customTitle,
                emulatorTitle: session.emulator.title
            )
        }

        let state = TerminalProjectState(sessions: sessionStates)

        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key(for: projectID))
        }
    }

    static func restore(forProject projectID: String) -> [TerminalSessionState] {
        guard let data = UserDefaults.standard.data(forKey: key(for: projectID)),
              let state = try? JSONDecoder().decode(TerminalProjectState.self, from: data) else {
            return []
        }
        return state.sessions
    }

    static func clear(forProject projectID: String) {
        UserDefaults.standard.removeObject(forKey: key(for: projectID))
    }
}
