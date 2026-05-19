import AppKit

@MainActor
@Observable
class UpdateChecker {
    var updateAvailable = false
    var showUpToDate = false
    var latestVersion = ""
    var releaseNotes = ""
    private var downloadURL = ""

    private static let versionEndpoint = "https://api.github.com/repos/J-Krush/wrangle/releases/latest"
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
        // Open the GitHub Release page directly (D-11). No legacy
        // landing-page fallback — `downloadURL` is the Release
        // `html_url` populated from the GitHub Releases response.
        guard !downloadURL.isEmpty, let url = URL(string: downloadURL) else { return }
        NSWorkspace.shared.open(url)
        updateAvailable = false
    }

    // MARK: - Private

    private func performCheck(manual: Bool = false) async {
        guard let url = URL(string: Self.versionEndpoint) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

            // GitHub release tag_name is often prefixed with "v" (e.g. "v1.3.0");
            // strip it so the semver comparison below works unchanged.
            let releaseVersion: String = {
                let tag = release.tag_name
                return tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            }()

            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            guard isVersion(releaseVersion, newerThan: currentVersion) else {
                if manual { showUpToDate = true }
                return
            }

            if !manual {
                let dismissed = UserDefaults.standard.string(forKey: Self.dismissedVersionKey)
                guard dismissed != releaseVersion else { return }
            }

            latestVersion = releaseVersion
            downloadURL = release.html_url
            releaseNotes = release.body ?? ""
            updateAvailable = true
        } catch {
            // Pre-public-flip (Phases 13–17), the GitHub Releases endpoint
            // returns 404 because the repo is still private. The decode
            // throws, we land here, and the existing manual / non-manual
            // paths handle the fall-through: manual flips
            // `showUpToDate = true` (per D-10), background checks swallow
            // silently. Phase 18 makes the endpoint live and this becomes
            // the success path.
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

// MARK: - GitHub Releases Response Model

/// Subset of GitHub's Releases API response used by `UpdateChecker`.
/// Other fields (`assets[]`, `prerelease`, `draft`, `author`, etc.) are
/// ignored — opening the Release `html_url` is the v1.3 download path
/// (D-09). Parsing `assets[]` for a `.dmg` `browser_download_url` is
/// deferred to Phase 18 per CONTEXT.md `<deferred>`.
// swiftlint:disable identifier_name
private struct GitHubRelease: Decodable {
    let tag_name: String
    let html_url: String
    let body: String?
}
// swiftlint:enable identifier_name
