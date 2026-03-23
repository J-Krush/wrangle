//
//  BrowserTab.swift
//  Wrangle
//

import Foundation
import AppKit

// MARK: - Navigation Action

enum NavigationAction {
    case load(URL)
    case goBack
    case goForward
    case reload
    case stop
}

// MARK: - Console Message

struct ConsoleMessage: Identifiable {
    let id = UUID()
    let level: Level
    let text: String
    let timestamp: Date

    enum Level: String {
        case log, warn, error, info
    }
}

// MARK: - Browser Tab

@MainActor
@Observable
class BrowserTab: Identifiable {
    let id = UUID()
    var url: URL?
    var title: String = "New Tab"
    var favicon: NSImage?
    var isLoading: Bool = false
    var estimatedProgress: Double = 0
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var consoleMessages: [ConsoleMessage] = []
    var pendingNavigation: NavigationAction?

    init(url: URL? = nil) {
        self.url = url
        if let url {
            self.title = url.host() ?? url.absoluteString
        }
    }

    var displayTitle: String {
        if title.isEmpty || title == "New Tab" {
            return url?.host() ?? "New Tab"
        }
        return title
    }

    func clearConsole() {
        consoleMessages.removeAll()
    }
}
