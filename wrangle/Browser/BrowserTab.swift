//
//  BrowserTab.swift
//  Wrangle
//

import Foundation
import AppKit
import Security

// MARK: - Navigation Action

enum NavigationAction {
    case load(URL)
    case goBack
    case goForward
    case reload
    case reloadFromOrigin
    case stop
    case zoomIn
    case zoomOut
    case zoomReset
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

// MARK: - Security State

enum SecurityState: Equatable {
    case unknown      // Fresh tab, no URL yet
    case insecure     // HTTP
    case secure       // HTTPS, trust evaluated OK
    case invalid      // Trust evaluation failed
    case fileLocal    // file:// or about: — no security indicator

    var systemImage: String {
        switch self {
        case .secure: return "lock.fill"
        case .insecure: return "exclamationmark.triangle.fill"
        case .invalid: return "xmark.shield.fill"
        case .fileLocal: return "doc"
        case .unknown: return "globe"
        }
    }

    var shortDescription: String {
        switch self {
        case .secure: return "Secure"
        case .insecure: return "Not Secure"
        case .invalid: return "Certificate Error"
        case .fileLocal: return "Local"
        case .unknown: return "No site loaded"
        }
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

    // Security state
    var securityState: SecurityState = .unknown
    var serverTrust: SecTrust?

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
