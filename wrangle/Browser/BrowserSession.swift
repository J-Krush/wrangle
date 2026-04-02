//
//  BrowserSession.swift
//  Wrangle
//

import Foundation
import SwiftUI
import WebKit

enum DevToolType: String, CaseIterable {
    case console = "Console"
    case cookies = "Cookies"
    case network = "Network"
    case elements = "Elements"
}

@MainActor
@Observable
class BrowserSession: Identifiable {
    let id = UUID()
    var bookmarkID: String?
    var intentID: String?
    var roomID: String?
    var tabs: [BrowserTab]
    var activeTabIndex: Int = 0
    var customTitle: String?
    var isDevToolsVisible: Bool = false
    var devToolsHeight: CGFloat = 250
    var activeDevTool: DevToolType = .console

    /// Set by the BrowserWebView Coordinator
    weak var controller: BrowserController?

    init(url: URL? = nil, bookmarkID: String? = nil, intentID: String? = nil, roomID: String? = nil) {
        let initialTab = BrowserTab(url: url)
        self.tabs = [initialTab]
        self.bookmarkID = bookmarkID
        self.intentID = intentID
        self.roomID = roomID
    }

    // MARK: - Computed Properties

    var activeTab: BrowserTab? {
        guard activeTabIndex >= 0, activeTabIndex < tabs.count else { return nil }
        return tabs[activeTabIndex]
    }

    var displayTitle: String {
        if let customTitle { return customTitle }
        return activeTab?.displayTitle ?? "Browser"
    }

    var iconName: String { "globe" }
    var iconColor: Color { .blue }

    // MARK: - Tab Management

    func addTab(url: URL? = nil) {
        let tab = BrowserTab(url: url)
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
    }

    func closeTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        tabs.remove(at: index)
        if tabs.isEmpty {
            // Keep at least one tab
            let blank = BrowserTab()
            tabs.append(blank)
            activeTabIndex = 0
        } else if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        } else if activeTabIndex > index {
            activeTabIndex -= 1
        }
    }

    func selectTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        activeTabIndex = index
    }

    func moveTab(from source: Int, to destination: Int) {
        guard source != destination,
              source >= 0, source < tabs.count,
              destination >= 0, destination < tabs.count else { return }
        let tab = tabs.remove(at: source)
        tabs.insert(tab, at: destination)
        if activeTabIndex == source {
            activeTabIndex = destination
        }
    }
}
