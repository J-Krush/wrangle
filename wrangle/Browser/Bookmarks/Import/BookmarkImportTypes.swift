//
//  BookmarkImportTypes.swift
//  Wrangle
//

import Foundation

/// Source browser to import bookmarks from.
enum BookmarkImportSource: String, CaseIterable, Identifiable {
    case safari
    case chrome
    case brave
    case firefox

    var id: String { rawValue }

    var label: String {
        switch self {
        case .safari: return "Safari"
        case .chrome: return "Chrome"
        case .brave: return "Brave"
        case .firefox: return "Firefox"
        }
    }

    var systemImage: String {
        switch self {
        case .safari: return "safari"
        case .chrome, .brave: return "globe"
        case .firefox: return "globe.badge.chevron.backward"
        }
    }
}

/// A bookmark, post-parse, ready for insertion.
struct ImportedBookmark: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    let folderPath: [String]    // path from root, e.g. ["Bookmarks Bar", "Work"]
}

/// A folder with its bookmarks, for the preview tree.
@MainActor
@Observable
final class ImportedFolder: Identifiable {
    let id = UUID()
    let name: String
    var isSelected: Bool
    var children: [ImportedFolder]
    var bookmarks: [ImportedBookmark]

    init(name: String, bookmarks: [ImportedBookmark] = [], children: [ImportedFolder] = [], isSelected: Bool = true) {
        self.name = name
        self.bookmarks = bookmarks
        self.children = children
        self.isSelected = isSelected
    }

    /// Recursive total count of bookmarks in this subtree (selection-aware).
    /// Unlike selection cascading, count descends into children regardless of
    /// the parent's own selection — a child folder can be selected even when
    /// its ancestor is not.
    func totalBookmarkCount(selectedOnly: Bool = false) -> Int {
        var count = (selectedOnly && !isSelected) ? 0 : bookmarks.count
        for child in children {
            count += child.totalBookmarkCount(selectedOnly: selectedOnly)
        }
        return count
    }

    /// Flatten into ImportedBookmark list, respecting per-folder selection.
    /// A folder contributes its own bookmarks only when `isSelected`, but we
    /// always descend into children so a checked subfolder still imports
    /// when its parent is unchecked.
    func flattenSelected(pathPrefix: [String] = []) -> [ImportedBookmark] {
        let path = pathPrefix + [name]
        var result: [ImportedBookmark] = []
        if isSelected {
            result = bookmarks.map { ImportedBookmark(title: $0.title, url: $0.url, folderPath: path) }
        }
        for child in children {
            result.append(contentsOf: child.flattenSelected(pathPrefix: path))
        }
        return result
    }

    /// Cascade selection to all descendants.
    func setSelected(_ selected: Bool) {
        isSelected = selected
        for child in children {
            child.setSelected(selected)
        }
    }
}

/// Errors an importer can report.
enum BookmarkImportError: Error, LocalizedError {
    case browserNotFound
    case fileNotFound(path: String)
    case fullDiskAccessRequired
    case parseFailure(String)
    case sqliteFailure(String)

    var errorDescription: String? {
        switch self {
        case .browserNotFound:
            return "That browser isn't installed, or its bookmark data couldn't be located."
        case .fileNotFound(let path):
            return "Bookmark file not found at \(path)."
        case .fullDiskAccessRequired:
            return "Wrangle needs Full Disk Access to read Safari bookmarks."
        case .parseFailure(let detail):
            return "Couldn't parse bookmarks file: \(detail)."
        case .sqliteFailure(let detail):
            return "Couldn't read Firefox bookmark database: \(detail)."
        }
    }

    /// Whether the UI should link out to TCC pane.
    var suggestsFullDiskAccess: Bool {
        if case .fullDiskAccessRequired = self { return true }
        return false
    }
}

/// Profile descriptor for Chromium-family browsers (multiple profiles per install).
struct ChromiumProfile: Identifiable, Hashable {
    let id = UUID()
    let directoryName: String      // e.g., "Default", "Profile 1"
    let displayName: String        // friendly name if we can read one; else directoryName
    let bookmarksPath: URL
}

/// Common protocol implemented by each browser-specific importer.
@MainActor
protocol BookmarkImporter {
    static var source: BookmarkImportSource { get }
    /// Import from the default location for this browser. May throw BookmarkImportError.
    static func importBookmarks() throws -> ImportedFolder
}
