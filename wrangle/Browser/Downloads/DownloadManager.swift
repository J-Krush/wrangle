//
//  DownloadManager.swift
//  Wrangle
//

import Foundation
import AppKit
import WebKit
import SwiftData

/// Owns WKDownloadDelegate and bridges to the SwiftData record model.
@MainActor
final class DownloadManager: NSObject {
    static let shared = DownloadManager()

    /// Last modelContext handed off by any browser coordinator. Used to
    /// write records — in multi-window setups the most-recent active
    /// context wins, which is acceptable because the SwiftData model
    /// store is shared.
    var modelContext: ModelContext?

    /// In-memory map of live WKDownload ↔ record IDs. Persists only for
    /// the lifetime of the download.
    private var active: [ObjectIdentifier: String] = [:]
    /// Held strongly so the delegate chain keeps the download alive.
    private var alive: [ObjectIdentifier: WKDownload] = [:]
    /// KVO observations for Foundation.Progress bytes written.
    private var progressObservations: [ObjectIdentifier: [NSKeyValueObservation]] = [:]

    // MARK: - Settings

    static let defaultDirectoryDefaultsKey = "browser.defaultDownloadsDirectory"

    /// User-configured default location; falls back to ~/Downloads.
    var defaultDirectory: URL {
        if let raw = UserDefaults.standard.string(forKey: Self.defaultDirectoryDefaultsKey),
           !raw.isEmpty {
            return URL(fileURLWithPath: raw)
        }
        return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Downloads")
    }

    // MARK: - Public API

    /// Attach as delegate and create a persistence record.
    func begin(_ download: WKDownload, suggestedURL: URL?) {
        download.delegate = self
        let id = UUID().uuidString
        let key = ObjectIdentifier(download)
        alive[key] = download
        active[key] = id

        // Observe byte progress.
        let progress = download.progress
        let completedObs = progress.observe(\.completedUnitCount) { [weak self] prog, _ in
            Task { @MainActor [weak self] in
                self?.updateProgress(downloadKey: key, received: prog.completedUnitCount, expected: prog.totalUnitCount)
            }
        }
        let totalObs = progress.observe(\.totalUnitCount) { [weak self] prog, _ in
            Task { @MainActor [weak self] in
                self?.updateProgress(downloadKey: key, received: prog.completedUnitCount, expected: prog.totalUnitCount)
            }
        }
        progressObservations[key] = [completedObs, totalObs]

        // Create a placeholder record — filename filled in when destination decided.
        if let context = modelContext {
            let record = BrowserDownloadRecord(
                id: id,
                sourceURLString: suggestedURL?.absoluteString ?? "",
                destinationPath: "",
                filename: suggestedURL?.lastPathComponent ?? "download",
                state: .inProgress
            )
            context.insert(record)
            try? context.save()
        }
    }

    private func updateProgress(downloadKey: ObjectIdentifier, received: Int64, expected: Int64) {
        guard let id = active[downloadKey],
              let context = modelContext else { return }
        let descriptor = FetchDescriptor<BrowserDownloadRecord>()
        guard let all = try? context.fetch(descriptor),
              let record = all.first(where: { $0.id == id }) else { return }
        record.bytesReceived = received
        if expected > 0 { record.bytesExpected = expected }
        try? context.save()
    }

    /// Cancel an in-progress download and delete the partial file.
    func cancel(_ record: BrowserDownloadRecord) {
        // Find the WKDownload by id lookup.
        for (key, downloadID) in active where downloadID == record.id {
            if let download = alive[key] {
                download.cancel { _ in }
            }
        }
        record.state = .cancelled
        record.dateCompleted = .now
        let partial = record.destinationURL
        if let partial, FileManager.default.fileExists(atPath: partial.path) {
            try? FileManager.default.removeItem(at: partial)
        }
        try? modelContext?.save()
    }

    /// Nuke the record and (optionally) the underlying file.
    func remove(_ record: BrowserDownloadRecord) {
        modelContext?.delete(record)
        try? modelContext?.save()
    }

    // MARK: - Helpers

    private func recordID(for download: WKDownload) -> String? {
        active[ObjectIdentifier(download)]
    }

    private func record(for download: WKDownload) -> BrowserDownloadRecord? {
        guard let context = modelContext, let id = recordID(for: download) else { return nil }
        let descriptor = FetchDescriptor<BrowserDownloadRecord>()
        guard let all = try? context.fetch(descriptor) else { return nil }
        return all.first { $0.id == id }
    }

    private func cleanup(_ download: WKDownload) {
        let key = ObjectIdentifier(download)
        progressObservations[key]?.forEach { $0.invalidate() }
        progressObservations.removeValue(forKey: key)
        alive.removeValue(forKey: key)
        active.removeValue(forKey: key)
    }

    /// Produce a unique file URL by appending " (1)", " (2)" if needed.
    static func uniqueDestination(directory: URL, filename: String) -> URL {
        var candidate = directory.appending(path: filename)
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let ext = candidate.pathExtension
            let stem = candidate.deletingPathExtension().lastPathComponent
            // Strip previous " (n)" suffix if present before adding new one.
            let base: String = {
                if let range = stem.range(of: #" \(\d+\)$"#, options: .regularExpression) {
                    return String(stem[..<range.lowerBound])
                }
                return stem
            }()
            let newName = ext.isEmpty ? "\(base) (\(counter))" : "\(base) (\(counter)).\(ext)"
            candidate = directory.appending(path: newName)
            counter += 1
        }
        return candidate
    }
}

// MARK: - WKDownloadDelegate

extension DownloadManager: WKDownloadDelegate {
    nonisolated func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping @Sendable (URL?) -> Void
    ) {
        let filename = suggestedFilename
        let sourceURLString = response.url?.absoluteString ?? ""
        Task { @MainActor in
            let directory = self.defaultDirectory
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let destination = DownloadManager.uniqueDestination(directory: directory, filename: filename)

            if let record = self.record(for: download) {
                record.destinationPath = destination.path
                record.filename = destination.lastPathComponent
                if record.sourceURLString.isEmpty { record.sourceURLString = sourceURLString }
                record.bytesExpected = response.expectedContentLength
                try? self.modelContext?.save()
            }
            completionHandler(destination)
        }
    }

    nonisolated func download(
        _ download: WKDownload,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (WKDownload.RedirectPolicy) -> Void
    ) {
        completionHandler(.allow)
    }

    nonisolated func downloadDidFinish(_ download: WKDownload) {
        Task { @MainActor in
            if let record = self.record(for: download) {
                record.state = .completed
                record.dateCompleted = .now
                if record.bytesExpected == 0,
                   let attrs = try? FileManager.default.attributesOfItem(atPath: record.destinationPath),
                   let size = attrs[.size] as? NSNumber {
                    record.bytesReceived = size.int64Value
                    record.bytesExpected = size.int64Value
                }
                try? self.modelContext?.save()
            }
            self.cleanup(download)
        }
    }

    nonisolated func download(
        _ download: WKDownload,
        didFailWithError error: any Error,
        resumeData: Data?
    ) {
        let message = error.localizedDescription
        Task { @MainActor in
            if let record = self.record(for: download) {
                record.state = .failed
                record.errorDescription = message
                record.dateCompleted = .now
                try? self.modelContext?.save()
            }
            self.cleanup(download)
        }
    }
}
