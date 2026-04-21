import AppKit
import Foundation
import Testing
@testable import Wrangle

@MainActor
@Suite("LinkRouter")
struct LinkRouterTests {

    // MARK: - Helpers

    /// Spins up a minimal AppState instance for exercising the router. We don't
    /// assert on its state — these tests focus on the router's return value and
    /// the directory-resolution logic that happens before any opener runs.
    private func makeAppState() -> AppState {
        AppState()
    }

    /// Creates a scratch directory we can drop real files into so existence checks pass.
    private func scratchDir() throws -> URL {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LinkRouterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Scheme handling

    @Test("Empty / whitespace input returns false")
    func emptyInput() {
        let app = makeAppState()
        #expect(LinkRouter.open("", appState: app) == false)
        #expect(LinkRouter.open("   ", appState: app) == false)
    }

    @Test("Hash-only anchors are a no-op (return false, no crash)")
    func hashAnchor() {
        let app = makeAppState()
        #expect(LinkRouter.open("#section", appState: app) == false)
    }

    @Test("Missing file returns false and does not crash")
    func missingFile() throws {
        let app = makeAppState()
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let base = dir.appendingPathComponent("doc.md")
        #expect(LinkRouter.open("./does-not-exist.md", relativeTo: base, appState: app) == false)
    }

    // MARK: - Path resolution

    @Test("Relative path resolves against a file base URL's parent directory")
    func relativeAgainstFile() throws {
        let app = makeAppState()
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let target = dir.appendingPathComponent("sibling.md")
        try "hello".write(to: target, atomically: true, encoding: .utf8)
        let base = dir.appendingPathComponent("doc.md")

        #expect(LinkRouter.open("./sibling.md", relativeTo: base, appState: app) == true)
    }

    @Test("Relative path resolves against a directory base URL (terminal cwd)")
    func relativeAgainstDirectory() throws {
        let app = makeAppState()
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let target = dir.appendingPathComponent("file.md")
        try "hello".write(to: target, atomically: true, encoding: .utf8)

        // When `base` is a directory, router must NOT strip its last component.
        #expect(LinkRouter.open("./file.md", relativeTo: dir, appState: app) == true)
    }

    @Test("Parent-directory link resolves via ../")
    func parentRelative() throws {
        let app = makeAppState()
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let sub = dir.appendingPathComponent("sub", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let target = dir.appendingPathComponent("top.md")
        try "x".write(to: target, atomically: true, encoding: .utf8)

        let base = sub.appendingPathComponent("inner.md")
        #expect(LinkRouter.open("../top.md", relativeTo: base, appState: app) == true)
    }

    @Test("Absolute POSIX path resolves without a base")
    func absolutePath() throws {
        let app = makeAppState()
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let target = dir.appendingPathComponent("abs.md")
        try "x".write(to: target, atomically: true, encoding: .utf8)

        #expect(LinkRouter.open(target.path, appState: app) == true)
    }

    @Test("Percent-encoded relative path is decoded before resolution")
    func percentEncoded() throws {
        let app = makeAppState()
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let target = dir.appendingPathComponent("my notes.md")
        try "x".write(to: target, atomically: true, encoding: .utf8)
        let base = dir.appendingPathComponent("doc.md")

        #expect(LinkRouter.open("./my%20notes.md", relativeTo: base, appState: app) == true)
    }

    // MARK: - Scheme routing (doesn't actually open — we trust the branch is taken)

    @Test("http(s) URLs are considered handled (routed to browser)")
    func webURLHandled() {
        let app = makeAppState()
        // openURLInBrowser mutates AppState but without a real WebKit stack it's
        // a no-op apart from appending a tab; that's fine. We only assert that
        // the router reports it handled the link.
        #expect(LinkRouter.open("https://example.com", appState: app) == true)
        #expect(LinkRouter.open("http://example.com/page?q=1", appState: app) == true)
    }

    @Test("file:// URL routes to local opener and respects existence")
    func fileURLRouting() throws {
        let app = makeAppState()
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let target = dir.appendingPathComponent("f.md")
        try "x".write(to: target, atomically: true, encoding: .utf8)

        #expect(LinkRouter.open(target.absoluteString, appState: app) == true)

        let ghost = dir.appendingPathComponent("ghost.md")
        #expect(LinkRouter.open(ghost.absoluteString, appState: app) == false)
    }
}
