//
//  TimelineTabSpan.swift
//  Wrangle
//
//  Represents a span of activity for a specific tab type within a room.
//  Used in room-mode timeline to show terminal/browser/document activity.

import SwiftUI

struct TimelineTabSpan: Identifiable {
    var id: String { "\(kind)-\(startMs)-\(label)" }
    let kind: TabSpanKind
    let label: String       // e.g. "npm dev", "localhost:3000", "index.ts"
    let startMs: Int64
    let endMs: Int64

    var color: Color {
        kind.color
    }
}

enum TabSpanKind: String {
    case document
    case terminal
    case terminalClaude = "terminal-claude"
    case terminalGemini = "terminal-gemini"
    case browser

    var color: Color {
        switch self {
        case .document:        .gray
        case .terminal:        .mint
        case .terminalClaude:  .orange
        case .terminalGemini:  .blue
        case .browser:         .blue.opacity(0.7)
        }
    }

    var displayName: String {
        switch self {
        case .document:        "file"
        case .terminal:        "terminal"
        case .terminalClaude:  "claude"
        case .terminalGemini:  "gemini"
        case .browser:         "browser"
        }
    }

    static func from(tabSnapshot: TabSnapshot) -> TabSpanKind {
        switch tabSnapshot.kind {
        case "terminal":
            if tabSnapshot.metadata["agent_type"] == "claude" { return .terminalClaude }
            if tabSnapshot.metadata["agent_type"] == "gemini" { return .terminalGemini }
            return .terminal
        case "browser":
            return .browser
        default:
            return .document
        }
    }
}
