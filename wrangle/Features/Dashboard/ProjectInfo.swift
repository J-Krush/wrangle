import Foundation
import SwiftUI

enum AgentStatus {
    case running(count: Int)
    case waiting(count: Int)
    case idle
    case none

    var displayText: String {
        switch self {
        case .running(let count):
            return count == 1 ? "1 agent running" : "\(count) agents running"
        case .waiting(let count):
            return count == 1 ? "1 agent waiting" : "\(count) agents waiting"
        case .idle:
            return "Idle"
        case .none:
            return "No agent"
        }
    }

    var dotColor: Color {
        switch self {
        case .running: .green
        case .waiting: .yellow
        case .idle: Color(.systemGray)
        case .none: Color(.systemGray).opacity(0.4)
        }
    }

    var isActive: Bool {
        switch self {
        case .running, .waiting: true
        default: false
        }
    }
}

struct ProjectInfo: Identifiable {
    let id: String
    let name: String
    let url: URL?
    let bookmarkID: String
    let projectID: String?
    var terminalSessions: [TerminalSession]
    var agentStatus: AgentStatus
    var gitBranch: String?
    var uncommittedCount: Int?
    var todoTotal: Int?
    var todoDone: Int?
    var lastActivity: Date?

    var hasRunningAgent: Bool {
        agentStatus.isActive
    }

    var activeTerminalCount: Int {
        terminalSessions.filter(\.isRunning).count
    }

    var lastActivityText: String {
        guard let date = lastActivity else { return "" }
        let interval = Date.now.timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}
