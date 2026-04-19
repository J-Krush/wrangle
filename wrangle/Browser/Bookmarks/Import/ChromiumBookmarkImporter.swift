//
//  ChromiumBookmarkImporter.swift
//  Wrangle
//
//  Parses Chrome / Brave bookmark JSON. Both are Chromium, same schema.
//

import Foundation

@MainActor
enum ChromiumBookmarkImporter {
    /// Locations for each Chromium-derived browser's profile root.
    static func profileRoot(for source: BookmarkImportSource) -> URL? {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let base = appSupport else { return nil }
        switch source {
        case .chrome:
            return base.appending(path: "Google/Chrome", directoryHint: .isDirectory)
        case .brave:
            return base.appending(path: "BraveSoftware/Brave-Browser", directoryHint: .isDirectory)
        default:
            return nil
        }
    }

    /// Enumerate available profiles (subdirectories containing a Bookmarks JSON file).
    static func profiles(for source: BookmarkImportSource) -> [ChromiumProfile] {
        guard let root = profileRoot(for: source),
              let contents = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return []
        }
        var result: [ChromiumProfile] = []
        for item in contents {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue else { continue }
            let bookmarks = item.appending(path: "Bookmarks")
            guard FileManager.default.fileExists(atPath: bookmarks.path) else { continue }
            let displayName = readProfileName(from: item) ?? item.lastPathComponent
            result.append(ChromiumProfile(
                directoryName: item.lastPathComponent,
                displayName: displayName,
                bookmarksPath: bookmarks
            ))
        }
        // Sort: Default first, then by name.
        result.sort { a, b in
            if a.directoryName == "Default" { return true }
            if b.directoryName == "Default" { return false }
            return a.directoryName < b.directoryName
        }
        return result
    }

    private static func readProfileName(from profileDir: URL) -> String? {
        // Chromium stores a profile's friendly name in Preferences JSON at
        // profile.name. If we can't read it, fall back to directory name.
        let prefsURL = profileDir.appending(path: "Preferences")
        guard let data = try? Data(contentsOf: prefsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = json["profile"] as? [String: Any],
              let name = profile["name"] as? String,
              !name.isEmpty else {
            return nil
        }
        return name
    }

    /// Parse a Chromium Bookmarks file and produce the folder tree.
    static func importBookmarks(from bookmarksPath: URL) throws -> ImportedFolder {
        let data: Data
        do {
            data = try Data(contentsOf: bookmarksPath)
        } catch {
            throw mappedReadError(from: error, path: bookmarksPath.path)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BookmarkImportError.parseFailure("Top-level JSON object expected.")
        }
        guard let roots = json["roots"] as? [String: Any] else {
            throw BookmarkImportError.parseFailure("\"roots\" key missing.")
        }

        // Root-level folders we care about. Order matches Chromium UI.
        let rootKeys = ["bookmark_bar", "other", "synced"]
        var topLevel: [ImportedFolder] = []
        for key in rootKeys {
            if let node = roots[key] as? [String: Any],
               let folder = parseNode(node) as? ImportedFolder {
                topLevel.append(folder)
            }
        }

        if topLevel.isEmpty {
            throw BookmarkImportError.parseFailure("No recognizable root folders found.")
        }

        return ImportedFolder(name: "All Bookmarks", children: topLevel)
    }

    /// Returns either an ImportedFolder or an ImportedBookmark.
    private static func parseNode(_ node: [String: Any]) -> Any? {
        let type = node["type"] as? String
        let name = node["name"] as? String ?? "Untitled"

        switch type {
        case "url":
            guard let urlString = node["url"] as? String,
                  let url = URL(string: urlString) else { return nil }
            return ImportedBookmark(title: name, url: url, folderPath: [])
        case "folder":
            let childrenRaw = node["children"] as? [[String: Any]] ?? []
            var childFolders: [ImportedFolder] = []
            var childBookmarks: [ImportedBookmark] = []
            for childNode in childrenRaw {
                if let parsed = parseNode(childNode) {
                    if let bookmark = parsed as? ImportedBookmark {
                        childBookmarks.append(bookmark)
                    } else if let folder = parsed as? ImportedFolder {
                        childFolders.append(folder)
                    }
                }
            }
            return ImportedFolder(name: name, bookmarks: childBookmarks, children: childFolders)
        default:
            return nil
        }
    }

    private static func mappedReadError(from error: Error, path: String) -> BookmarkImportError {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain {
            switch nsError.code {
            case NSFileReadNoPermissionError, NSFileReadNoSuchFileError:
                return .fileNotFound(path: path)
            default:
                break
            }
        }
        return .parseFailure(error.localizedDescription)
    }
}

// MARK: - BookmarkImporter conformances

@MainActor
enum ChromeBookmarkImporter: BookmarkImporter {
    static let source: BookmarkImportSource = .chrome

    static func importBookmarks() throws -> ImportedFolder {
        let profiles = ChromiumBookmarkImporter.profiles(for: .chrome)
        guard let first = profiles.first else { throw BookmarkImportError.browserNotFound }
        return try ChromiumBookmarkImporter.importBookmarks(from: first.bookmarksPath)
    }
}

@MainActor
enum BraveBookmarkImporter: BookmarkImporter {
    static let source: BookmarkImportSource = .brave

    static func importBookmarks() throws -> ImportedFolder {
        let profiles = ChromiumBookmarkImporter.profiles(for: .brave)
        guard let first = profiles.first else { throw BookmarkImportError.browserNotFound }
        return try ChromiumBookmarkImporter.importBookmarks(from: first.bookmarksPath)
    }
}
