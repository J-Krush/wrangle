//
//  BrowserStateStore.swift
//  Wrangle
//

import Foundation

// MARK: - Codable State

struct BrowserTabState: Codable {
    let url: String?
    let title: String
}

struct BrowserSessionState: Codable {
    let tabs: [BrowserTabState]
    let activeIndex: Int
    let bookmarkID: String?
    let intentID: String?
    let isDevToolsVisible: Bool
}

struct BrowserRoomState: Codable {
    let sessions: [BrowserSessionState]
}

// MARK: - State Store

enum BrowserStateStore {

    private static func key(for roomID: String) -> String {
        "browser-state-\(roomID)"
    }

    static func save(sessions: [BrowserSession], forRoom roomID: String) {
        let sessionStates = sessions.map { session in
            BrowserSessionState(
                tabs: session.tabs.map { tab in
                    BrowserTabState(
                        url: tab.url?.absoluteString,
                        title: tab.title
                    )
                },
                activeIndex: session.activeTabIndex,
                bookmarkID: session.bookmarkID,
                intentID: session.intentID,
                isDevToolsVisible: session.isDevToolsVisible
            )
        }

        let state = BrowserRoomState(sessions: sessionStates)

        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key(for: roomID))
        }
    }

    static func restore(forRoom roomID: String) -> [BrowserSessionState] {
        guard let data = UserDefaults.standard.data(forKey: key(for: roomID)),
              let state = try? JSONDecoder().decode(BrowserRoomState.self, from: data) else {
            return []
        }
        return state.sessions
    }

    static func clear(forRoom roomID: String) {
        UserDefaults.standard.removeObject(forKey: key(for: roomID))
    }
}
