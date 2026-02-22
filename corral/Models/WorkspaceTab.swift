//
//  WorkspaceTab.swift
//  corral
//

import Foundation
import SwiftUI

enum TabContent {
    case document(EditorDocument)
    case terminal(TerminalSession)
}

@Observable
class WorkspaceTab: Identifiable {
    let id = UUID()
    let content: TabContent
    var isPinned: Bool = false

    init(content: TabContent) {
        self.content = content
    }

    var displayName: String {
        switch content {
        case .document(let doc):
            return doc.fileName
        case .terminal(let session):
            return session.displayTitle
        }
    }

    var isDirty: Bool {
        switch content {
        case .document(let doc):
            return doc.isDirty
        case .terminal:
            return false
        }
    }

    var iconName: String {
        switch content {
        case .document(let doc):
            return doc.fileType.iconName
        case .terminal(let session):
            return session.iconName
        }
    }

    var iconColor: Color {
        switch content {
        case .document(let doc):
            return doc.fileType.iconColor
        case .terminal(let session):
            return session.iconColor
        }
    }

    var isTerminal: Bool {
        if case .terminal = content { return true }
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

    var isRunningTerminal: Bool {
        terminalSession?.isRunning ?? false
    }
}
