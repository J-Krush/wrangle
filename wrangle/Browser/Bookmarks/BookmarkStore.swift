//
//  BookmarkStore.swift
//  Wrangle
//

import Foundation
import SwiftData
import AppKit

@MainActor
struct BookmarkStore {
    let context: ModelContext

    // MARK: - Queries

    func existing(url: URL, projectID: String?) -> BrowserBookmark? {
        let key = BrowserBookmark.normalizedKey(for: url.absoluteString)
        let descriptor = FetchDescriptor<BrowserBookmark>()
        guard let all = try? context.fetch(descriptor) else { return nil }
        return all.first { bookmark in
            BrowserBookmark.normalizedKey(for: bookmark.urlString) == key
                && bookmark.projectID == projectID
        }
    }

    func isBookmarked(url: URL, projectID: String?) -> Bool {
        existing(url: url, projectID: projectID) != nil
    }

    func bookmarks(forProject projectID: String?) -> [BrowserBookmark] {
        let descriptor = FetchDescriptor<BrowserBookmark>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        guard let all = try? context.fetch(descriptor) else { return [] }
        // Show bookmarks scoped to this project + global bookmarks (projectID == nil).
        return all.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    func folders(forProject projectID: String?) -> [BrowserBookmarkFolder] {
        let descriptor = FetchDescriptor<BrowserBookmarkFolder>(
            sortBy: [SortDescriptor(\.displayOrder), SortDescriptor(\.name)]
        )
        guard let all = try? context.fetch(descriptor) else { return [] }
        return all.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    // MARK: - Mutations

    @discardableResult
    func addOrUpdate(
        title: String,
        url: URL,
        folderID: String? = nil,
        projectID: String?,
        favicon: NSImage? = nil
    ) -> BrowserBookmark {
        if let existing = existing(url: url, projectID: projectID) {
            existing.title = title
            if folderID != nil { existing.folderID = folderID }
            if let favicon {
                existing.faviconData = faviconPNGData(for: favicon)
            }
            try? context.save()
            return existing
        }

        let bookmark = BrowserBookmark(
            title: title,
            urlString: url.absoluteString,
            folderID: folderID,
            projectID: projectID,
            faviconData: faviconPNGData(for: favicon),
            dateAdded: .now
        )
        context.insert(bookmark)
        try? context.save()
        return bookmark
    }

    func remove(_ bookmark: BrowserBookmark) {
        context.delete(bookmark)
        try? context.save()
    }

    func removeBookmark(url: URL, projectID: String?) {
        if let existing = existing(url: url, projectID: projectID) {
            context.delete(existing)
            try? context.save()
        }
    }

    func update(_ bookmark: BrowserBookmark, title: String, url: URL, folderID: String?) {
        bookmark.title = title
        bookmark.urlString = url.absoluteString
        bookmark.folderID = folderID
        try? context.save()
    }

    @discardableResult
    func createFolder(name: String, projectID: String?) -> BrowserBookmarkFolder {
        let folder = BrowserBookmarkFolder(name: name, projectID: projectID)
        context.insert(folder)
        try? context.save()
        return folder
    }

    // MARK: - Helpers

    private func faviconPNGData(for image: NSImage?) -> Data? {
        guard let image else { return nil }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
