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
    var customName: String?

    var displayName: String { customName ?? name }

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
    /// If the bookmark is stale and `refreshIfStale` is true, attempts to recreate it.
    /// Pass `refreshIfStale: false` when calling from an `onChange` of `bookmarkData` to avoid an infinite loop.
    func resolveURL(refreshIfStale: Bool = true) -> URL? {
        do {
            let (url, isStale) = try SecurityScopedBookmark.resolve(bookmarkData)
            if isStale && refreshIfStale {
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
