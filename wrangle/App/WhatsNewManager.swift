import Foundation

@MainActor
@Observable
class WhatsNewManager {
    private static let lastSeenVersionKey = "WhatsNewManager.lastSeenVersion"

    var shouldShowModal: Bool = false

    func checkOnLaunch() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let lastSeen = UserDefaults.standard.string(forKey: Self.lastSeenVersionKey)

        // First install — seed current version, don't show
        guard let lastSeen else {
            UserDefaults.standard.set(currentVersion, forKey: Self.lastSeenVersionKey)
            return
        }

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
    }

    var visibleEntries: [ChangelogEntry] {
        let lastSeen = UserDefaults.standard.string(forKey: Self.lastSeenVersionKey) ?? "0.0.0"
        return WhatsNewChangelog.entries.filter { isVersion($0.version, newerThan: lastSeen) }
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
