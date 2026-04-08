//
//  WorkspaceTab.swift
//  wrangle
//

import Foundation
import SwiftUI

enum TabContent {
    case document(EditorDocument)
    case terminal(TerminalSession)
    case browser(BrowserSession)
    case projectOverview(String) // projectID
}

@MainActor
@Observable
class WorkspaceTab: Identifiable {
    let id = UUID()
    let content: TabContent
    var isPinned: Bool = false
    var customName: String?
    var projectID: String?

    init(content: TabContent) {
        self.content = content
    }

    var displayName: String {
        switch content {
        case .document:
            if let customName { return customName }
            return document!.fileName
        case .terminal(let session):
            return session.displayTitle
        case .browser(let session):
            return session.displayTitle
        case .projectOverview:
            return customName ?? "Overview"
        }
    }

    var isDirty: Bool {
        switch content {
        case .document(let doc):
            return doc.isDirty
        case .terminal, .browser, .projectOverview:
            return false
        }
    }

    var iconName: String {
        switch content {
        case .document(let doc):
            return doc.fileType.iconName
        case .terminal(let session):
            return session.iconName
        case .browser(let session):
            return session.iconName
        case .projectOverview:
            return "square.grid.2x2"
        }
    }

    var isCustomIcon: Bool {
        if case .terminal(let session) = content {
            return session.isCustomIcon
        }
        return false
    }

    var iconColor: Color {
        switch content {
        case .document(let doc):
            return doc.fileType.iconColor
        case .terminal(let session):
            return session.iconColor
        case .browser(let session):
            return session.iconColor
        case .projectOverview:
            return .secondary
        }
    }

    var isTerminal: Bool {
        if case .terminal = content { return true }
        return false
    }

    var isBrowser: Bool {
        if case .browser = content { return true }
        return false
    }

    var document: EditorDocument? {
        if case .document(let doc) = content { return doc }
        return nil
    }

    var terminalSession: TerminalSession? {
        if case .terminal(let session) = content { return session }
        return nil
    }

    var browserSession: BrowserSession? {
        if case .browser(let session) = content { return session }
        return nil
    }

    var isRunningTerminal: Bool {
        terminalSession?.isRunning ?? false
    }

    var isProjectOverview: Bool {
        if case .projectOverview = content { return true }
        return false
    }

    var projectOverviewID: String? {
        if case .projectOverview(let id) = content { return id }
        return nil
    }
}
