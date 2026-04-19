//
//  BrowserBookmark.swift
//  Wrangle
//

import Foundation
import SwiftData

@Model
final class BrowserBookmark {
    /// Stable identifier for cross-reference (e.g., New Tab page recents).
    @Attribute(.unique) var id: String
    var title: String
    var urlString: String
    /// Corresponds to `BrowserBookmarkFolder.id`. `nil` = "Unfiled" top-level.
    var folderID: String?
    /// `nil` = global bookmark (visible in every project).
    var projectID: String?
    /// Raw PNG bytes of the favicon if available.
    var faviconData: Data?
    var dateAdded: Date
    /// Free-form note field for the user (reserved for future use).
    var note: String?

    init(
        id: String = UUID().uuidString,
        title: String,
        urlString: String,
        folderID: String? = nil,
        projectID: String? = nil,
        faviconData: Data? = nil,
        dateAdded: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.folderID = folderID
        self.projectID = projectID
        self.faviconData = faviconData
        self.dateAdded = dateAdded
        self.note = note
    }

    var url: URL? {
        URL(string: urlString)
    }

    /// Normalized URL string used for dedupe — strips fragment, normalizes host.
    static func normalizedKey(for urlString: String) -> String {
        guard var components = URLComponents(string: urlString) else { return urlString }
        components.fragment = nil
        components.host = components.host?.lowercased()
        // Drop default ports
        if (components.scheme == "http" && components.port == 80)
            || (components.scheme == "https" && components.port == 443) {
            components.port = nil
        }
        return components.url?.absoluteString ?? urlString
    }
}
