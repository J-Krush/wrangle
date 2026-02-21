import Foundation

enum SecurityScopedBookmark {
    /// Creates a bookmark for the given URL.
    /// Uses security-scoped bookmarks when sandboxed, regular bookmarks otherwise.
    static func create(for url: URL) throws -> Data {
        if isSandboxed {
            return try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } else {
            return try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        }
    }

    /// Resolves bookmark data back to a URL.
    /// Returns a tuple of (resolved URL, whether the bookmark was stale).
    static func resolve(_ data: Data) throws -> (URL, Bool) {
        var isStale = false
        if isSandboxed {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            _ = url.startAccessingSecurityScopedResource()
            return (url, isStale)
        } else {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (url, isStale)
        }
    }

    /// Detects whether the app is running in a sandbox.
    private static var isSandboxed: Bool {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
}
