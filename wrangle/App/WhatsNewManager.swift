import Foundation

@MainActor
@Observable
class WhatsNewManager {
    private static let lastSeenVersionKey = "WhatsNewManager.lastSeenVersion"

    var shouldShowModal: Bool = false
    var showAll: Bool = false

    func checkOnLaunch() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let lastSeen = UserDefaults.standard.string(forKey: Self.lastSeenVersionKey) ?? "0.0.0"

        guard lastSeen != currentVersion else { return }

        let newEntries = WhatsNewChangelog.entries.filter { entry in
            isVersion(entry.version, newerThan: lastSeen)
        }

        if !newEntries.isEmpty {
            shouldShowModal = true
        } else {
            UserDefaults.standard.set(currentVersion, forKey: Self.lastSeenVersionKey)
        }
    }

    func dismiss() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        UserDefaults.standard.set(currentVersion, forKey: Self.lastSeenVersionKey)
        shouldShowModal = false
        showAll = false
    }

    var visibleEntries: [ChangelogEntry] {
        if showAll { return WhatsNewChangelog.entries }
        let lastSeen = UserDefaults.standard.string(forKey: Self.lastSeenVersionKey) ?? "0.0.0"
        let isFreshInstall = lastSeen == "0.0.0"
        return WhatsNewChangelog.entries.filter { entry in
            // Always require: entry version > lastSeen (existing semver gate).
            guard isVersion(entry.version, newerThan: lastSeen) else { return false }
            // D-05 fresh-install filter: brand-new installs (no prior lastSeen)
            // only see entries >= "1.3.0" so v1.1.x / v1.2.0 history isn't
            // auto-shown to users who never ran an older Wrangle build.
            // Upgrading users (lastSeen != "0.0.0") fall through with just the
            // semver-newer gate above. Help → What's New (showAll) bypasses
            // this filter via the short-circuit at the top of this getter.
            if isFreshInstall {
                return !isVersion("1.3.0", newerThan: entry.version)
            }
            return true
        }
    }

    private func isVersion(_ a: String, newerThan b: String) -> Bool {
        let partsA = a.split(separator: ".").compactMap { Int($0) }
        let partsB = b.split(separator: ".").compactMap { Int($0) }
        let count = max(partsA.count, partsB.count)
        for i in 0..<count {
            let va = i < partsA.count ? partsA[i] : 0
            let vb = i < partsB.count ? partsB[i] : 0
            if va > vb { return true }
            if va < vb { return false }
        }
        return false
    }
}
