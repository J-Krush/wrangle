import Foundation
import SwiftUI

struct RoomSessionItem: Identifiable {
    let id: UUID
    let sessionType: SessionType
    let displayTitle: String
    let subtitle: String?
    let iconName: String
    let iconColor: Color
    let isCustomIcon: Bool
    let agentStatus: AgentStatus
    let isRunning: Bool
    let needsAttention: Bool
    let locationName: String?
    let locationID: String?
    let intentName: String?
    let intentID: String?
    /// Browser tab count (only for browser sessions)
    let tabCount: Int?

    enum SessionType: String, CaseIterable {
        case claudeAgent
        case geminiAgent
        case terminal
        case browser

        var label: String {
            switch self {
            case .claudeAgent: "Agents"
            case .geminiAgent: "Agents"
            case .terminal: "Terminals"
            case .browser: "Browsers"
            }
        }

        var isAgent: Bool {
            self == .claudeAgent || self == .geminiAgent
        }
    }
}

enum RoomOverviewFilter: Hashable {
    case all
    case agents
    case terminals
    case browsers
    case location(String)
    case intent(String)
}
