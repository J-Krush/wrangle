import Foundation
import SwiftData

@Model
final class BookmarkedDirectory {
    var name: String
    var bookmarkData: Data
    var displayOrder: Int
    var iconColorHex: String
    var dateAdded: Date
    var isFile: Bool

    init(
        name: String,
        bookmarkData: Data,
        displayOrder: Int = 0,
        iconColorHex: String = "#007AFF",
        dateAdded: Date = .now,
        isFile: Bool = false
    ) {
        self.name = name
        self.bookmarkData = bookmarkData
        self.displayOrder = displayOrder
        self.iconColorHex = iconColorHex
        self.dateAdded = dateAdded
        self.isFile = isFile
    }

    /// Resolves bookmark data back to a URL.
    /// If the bookmark is stale, attempts to recreate it.
    func resolveURL() -> URL? {
        do {
            let (url, isStale) = try SecurityScopedBookmark.resolve(bookmarkData)
            if isStale {
                if let newData = try? SecurityScopedBookmark.create(for: url) {
                    bookmarkData = newData
                }
            }
            return url
        } catch {
            return nil
        }
    }
}
