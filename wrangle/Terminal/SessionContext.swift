//
//  SessionContext.swift
//  wrangle
//

import Foundation

// MARK: - Data Types

struct ContextFile: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let fileType: FileType
}

struct SkillEntry: Identifiable {
    let id = UUID()
    let name: String
    let source: String
    let sourceType: String
}

enum MCPServerStatus {
    case configured
    case unknown
}

struct MCPServer: Identifiable {
    let id = UUID()
    let name: String
    let command: String?
    let status: MCPServerStatus
}

// MARK: - Session Context Model

@MainActor
@Observable
class SessionContext {
    var contextFiles: [ContextFile] = []
    var skills: [SkillEntry] = []
    var mcpServers: [MCPServer] = []
    var isLoading: Bool = false

    private var refreshTask: Task<Void, Never>?

    func refresh(for directory: URL?, isClaude: Bool, isGemini: Bool) {
        refreshTask?.cancel()
        guard let directory else { return }

        isLoading = true

        refreshTask = Task {
            async let files = Task.detached {
                SessionContextParser.parseContextFiles(in: directory, isClaude: isClaude, isGemini: isGemini)
            }.value
            async let parsedSkills = Task.detached {
                SessionContextParser.parseSkills(in: directory, isClaude: isClaude, isGemini: isGemini)
            }.value
            async let parsedMCP = Task.detached {
                SessionContextParser.parseMCPServers(in: directory, isClaude: isClaude, isGemini: isGemini)
            }.value

            let (f, s, m) = await (files, parsedSkills, parsedMCP)

            guard !Task.isCancelled else { return }
            contextFiles = f
            skills = s
            mcpServers = m
            isLoading = false
        }
    }
}
