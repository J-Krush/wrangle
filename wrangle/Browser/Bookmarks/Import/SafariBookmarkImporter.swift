//
//  SafariBookmarkImporter.swift
//  Wrangle
//
//  Reads Safari's ~/Library/Safari/Bookmarks.plist directly. macOS TCC
//  (File System Access) gates this file: without Full Disk Access, reading
//  fails with NSFileReadNoPermissionError — we surface a clear, actionable
//  message in that case.
//

import Foundation

@MainActor
enum SafariBookmarkImporter: BookmarkImporter {
    static let source: BookmarkImportSource = .safari

    static var bookmarksPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appending(path: "Library/Safari/Bookmarks.plist")
    }

    static func importBookmarks() throws -> ImportedFolder {
        let data: Data
        do {
            data = try Data(contentsOf: bookmarksPath)
        } catch {
            throw mapReadError(error)
        }

        guard let top = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw BookmarkImportError.parseFailure("Top-level plist dictionary expected.")
        }

        // Safari's layout: a top-level list with "Children" containing
        // named sub-lists ("BookmarksBar", "BookmarksMenu", reading list, etc.).
        guard let children = top["Children"] as? [[String: Any]] else {
            throw BookmarkImportError.parseFailure("Top-level Children array missing.")
        }

        let root = ImportedFolder(name: "All Bookmarks")
        for child in children {
            if let folder = parse(node: child, fallbackName: rootFolderName(child)) as? ImportedFolder {
                root.children.append(folder)
            }
        }
        if root.children.isEmpty {
            throw BookmarkImportError.parseFailure("No recognizable bookmark folders in Safari data.")
        }
        return root
    }

    /// Safari's root children have a "Title" string (e.g. "BookmarksBar") that we map to friendlier names.
    private static func rootFolderName(_ node: [String: Any]) -> String {
        let raw = (node["Title"] as? String) ?? "Folder"
        switch raw {
        case "BookmarksBar": return "Favorites"
        case "BookmarksMenu": return "Bookmarks Menu"
        case "com.apple.ReadingList": return "Reading List"
        default: return raw
        }
    }

    /// Returns either an ImportedFolder or ImportedBookmark (or nil for unrecognized types).
    private static func parse(node: [String: Any], fallbackName: String) -> Any? {
        let type = node["WebBookmarkType"] as? String
        switch type {
        case "WebBookmarkTypeLeaf":
            guard let urlString = node["URLString"] as? String,
                  let url = URL(string: urlString) else { return nil }
            let titleDict = node["URIDictionary"] as? [String: Any]
            let title = (titleDict?["title"] as? String)
                ?? (titleDict?["Title"] as? String)
                ?? url.host()
                ?? urlString
            return ImportedBookmark(title: title, url: url, folderPath: [])
        case "WebBookmarkTypeList":
            let name = (node["Title"] as? String).map { friendly($0) } ?? fallbackName
            let kids = node["Children"] as? [[String: Any]] ?? []
            let folder = ImportedFolder(name: name)
            for child in kids {
                if let parsed = parse(node: child, fallbackName: "Folder") {
                    if let b = parsed as? ImportedBookmark {
                        folder.bookmarks.append(b)
                    } else if let f = parsed as? ImportedFolder {
                        folder.children.append(f)
                    }
                }
            }
            return folder
        default:
            return nil
        }
    }

    private static func friendly(_ rawTitle: String) -> String {
        switch rawTitle {
        case "BookmarksBar": return "Favorites"
        case "BookmarksMenu": return "Bookmarks Menu"
        case "com.apple.ReadingList": return "Reading List"
        default: return rawTitle
        }
    }

    private static func mapReadError(_ error: Error) -> BookmarkImportError {
        let nsError = error as NSError
        // NSCocoaErrorDomain: 257 = NSFileReadNoPermissionError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoPermissionError {
            return .fullDiskAccessRequired
        }
        // POSIX EACCES (13) surfaces as domain NSPOSIXErrorDomain in some paths.
        if nsError.domain == NSPOSIXErrorDomain && nsError.code == 13 {
            return .fullDiskAccessRequired
        }
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoSuchFileError {
            return .fileNotFound(path: bookmarksPath.path)
        }
        return .parseFailure(error.localizedDescription)
    }
}
