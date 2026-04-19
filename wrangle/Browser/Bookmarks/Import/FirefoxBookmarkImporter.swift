//
//  FirefoxBookmarkImporter.swift
//  Wrangle
//
//  Reads Firefox's places.sqlite bookmark tree. Because Firefox holds
//  places.sqlite open with WAL while running, we copy the file to a temp
//  directory first and open read-only.
//

import Foundation
import SQLite3

@MainActor
enum FirefoxBookmarkImporter: BookmarkImporter {
    static let source: BookmarkImportSource = .firefox

    static func importBookmarks() throws -> ImportedFolder {
        guard let profilePath = defaultProfilePath() else {
            throw BookmarkImportError.browserNotFound
        }
        let places = profilePath.appending(path: "places.sqlite")
        guard FileManager.default.fileExists(atPath: places.path) else {
            throw BookmarkImportError.fileNotFound(path: places.path)
        }
        let temp = try copyToTemp(originalProfile: profilePath)
        defer { try? FileManager.default.removeItem(at: temp) }
        return try readTree(from: temp.appending(path: "places.sqlite"))
    }

    // MARK: - Profile Discovery

    static func defaultProfilePath() -> URL? {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let base = appSupport else { return nil }
        let firefox = base.appending(path: "Firefox")
        let profilesIni = firefox.appending(path: "profiles.ini")

        // Try profiles.ini to find the default profile
        if let iniData = try? String(contentsOf: profilesIni, encoding: .utf8) {
            if let relativePath = parseProfilesIni(iniData) {
                let resolved = firefox.appending(path: relativePath)
                if FileManager.default.fileExists(atPath: resolved.path) {
                    return resolved
                }
            }
        }

        // Fallback: pick any directory under Profiles/ that contains places.sqlite
        let profilesDir = firefox.appending(path: "Profiles")
        if let contents = try? FileManager.default.contentsOfDirectory(at: profilesDir, includingPropertiesForKeys: nil) {
            for candidate in contents {
                if FileManager.default.fileExists(atPath: candidate.appending(path: "places.sqlite").path) {
                    return candidate
                }
            }
        }
        return nil
    }

    private static func parseProfilesIni(_ text: String) -> String? {
        // Look for default=1 or Default=1 block, read its Path= line.
        // profiles.ini has blocks starting with [Section], then key=value pairs.
        var blocks: [[String: String]] = []
        var current: [String: String] = [:]
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                if !current.isEmpty { blocks.append(current); current = [:] }
            } else if let eq = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<eq])
                let value = String(trimmed[trimmed.index(after: eq)...])
                current[key] = value
            }
        }
        if !current.isEmpty { blocks.append(current) }

        // Prefer a Profile block with Default=1.
        for block in blocks {
            if let path = block["Path"], block["Default"] == "1" {
                return path
            }
        }
        // Fall back to Install block pointing to Default
        for block in blocks {
            if let defaultName = block["Default"] {
                return defaultName
            }
        }
        // Fall back: first Profile block with Path
        return blocks.compactMap { $0["Path"] }.first
    }

    // MARK: - Temp Copy

    private static func copyToTemp(originalProfile: URL) throws -> URL {
        let temp = FileManager.default.temporaryDirectory
            .appending(path: "wrangle-firefox-import-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)

        let files = ["places.sqlite", "places.sqlite-wal", "places.sqlite-shm"]
        for name in files {
            let source = originalProfile.appending(path: name)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let target = temp.appending(path: name)
            try FileManager.default.copyItem(at: source, to: target)
        }
        return temp
    }

    // MARK: - SQLite Read

    private static func readTree(from databasePath: URL) throws -> ImportedFolder {
        var db: OpaquePointer?
        // Open read-only with immutable=1 so SQLite doesn't try to acquire locks.
        let openString = "file:\(databasePath.path)?mode=ro&immutable=1"
        guard sqlite3_open_v2(openString, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK, let db else {
            if let db { sqlite3_close(db) }
            throw BookmarkImportError.sqliteFailure("Could not open database.")
        }
        defer { sqlite3_close(db) }

        // Select relevant rows: bookmarks (type=1) and folders (type=2), with URL joined.
        let sql = """
            SELECT b.id, b.type, b.parent, b.title, p.url, b.position
            FROM moz_bookmarks b
            LEFT JOIN moz_places p ON b.fk = p.id
            WHERE b.type IN (1, 2)
            ORDER BY b.parent, b.position
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            throw BookmarkImportError.sqliteFailure("Could not prepare query.")
        }
        defer { sqlite3_finalize(stmt) }

        struct Row {
            let id: Int64
            let type: Int32
            let parent: Int64
            let title: String
            let url: String?
        }
        var rows: [Row] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let type = sqlite3_column_int(stmt, 1)
            let parent = sqlite3_column_int64(stmt, 2)
            let title: String = {
                if let cString = sqlite3_column_text(stmt, 3) {
                    return String(cString: cString)
                }
                return ""
            }()
            let url: String? = {
                if let cString = sqlite3_column_text(stmt, 4) {
                    return String(cString: cString)
                }
                return nil
            }()
            rows.append(Row(id: id, type: type, parent: parent, title: title, url: url))
        }

        // Build the tree. Firefox known roots:
        //   1 = places root (hidden)
        //   2 = menu root ("Bookmarks Menu")
        //   3 = toolbar root ("Bookmarks Toolbar")
        //   4 = tags root (we skip)
        //   5 = unfiled root ("Other Bookmarks")
        //   6 = mobile root
        let rootIDs: Set<Int64> = [2, 3, 5, 6]
        let rootNames: [Int64: String] = [
            2: "Bookmarks Menu",
            3: "Bookmarks Toolbar",
            5: "Other Bookmarks",
            6: "Mobile Bookmarks",
        ]

        // Group children by parent id
        var childrenByParent: [Int64: [Row]] = [:]
        for row in rows {
            childrenByParent[row.parent, default: []].append(row)
        }

        func build(parent: Int64, fallbackName: String) -> ImportedFolder {
            let folder = ImportedFolder(name: fallbackName)
            let children = childrenByParent[parent] ?? []
            for child in children {
                if child.type == 1 {
                    if let urlString = child.url, let url = URL(string: urlString) {
                        let title = child.title.isEmpty ? (url.host() ?? urlString) : child.title
                        folder.bookmarks.append(ImportedBookmark(title: title, url: url, folderPath: []))
                    }
                } else if child.type == 2 {
                    let name = child.title.isEmpty ? "Folder" : child.title
                    folder.children.append(build(parent: child.id, fallbackName: name))
                }
            }
            return folder
        }

        let root = ImportedFolder(name: "All Bookmarks")
        for id in rootIDs {
            if childrenByParent[id] != nil {
                let folder = build(parent: id, fallbackName: rootNames[id] ?? "Folder")
                if folder.bookmarks.isEmpty && folder.children.isEmpty { continue }
                root.children.append(folder)
            }
        }

        if root.children.isEmpty {
            throw BookmarkImportError.parseFailure("No bookmarks found in Firefox database.")
        }
        return root
    }
}
