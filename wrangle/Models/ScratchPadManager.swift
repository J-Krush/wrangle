import Foundation
import os.log

struct ScratchPadItem: Identifiable, Sendable {
    var id: URL { url }
    let url: URL
    let name: String
    let modificationDate: Date
    let projectID: String?
}

@MainActor
@Observable
class ScratchPadManager {
    var scratchPads: [ScratchPadItem] = []

    private var fileWatcher: FileWatcher?
    private var projectWatchers: [String: FileWatcher] = [:]

    static var scratchPadDirectory: URL {
        URL.applicationSupportDirectory
            .appending(path: "Wrangle/ScratchPads", directoryHint: .isDirectory)
    }

    init() {
        ensureDirectoryExists(Self.scratchPadDirectory)
        loadScratchPads()
        startWatching()
    }

    /// Scratch pads for a specific project
    func scratchPads(forProject projectID: String) -> [ScratchPadItem] {
        scratchPads.filter { $0.projectID == projectID }
    }

    // MARK: - CRUD

    @discardableResult
    func createScratchPad(name: String, projectID: String? = nil) -> URL {
        let sanitized = name
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let baseName = sanitized.isEmpty ? "Scratch" : sanitized
        let dir = directoryForProject(projectID)
        let url = uniqueURL(for: baseName, in: dir)

        FileManager.default.createFile(atPath: url.path, contents: nil)
        loadScratchPads()
        return url
    }

    @discardableResult
    func createScratchPadWithTimestamp(projectID: String? = nil) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let name = "Scratch \(formatter.string(from: Date()))"
        return createScratchPad(name: name, projectID: projectID)
    }

    func renameScratchPad(at url: URL, to newName: String) -> URL? {
        let sanitized = newName
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        guard !sanitized.isEmpty else { return nil }

        let dir = url.deletingLastPathComponent()
        let newURL = uniqueURL(for: sanitized, in: dir, excluding: url)
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            loadScratchPads()
            return newURL
        } catch {
            return nil
        }
    }

    func deleteScratchPad(at url: URL) {
        // Phase 12 / RESEARCH Pitfall 2: prior code silently hard-deleted on
        // trashItem failure, which contradicted the UX promise of "moved to
        // Trash". Log the error instead and leave the file in place so the
        // user can retry or investigate.
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } catch {
            os_log(
                "Failed to move scratch pad to Trash: %{public}@ (%{public}@)",
                log: .default,
                type: .error,
                url.path,
                String(describing: error)
            )
        }
        loadScratchPads()
    }

    func loadScratchPads() {
        var items: [ScratchPadItem] = []

        // Load legacy global scratch pads (no project)
        items.append(contentsOf: loadPadsFromDirectory(Self.scratchPadDirectory, projectID: nil))

        // Load project-scoped scratch pads from subdirectories
        let fm = FileManager.default
        if let subdirs = try? fm.contentsOfDirectory(at: Self.scratchPadDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            for subdir in subdirs {
                let isDir = (try? subdir.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                guard isDir else { continue }
                let projectID = subdir.lastPathComponent
                items.append(contentsOf: loadPadsFromDirectory(subdir, projectID: projectID))
                ensureProjectWatcher(projectID: projectID, directory: subdir)
            }
        }

        scratchPads = items.sorted { $0.modificationDate > $1.modificationDate }
    }

    /// Ensures a project subdirectory exists and starts watching it.
    func ensureProjectDirectory(for projectID: String) {
        let dir = directoryForProject(projectID)
        ensureDirectoryExists(dir)
        ensureProjectWatcher(projectID: projectID, directory: dir)
    }

    // MARK: - Private

    private func directoryForProject(_ projectID: String?) -> URL {
        guard let projectID else { return Self.scratchPadDirectory }
        let dir = Self.scratchPadDirectory.appending(path: projectID, directoryHint: .isDirectory)
        ensureDirectoryExists(dir)
        return dir
    }

    private func loadPadsFromDirectory(_ dir: URL, projectID: String?) -> [ScratchPadItem] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap { url -> ScratchPadItem? in
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                let modDate = values?.contentModificationDate ?? Date.distantPast
                let name = url.deletingPathExtension().lastPathComponent
                return ScratchPadItem(url: url, name: name, modificationDate: modDate, projectID: projectID)
            }
    }

    private func ensureDirectoryExists(_ dir: URL) {
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func startWatching() {
        let watcher = FileWatcher(url: Self.scratchPadDirectory) { [weak self] in
            self?.loadScratchPads()
        }
        watcher.start()
        fileWatcher = watcher
    }

    private func ensureProjectWatcher(projectID: String, directory: URL) {
        guard projectWatchers[projectID] == nil else { return }
        let watcher = FileWatcher(url: directory) { [weak self] in
            self?.loadScratchPads()
        }
        watcher.start()
        projectWatchers[projectID] = watcher
    }

    private func uniqueURL(for baseName: String, in dir: URL, excluding: URL? = nil) -> URL {
        let candidate = dir.appending(path: "\(baseName).md")
        if candidate != excluding, !FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }

        var n = 2
        while true {
            let numbered = dir.appending(path: "\(baseName) \(n).md")
            if numbered != excluding, !FileManager.default.fileExists(atPath: numbered.path) {
                return numbered
            }
            n += 1
        }
    }
}
