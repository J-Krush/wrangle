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

struct BrowserProjectState: Codable {
    let sessions: [BrowserSessionState]
}

// MARK: - State Store

enum BrowserStateStore {

    private static func key(for projectID: String) -> String {
        "browser-state-\(projectID)"
    }

    static func save(sessions: [BrowserSession], forProject projectID: String) {
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

        let state = BrowserProjectState(sessions: sessionStates)

        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key(for: projectID))
        }
    }

    static func restore(forProject projectID: String) -> [BrowserSessionState] {
        guard let data = UserDefaults.standard.data(forKey: key(for: projectID)),
              let state = try? JSONDecoder().decode(BrowserProjectState.self, from: data) else {
            return []
        }
        return state.sessions
    }

    static func clear(forProject projectID: String) {
        UserDefaults.standard.removeObject(forKey: key(for: projectID))
    }
}
