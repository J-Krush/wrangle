//
//  HistoryStore.swift
//  Wrangle
//

import Foundation
import SwiftData
import AppKit

@MainActor
struct HistoryStore {
    let context: ModelContext

    // MARK: - Recording

    func record(url: URL, title: String, favicon: NSImage?, projectID: String?) {
        guard shouldRecord(url: url) else { return }
        let normalized = BrowserBookmark.normalizedKey(for: url.absoluteString)
        let descriptor = FetchDescriptor<BrowsingHistoryEntry>(
            sortBy: [SortDescriptor(\.dateVisited, order: .reverse)]
        )
        if let all = try? context.fetch(descriptor),
           let existing = all.first(where: {
               BrowserBookmark.normalizedKey(for: $0.urlString) == normalized
           }) {
            // Update existing: bump date, count, favicon, title if better.
            existing.dateVisited = .now
            existing.visitCount += 1
            if !title.isEmpty, title != "New Tab" {
                existing.title = title
            }
            if let data = faviconPNGData(for: favicon) {
                existing.faviconData = data
            }
            try? context.save()
            return
        }
        let entry = BrowsingHistoryEntry(
            urlString: url.absoluteString,
            title: title.isEmpty ? (url.host() ?? url.absoluteString) : title,
            dateVisited: .now,
            faviconData: faviconPNGData(for: favicon),
            projectID: projectID,
            visitCount: 1
        )
        context.insert(entry)
        try? context.save()
    }

    /// Exclude certain URLs from history: non-http, data: URIs, etc.
    private func shouldRecord(url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    // MARK: - Queries

    func all() -> [BrowsingHistoryEntry] {
        let descriptor = FetchDescriptor<BrowsingHistoryEntry>(
            sortBy: [SortDescriptor(\.dateVisited, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func suggestions(matching query: String, limit: Int = 8) -> [BrowsingHistoryEntry] {
        let entries = all()
        guard !query.isEmpty else { return Array(entries.prefix(limit)) }
        let lower = query.lowercased()
        return entries
            .filter { $0.urlString.lowercased().contains(lower) || $0.title.lowercased().contains(lower) }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Clearing

    enum ClearRange {
        case lastHour
        case lastDay
        case lastWeek
        case allTime
    }

    @discardableResult
    func clear(_ range: ClearRange) -> Int {
        let cutoff: Date?
        switch range {
        case .lastHour:  cutoff = Calendar.current.date(byAdding: .hour, value: -1, to: .now)
        case .lastDay:   cutoff = Calendar.current.date(byAdding: .day, value: -1, to: .now)
        case .lastWeek:  cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now)
        case .allTime:   cutoff = nil
        }
        let entries = all()
        let toDelete = entries.filter { entry in
            guard let cutoff else { return true }
            return entry.dateVisited >= cutoff
        }
        for entry in toDelete {
            context.delete(entry)
        }
        try? context.save()
        return toDelete.count
    }

    // MARK: - Helpers

    private func faviconPNGData(for image: NSImage?) -> Data? {
        guard let image else { return nil }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
