//
//  FeedbackHelper.swift
//  wrangle
//

import AppKit

enum FeedbackHelper {
    enum FeedbackType {
        case bug
        case feature
    }

    static func openFeedback(_ type: FeedbackType) {
        let base = "https://github.com/J-Krush/wrangle-feedback/issues/new"

        let title: String
        let labels: String
        let body: String

        let systemInfo = collectSystemInfo()

        switch type {
        case .bug:
            title = "[Bug] "
            labels = "bug"
            body = """
            **Describe the issue:**


            **Steps to reproduce:**
            1.

            **Expected behavior:**


            ---
            \(systemInfo)
            """
        case .feature:
            title = "[Feature] "
            labels = "enhancement"
            body = """
            **Describe the feature:**


            **Use case:**


            ---
            \(systemInfo)
            """
        }

        var components = URLComponents(string: base)!
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "labels", value: labels),
            URLQueryItem(name: "body", value: body),
        ]

        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    private static func collectSystemInfo() -> String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return "App: Wrangle v\(appVersion) (build \(buildNumber))\nmacOS: \(osVersion)"
    }
}
