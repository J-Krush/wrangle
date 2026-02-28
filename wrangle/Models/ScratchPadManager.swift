import Foundation

struct ScratchPadItem: Identifiable, Sendable {
    var id: URL { url }
    let url: URL
    let name: String
    let modificationDate: Date
}

@MainActor
@Observable
class ScratchPadManager {
    var scratchPads: [ScratchPadItem] = []

    private var fileWatcher: FileWatcher?

    static var scratchPadDirectory: URL {
        URL.applicationSupportDirectory
            .appending(path: "Wrangle/ScratchPads", directoryHint: .isDirectory)
    }

    init() {
        ensureDirectoryExists()
        loadScratchPads()
        startWatching()
    }

    // MARK: - CRUD

    @discardableResult
    func createScratchPad(name: String) -> URL {
        let sanitized = name
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let baseName = sanitized.isEmpty ? "Scratch" : sanitized
        let url = uniqueURL(for: baseName)

        FileManager.default.createFile(atPath: url.path, contents: nil)
        loadScratchPads()
        return url
    }

    @discardableResult
    func createScratchPadWithTimestamp() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let name = "Scratch \(formatter.string(from: Date()))"
        return createScratchPad(name: name)
    }

    func renameScratchPad(at url: URL, to newName: String) -> URL? {
        let sanitized = newName
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        guard !sanitized.isEmpty else { return nil }

        let newURL = uniqueURL(for: sanitized, excluding: url)
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            loadScratchPads()
            return newURL
        } catch {
            return nil
        }
    }

    func deleteScratchPad(at url: URL) {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } catch {
            try? FileManager.default.removeItem(at: url)
        }
        loadScratchPads()
    }

    func loadScratchPads() {
        let dir = Self.scratchPadDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            scratchPads = []
            return
        }

        scratchPads = contents
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap { url -> ScratchPadItem? in
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                let modDate = values?.contentModificationDate ?? Date.distantPast
                let name = url.deletingPathExtension().lastPathComponent
                return ScratchPadItem(url: url, name: name, modificationDate: modDate)
            }
            .sorted { $0.modificationDate > $1.modificationDate }
    }

    // MARK: - Private

    private func ensureDirectoryExists() {
        let dir = Self.scratchPadDirectory
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

    private func uniqueURL(for baseName: String, excluding: URL? = nil) -> URL {
        let dir = Self.scratchPadDirectory
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
