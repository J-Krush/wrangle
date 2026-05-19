import Foundation
import Testing
@testable import Wrangle

/// Tests for `WhatsNewManager.visibleEntries` filter behavior and
/// `dismiss()` regression guard. Gates the D-05 fresh-install filter
/// added in Plan 13-02 (`lastSeen == "0.0.0"` → entries must be
/// version >= "1.3.0" so v1.1.x / v1.2.0 history is not auto-shown to
/// brand-new installs).
///
/// **UserDefaults caveat:** `WhatsNewManager` reads `UserDefaults.standard`
/// directly via the `"WhatsNewManager.lastSeenVersion"` key. To avoid
/// cross-test pollution, every test snapshots the key in its body, sets
/// the value it needs, exercises the manager, and resets the key from a
/// `defer` block. If this proves fragile in CI, the recommended path is
/// to add a default-parameter `init(defaults: UserDefaults = .standard)`
/// to `WhatsNewManager` and inject a per-test suite — Plan 13-02 Task 1
/// `<behavior>` explicitly authorizes that refactor.
///
/// Note: the codebase uses Swift Testing (`@Suite` / `@Test`), not
/// XCTestCase. The plan referenced `MarkdownParserTests.swift` as a
/// template — that file also uses Swift Testing, so this file follows
/// the same idiom (deviation from the plan's XCTestCase wording, not
/// from the actual template file).
@MainActor
@Suite("WhatsNewManager.visibleEntries")
struct WhatsNewManagerTests {

    private static let lastSeenKey = "WhatsNewManager.lastSeenVersion"

    // MARK: - Test 1: fresh-install filter (D-05)

    @Test("Fresh install (lastSeen == 0.0.0) shows only entries >= 1.3.0")
    func freshInstallFiltersOlderEntries() {
        let original = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        defer { restoreLastSeen(original) }

        UserDefaults.standard.set("0.0.0", forKey: Self.lastSeenKey)
        let manager = WhatsNewManager()
        manager.showAll = false

        let visible = manager.visibleEntries
        let versions = visible.map { $0.version }

        // The v1.3.0 OSS entry must appear; v1.2.0 and v1.1.1 must not.
        #expect(versions.contains("1.3.0"), "Fresh install must surface v1.3.0 OSS entry")
        #expect(!versions.contains("1.2.0"), "Fresh install must filter out v1.2.0")
        #expect(!versions.contains("1.1.1"), "Fresh install must filter out v1.1.1")
    }

    // MARK: - Test 2: upgrading user keeps normal semver filter

    @Test("Upgrading v1.2.0 user sees only v1.3.0 (semver-newer-than)")
    func upgradingUserSeesOnlyNewer() {
        let original = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        defer { restoreLastSeen(original) }

        UserDefaults.standard.set("1.2.0", forKey: Self.lastSeenKey)
        let manager = WhatsNewManager()
        manager.showAll = false

        let visible = manager.visibleEntries
        let versions = visible.map { $0.version }

        #expect(versions.contains("1.3.0"), "Upgrading user must see v1.3.0")
        #expect(!versions.contains("1.2.0"), "Upgrading user must not re-see v1.2.0")
        #expect(!versions.contains("1.1.1"), "Upgrading user must not see older v1.1.1")
    }

    // MARK: - Test 3: showAll bypasses the filter (Help → What's New)

    @Test("showAll = true returns ALL entries regardless of lastSeen")
    func showAllReturnsEverything() {
        let original = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        defer { restoreLastSeen(original) }

        UserDefaults.standard.set("0.0.0", forKey: Self.lastSeenKey)
        let manager = WhatsNewManager()
        manager.showAll = true

        let visible = manager.visibleEntries
        let versions = Set(visible.map { $0.version })

        // showAll short-circuits — every entry in WhatsNewChangelog.entries appears.
        let expected = Set(WhatsNewChangelog.entries.map { $0.version })
        #expect(versions == expected, "showAll mode must return entries from WhatsNewChangelog unchanged")
    }

    // MARK: - Test 4: dismiss() writes lastSeenVersion regression guard

    @Test("dismiss() writes current bundle version to lastSeenVersion")
    func dismissWritesCurrentVersion() {
        let original = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        defer { restoreLastSeen(original) }

        UserDefaults.standard.set("0.0.0", forKey: Self.lastSeenKey)
        let manager = WhatsNewManager()
        manager.dismiss()

        let written = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        #expect(written == currentVersion,
                "dismiss() must write current bundle version to lastSeenVersion (got '\(written ?? "nil")', expected '\(currentVersion)')")
    }

    // MARK: - Helpers

    private func restoreLastSeen(_ original: String?) {
        if let original {
            UserDefaults.standard.set(original, forKey: Self.lastSeenKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.lastSeenKey)
        }
    }
}
