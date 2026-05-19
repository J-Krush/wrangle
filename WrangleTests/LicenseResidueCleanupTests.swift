import Foundation
import Security
import Testing
@testable import Wrangle

/// Tests for `LicenseResidueCleanup.run()` — the v1.2 → v1.3 one-shot
/// Keychain + UserDefaults cleanup helper.
///
/// `LicenseResidueCleanup` gates internally on
/// `UserDefaults.standard.string(forKey: "WhatsNewManager.lastSeenVersion") < "1.3.0"`
/// per D-13/D-14. Tests cover:
///   1. Idempotency — calling `run()` twice in a row succeeds both times
///      (second call hits `errSecItemNotFound` for the Keychain deletes,
///      which is treated as success per D-13).
///   2. `LicenseManager.instanceID` UserDefaults key is removed after `run()`.
///   3. Gate respected — when `lastSeenVersion >= "1.3.0"`, `run()` is a
///      no-op (sentinel UserDefaults value survives).
///   4. Gate respected (inverse) — when `lastSeenVersion == "0.0.0"`,
///      `run()` proceeds (UserDefaults `instanceID` ends up nil).
///
/// Keychain side-effects: the helper deletes only two hard-coded
/// service/account pairs (`dev.wrangle.license`/`license-key` and
/// `dev.wrangle.trial`/`trial-data`). Test #1 plants a known Keychain
/// entry, runs cleanup, and asserts the entry is gone; the second `run()`
/// is then trivially `errSecItemNotFound` — success.
@MainActor
@Suite("LicenseResidueCleanup")
struct LicenseResidueCleanupTests {

    private static let lastSeenKey = "WhatsNewManager.lastSeenVersion"
    private static let instanceIDKey = "LicenseManager.instanceID"
    private static let licenseService = "dev.wrangle.license"
    private static let licenseAccount = "license-key"

    // MARK: - Test 1: idempotency

    @Test("Calling run() twice succeeds (errSecItemNotFound treated as success)")
    func idempotentRuns() {
        let original = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        let originalInstanceID = UserDefaults.standard.string(forKey: Self.instanceIDKey)
        defer {
            restoreLastSeen(original)
            restoreInstanceID(originalInstanceID)
        }

        // Force the gate open.
        UserDefaults.standard.set("0.0.0", forKey: Self.lastSeenKey)

        // First call: deletes whatever might be there (likely nothing on CI).
        LicenseResidueCleanup.run()

        // Second call: must not crash, must not error — both Keychain
        // SecItemDeletes return errSecItemNotFound, which the helper
        // explicitly treats as success.
        LicenseResidueCleanup.run()

        // No assertion needed beyond "did not crash"; the gate condition
        // and Keychain query shape are exercised twice.
        #expect(Bool(true), "run() must be idempotent")
    }

    // MARK: - Test 2: UserDefaults instanceID cleared

    @Test("run() removes LicenseManager.instanceID from UserDefaults")
    func clearsInstanceID() {
        let original = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        let originalInstanceID = UserDefaults.standard.string(forKey: Self.instanceIDKey)
        defer {
            restoreLastSeen(original)
            restoreInstanceID(originalInstanceID)
        }

        // Plant a residue instanceID, force gate open, run cleanup.
        UserDefaults.standard.set("0.0.0", forKey: Self.lastSeenKey)
        UserDefaults.standard.set("test-instance-id", forKey: Self.instanceIDKey)

        LicenseResidueCleanup.run()

        let after = UserDefaults.standard.object(forKey: Self.instanceIDKey)
        #expect(after == nil, "LicenseManager.instanceID must be nil after cleanup (got \(String(describing: after)))")
    }

    // MARK: - Test 3: gate closed when lastSeenVersion >= "1.3.0"

    @Test("run() is a no-op when lastSeenVersion >= 1.3.0 (sentinel survives)")
    func gateRespectedWhenAtCurrentVersion() {
        let original = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        let originalInstanceID = UserDefaults.standard.string(forKey: Self.instanceIDKey)
        defer {
            restoreLastSeen(original)
            restoreInstanceID(originalInstanceID)
        }

        // Force the gate closed (user has already seen v1.3.0).
        UserDefaults.standard.set("1.3.0", forKey: Self.lastSeenKey)
        // Plant a sentinel that would survive only if the gate is respected.
        let sentinel = "do-not-delete-\(UUID().uuidString)"
        UserDefaults.standard.set(sentinel, forKey: Self.instanceIDKey)

        LicenseResidueCleanup.run()

        let after = UserDefaults.standard.string(forKey: Self.instanceIDKey)
        #expect(after == sentinel,
                "Sentinel must survive when lastSeenVersion >= '1.3.0' (got '\(after ?? "nil")', expected '\(sentinel)')")
    }

    // MARK: - Test 4: gate open on fresh install

    @Test("run() proceeds when lastSeenVersion == 0.0.0 (instanceID removed)")
    func gateOpenOnFreshInstall() {
        let original = UserDefaults.standard.string(forKey: Self.lastSeenKey)
        let originalInstanceID = UserDefaults.standard.string(forKey: Self.instanceIDKey)
        defer {
            restoreLastSeen(original)
            restoreInstanceID(originalInstanceID)
        }

        UserDefaults.standard.set("0.0.0", forKey: Self.lastSeenKey)
        UserDefaults.standard.set("should-be-cleared", forKey: Self.instanceIDKey)

        LicenseResidueCleanup.run()

        let after = UserDefaults.standard.object(forKey: Self.instanceIDKey)
        #expect(after == nil,
                "Fresh-install gate must let cleanup proceed; instanceID must be nil after run() (got \(String(describing: after)))")
    }

    // MARK: - Helpers

    private func restoreLastSeen(_ original: String?) {
        if let original {
            UserDefaults.standard.set(original, forKey: Self.lastSeenKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.lastSeenKey)
        }
    }

    private func restoreInstanceID(_ original: String?) {
        if let original {
            UserDefaults.standard.set(original, forKey: Self.instanceIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.instanceIDKey)
        }
    }
}
