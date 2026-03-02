import AppKit

@MainActor
@Observable
class UpdateChecker {
    var updateAvailable = false
    var showUpToDate = false
    var latestVersion = ""
    var releaseNotes = ""
    private var downloadURL = ""

    private static let versionEndpoint = "https://wrangle.dev/api/version.json"
    private static let dismissedVersionKey = "UpdateChecker.dismissedVersion"

    func checkForUpdate(manual: Bool = false) {
        Task {
            await performCheck(manual: manual)
        }
    }

    func dismissUpdate() {
        UserDefaults.standard.set(latestVersion, forKey: Self.dismissedVersionKey)
        updateAvailable = false
    }

    func openDownloadPage() {
        let urlString = downloadURL.isEmpty ? "https://wrangle.dev/download" : downloadURL
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        updateAvailable = false
    }

    // MARK: - Private

    private func performCheck(manual: Bool = false) async {
        guard let url = URL(string: Self.versionEndpoint) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let versionInfo = try JSONDecoder().decode(VersionInfo.self, from: data)

            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            guard isVersion(versionInfo.version, newerThan: currentVersion) else {
                if manual { showUpToDate = true }
                return
            }

            if !manual {
                let dismissed = UserDefaults.standard.string(forKey: Self.dismissedVersionKey)
                guard dismissed != versionInfo.version else { return }
            }

            latestVersion = versionInfo.version
            downloadURL = versionInfo.downloadURL
            releaseNotes = versionInfo.releaseNotes ?? ""
            updateAvailable = true
        } catch {
            if manual { showUpToDate = true }
        }
    }

    /// Semantic version comparison: returns true if `a` is strictly newer than `b`.
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

// MARK: - Version Endpoint Model

private struct VersionInfo: Codable {
    let version: String
    let downloadURL: String
    let releaseNotes: String?

    enum CodingKeys: String, CodingKey {
        case version
        case downloadURL = "download_url"
        case releaseNotes = "release_notes"
    }
}
