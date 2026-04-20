//
//  OverviewStorageKeys.swift
//  Wrangle
//
//  Canonical `@AppStorage` keys for Project Overview card expansion state.
//  Convention: `overview.<section>.expanded.<projectID>` (per-project).
//  Nested sub-sections append the sub-segment.
//
//  Phase 12 / UIX-22: all overview expansion storage keys route through
//  this namespace to prevent drift.
//

import Foundation

enum OverviewStorageKeys {
    static func todosExpanded(_ projectID: String) -> String {
        "overview.todos.expanded.\(projectID)"
    }

    static func sessionsExpanded(_ projectID: String) -> String {
        "overview.sessions.expanded.\(projectID)"
    }

    static func browsersExpanded(_ projectID: String) -> String {
        "overview.browsers.expanded.\(projectID)"
    }

    static func documentsExpanded(_ projectID: String) -> String {
        "overview.documents.expanded.\(projectID)"
    }

    static func locationsExpanded(_ projectID: String) -> String {
        "overview.locations.expanded.\(projectID)"
    }
}
