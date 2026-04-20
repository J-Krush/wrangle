//
//  SidebarStorageKeys.swift
//  Wrangle
//
//  Canonical `@AppStorage` keys for sidebar section expansion state.
//  Convention: `sidebar.<section>.expanded` (global, not per-project).
//  Nested sub-sections append the sub-segment.
//
//  Phase 12 / UIX-22: all sidebar `@AppStorage` keys route through this
//  namespace to prevent drift.
//

import Foundation

enum SidebarStorageKeys {
    static let locationsExpanded = "sidebar.locations.expanded"
    static let scratchPadsExpanded = "sidebar.scratchPads.expanded"
    static let browsersExpanded = "sidebar.browsers.expanded"
    static let otherSessionsExpanded = "sidebar.otherSessions.expanded"
    static let browserBookmarksExpanded = "sidebar.browsers.bookmarks.expanded"
}
