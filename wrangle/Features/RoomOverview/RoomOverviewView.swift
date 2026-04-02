import SwiftUI
import SwiftData

struct RoomOverviewView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \BookmarkedDirectory.displayOrder) private var allBookmarks: [BookmarkedDirectory]
    @Query(sort: \Intent.displayOrder) private var allIntents: [Intent]

    @State private var activeFilter: RoomOverviewFilter = .all

    private var roomID: String? { appState.selectedRoomID }

    private var bookmarks: [BookmarkedDirectory] {
        allBookmarks.filter { $0.roomID == roomID && !$0.isFile }
    }

    private var intents: [Intent] {
        allIntents.filter { $0.roomID == roomID }
    }

    private var roomName: String {
        // Room name isn't directly queryable without the Room object,
        // but we can get it from the tab or build it from context
        "Room Overview"
    }

    private var sessionItems: [RoomSessionItem] {
        // During playback, build items from the snapshot instead of live tabs
        if let playback = appState.timelinePlayback {
            return playbackSessionItems(from: playback.snapshot.workspace.tabs)
        }

        let roomTabs = appState.tabs.filter { $0.roomID == roomID }
        let bookmarkMap = Dictionary(
            uniqueKeysWithValues: bookmarks.map {
                ($0.persistentModelID.hashValue.description, $0.displayName)
            }
        )
        let intentMap = Dictionary(
            uniqueKeysWithValues: intents.map { ($0.id, $0.name) }
        )

        return roomTabs.compactMap { tab -> RoomSessionItem? in
            if let session = tab.terminalSession {
                let sessionType: RoomSessionItem.SessionType
                if session.isClaude { sessionType = .claudeAgent }
                else if session.isGemini { sessionType = .geminiAgent }
                else { sessionType = .terminal }

                let agentStatus = resolveAgentStatus(session)

                return RoomSessionItem(
                    id: tab.id,
                    sessionType: sessionType,
                    displayTitle: session.displayTitle,
                    subtitle: session.displaySubtitle,
                    iconName: session.iconName,
                    iconColor: session.iconColor,
                    isCustomIcon: session.isCustomIcon,
                    agentStatus: agentStatus,
                    isRunning: session.isRunning,
                    needsAttention: session.needsAttention,
                    locationName: session.bookmarkID.flatMap { bookmarkMap[$0] },
                    locationID: session.bookmarkID,
                    intentName: session.intentID.flatMap { intentMap[$0] },
                    intentID: session.intentID,
                    tabCount: nil
                )
            } else if let session = tab.browserSession {
                return RoomSessionItem(
                    id: tab.id,
                    sessionType: .browser,
                    displayTitle: session.displayTitle,
                    subtitle: session.activeTab?.url?.host(),
                    iconName: session.iconName,
                    iconColor: session.iconColor,
                    isCustomIcon: false,
                    agentStatus: .none,
                    isRunning: true,
                    needsAttention: false,
                    locationName: session.bookmarkID.flatMap { bookmarkMap[$0] },
                    locationID: session.bookmarkID,
                    intentName: session.intentID.flatMap { intentMap[$0] },
                    intentID: session.intentID,
                    tabCount: session.tabs.count
                )
            }
            return nil
        }
    }

    /// Build session items from a timeline snapshot's tab data.
    private func playbackSessionItems(from tabs: [TabSnapshot]) -> [RoomSessionItem] {
        tabs.map { tab in
            let sessionType: RoomSessionItem.SessionType
            let iconName: String
            let iconColor: Color
            let isCustomIcon: Bool
            let subtitle: String?

            switch tab.kind {
            case "terminal":
                if tab.metadata["agent_type"] == "claude" {
                    sessionType = .claudeAgent
                    iconName = "custom.claude-icon"
                    iconColor = .orange
                    isCustomIcon = true
                } else if tab.metadata["agent_type"] == "gemini" {
                    sessionType = .geminiAgent
                    iconName = "custom.gemini-icon"
                    iconColor = .blue
                    isCustomIcon = true
                } else {
                    sessionType = .terminal
                    iconName = "terminal"
                    iconColor = .mint
                    isCustomIcon = false
                }
                subtitle = tab.workingDir.flatMap { URL(fileURLWithPath: $0).lastPathComponent }
            case "browser":
                sessionType = .browser
                iconName = "globe"
                iconColor = .blue
                isCustomIcon = false
                subtitle = tab.url
            default:
                sessionType = .terminal
                iconName = "doc.text"
                iconColor = .gray
                isCustomIcon = false
                subtitle = tab.filePath
            }

            let isRunning = tab.process?.running ?? (tab.kind != "document")

            return RoomSessionItem(
                id: UUID(),
                sessionType: sessionType,
                displayTitle: tab.title ?? "untitled",
                subtitle: subtitle,
                iconName: iconName,
                iconColor: iconColor,
                isCustomIcon: isCustomIcon,
                agentStatus: isRunning && sessionType.isAgent ? .running(0) : .none,
                isRunning: isRunning,
                needsAttention: false,
                locationName: nil,
                locationID: nil,
                intentName: nil,
                intentID: tab.metadata["intent_id"],
                tabCount: tab.kind == "browser" ? 1 : nil
            )
        }
    }

    private var filteredItems: [RoomSessionItem] {
        switch activeFilter {
        case .all:
            return sessionItems
        case .agents:
            return sessionItems.filter { $0.sessionType.isAgent }
        case .terminals:
            return sessionItems.filter { $0.sessionType == .terminal }
        case .browsers:
            return sessionItems.filter { $0.sessionType == .browser }
        case .location(let id):
            return sessionItems.filter { $0.locationID == id }
        case .intent(let id):
            return sessionItems.filter { $0.intentID == id }
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 32)

            if !sessionItems.isEmpty {
                RoomOverviewFilterBar(
                    items: sessionItems,
                    bookmarks: bookmarks,
                    intents: intents,
                    activeFilter: $activeFilter
                )
                .padding(.top, 12)
            }

            if filteredItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredItems) { item in
                            RoomSessionCardView(item: item)
                                .onTapGesture { navigateToTab(item.id) }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: Theme.chromeBackground))
        .id(roomID)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var summaryText: String {
        let agents = sessionItems.filter { $0.sessionType.isAgent }.count
        let terminals = sessionItems.filter { $0.sessionType == .terminal }.count
        let browsers = sessionItems.filter { $0.sessionType == .browser }.count
        var parts: [String] = []
        if agents > 0 { parts.append("\(agents) agent\(agents == 1 ? "" : "s")") }
        if terminals > 0 { parts.append("\(terminals) terminal\(terminals == 1 ? "" : "s")") }
        if browsers > 0 { parts.append("\(browsers) browser\(browsers == 1 ? "" : "s")") }
        return parts.isEmpty ? "No active sessions" : parts.joined(separator: " · ")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No active sessions")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open a terminal or browser to see it here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func navigateToTab(_ tabID: UUID) {
        appState.viewMode = .editor
        if let globalIndex = appState.tabs.firstIndex(where: { $0.id == tabID }) {
            appState.activeTabIndex = globalIndex
        }
    }

    private func resolveAgentStatus(_ session: TerminalSession) -> AgentStatus {
        if (session.isClaude || session.isGemini) && session.isRunning {
            if session.needsAttention {
                return .waiting
            }
            return .running(0)
        }
        if session.isRunning {
            return .idle
        }
        return .none
    }
}
