import Foundation
import Security

/// One-time cleanup of v1.2 license + trial Keychain entries and the
/// `LicenseManager.instanceID` UserDefaults key. Gated by
/// `WhatsNewManager.lastSeenVersion < "1.3.0"` so it runs once per
/// upgrading-from-v1.2 user and is a (silent) no-op on fresh installs
/// since the Keychain entries don't exist there.
///
/// Idempotent: `SecItemDelete` returning `errSecItemNotFound` is treated
/// as success. The helper performs only DELETEs — no reads, no writes to
/// the deleted slots — so there is no secret-data flow out of Keychain
/// through this surface.
///
/// References:
/// - `.planning/phases/13-app-de-commercialization/13-CONTEXT.md` D-13, D-14
/// - Plan `13-02-oss-note-residue-cleanup-and-update-repoint-PLAN.md` Task 2
@MainActor
enum LicenseResidueCleanup {

    private static let lastSeenVersionKey = "WhatsNewManager.lastSeenVersion"
    private static let instanceIDKey = "LicenseManager.instanceID"

    private static let licenseService = "dev.wrangle.license"
    private static let licenseAccount = "license-key"
    private static let trialService = "dev.wrangle.trial"
    private static let trialAccount = "trial-data"

    static func run() {
        // Gate: only run for users coming from a pre-v1.3 build (or fresh
        // installs where `lastSeen` is the "0.0.0" sentinel). After
        // WhatsNewManager.dismiss() writes `lastSeen = "1.3.0"` or higher,
        // this helper short-circuits on subsequent launches.
        let lastSeen = UserDefaults.standard.string(forKey: lastSeenVersionKey) ?? "0.0.0"
        guard !isAtLeast130(lastSeen) else { return }

        // SecItemDelete: license key
        let licenseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: licenseService,
            kSecAttrAccount as String: licenseAccount,
        ]
        _ = SecItemDelete(licenseQuery as CFDictionary)

        // SecItemDelete: trial blob
        let trialQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: trialService,
            kSecAttrAccount as String: trialAccount,
        ]
        _ = SecItemDelete(trialQuery as CFDictionary)

        UserDefaults.standard.removeObject(forKey: instanceIDKey)
    }

    /// Component-wise semver `>= "1.3.0"` check. Mirrors
    /// `WhatsNewManager.isVersion(_:newerThan:)` but with explicit "1.3.0"
    /// constant so the gate is testable without a live `WhatsNewManager`.
    private static func isAtLeast130(_ s: String) -> Bool {
        let target: [Int] = [1, 3, 0]
        let parts = s.split(separator: ".").compactMap { Int($0) }
        for i in 0..<target.count {
            let v = i < parts.count ? parts[i] : 0
            if v > target[i] { return true }
            if v < target[i] { return false }
        }
        return true
    }
}
