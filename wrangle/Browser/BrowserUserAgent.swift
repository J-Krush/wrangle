//
//  BrowserUserAgent.swift
//  Wrangle
//

import Foundation

enum BrowserUserAgentMode: String, CaseIterable, Identifiable {
    case safari
    case chrome
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .safari: return "Safari (Default)"
        case .chrome: return "Chrome-Identical"
        case .custom: return "Custom"
        }
    }
}

enum BrowserUserAgent {
    static let modeDefaultsKey = "browser.userAgentMode"
    static let customValueDefaultsKey = "browser.customUserAgent"

    /// `nil` means "let WKWebView use its default user agent" (Safari default).
    static func resolved() -> String? {
        let mode = currentMode
        switch mode {
        case .safari:
            return nil
        case .chrome:
            return chromeUserAgent
        case .custom:
            let custom = UserDefaults.standard.string(forKey: customValueDefaultsKey) ?? ""
            return custom.isEmpty ? nil : custom
        }
    }

    static var currentMode: BrowserUserAgentMode {
        guard let raw = UserDefaults.standard.string(forKey: modeDefaultsKey),
              let mode = BrowserUserAgentMode(rawValue: raw) else {
            return .safari
        }
        return mode
    }

    /// Recent Chrome-on-macOS UA — close enough for sites that sniff browser identity.
    static let chromeUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
}
