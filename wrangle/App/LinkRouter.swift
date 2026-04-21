import AppKit
import Foundation

/// Routes a raw link string (from a markdown click or terminal OSC 8 hyperlink)
/// to the appropriate in-app opener instead of NSWorkspace.open.
///
/// - `http(s)://` → in-app browser tab
/// - `file://` + plain filesystem paths → editor tab if file, Finder reveal if folder
/// - Missing file → silent no-op
/// - Other schemes (mailto, ssh, …) → NSWorkspace.open fallback
@MainActor
enum LinkRouter {

    /// Returns `true` when the router handled the link (so NSTextView / SwiftTerm
    /// should suppress their default open behavior).
    @discardableResult
    static func open(
        _ raw: String,
        relativeTo base: URL? = nil,
        appState: AppState
    ) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        // In-document anchors — nothing to navigate to across files yet.
        if trimmed.hasPrefix("#") { return false }

        let lower = trimmed.lowercased()

        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            guard let url = URL(string: trimmed) else { return false }
            appState.openURLInBrowser(url)
            return true
        }

        if lower.hasPrefix("file://") {
            guard let url = URL(string: trimmed) else { return false }
            return openLocal(url: url, appState: appState)
        }

        if foreignScheme(of: trimmed) != nil {
            if let url = URL(string: trimmed) {
                NSWorkspace.shared.open(url)
                return true
            }
            return false
        }

        return openPath(trimmed, relativeTo: base, appState: appState)
    }

    // MARK: - Helpers

    /// Returns a scheme string iff `raw` starts with `scheme:` (not a filesystem path).
    /// Returns nil for plain paths, relative paths, and `./`, `../`, `/`, `~/` prefixes.
    private static func foreignScheme(of raw: String) -> String? {
        if raw.hasPrefix("./") || raw.hasPrefix("../") || raw.hasPrefix("/") || raw.hasPrefix("~") {
            return nil
        }
        guard let colonIdx = raw.firstIndex(of: ":") else { return nil }
        let prefix = raw[..<colonIdx]
        guard !prefix.isEmpty, prefix.first?.isLetter == true else { return nil }
        let ok = prefix.allSatisfy { ch in
            ch.isLetter || ch.isNumber || ch == "+" || ch == "-" || ch == "."
        }
        return ok ? String(prefix).lowercased() : nil
    }

    private static func openPath(
        _ rawPath: String,
        relativeTo base: URL?,
        appState: AppState
    ) -> Bool {
        // Strip percent-encoding if present (e.g. `./my%20notes.md`).
        let decoded = rawPath.removingPercentEncoding ?? rawPath

        // Expand ~ in leading position.
        let expanded: String
        if decoded.hasPrefix("~") {
            expanded = NSString(string: decoded).expandingTildeInPath
        } else {
            expanded = decoded
        }

        let resolved: URL
        if expanded.hasPrefix("/") {
            resolved = URL(fileURLWithPath: expanded).standardizedFileURL
        } else if let baseDir = directoryFor(base: base) {
            resolved = URL(fileURLWithPath: expanded, relativeTo: baseDir).standardizedFileURL
        } else {
            return false
        }
        return openLocal(url: resolved, appState: appState)
    }

    /// Accepts either a file URL (uses its parent) or a directory URL (uses it directly).
    /// Returns `nil` when `base` is nil.
    private static func directoryFor(base: URL?) -> URL? {
        guard let base else { return nil }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: base.path, isDirectory: &isDir), isDir.boolValue {
            return base
        }
        return base.deletingLastPathComponent()
    }

    private static func openLocal(url: URL, appState: AppState) -> Bool {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            return false
        }
        if isDir.boolValue {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            appState.openFile(url: url)
        }
        return true
    }
}
