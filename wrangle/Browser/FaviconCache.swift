//
//  FaviconCache.swift
//  Wrangle
//

import Foundation
import AppKit

@MainActor
final class FaviconCache {
    static let shared = FaviconCache()

    private var cache: [String: NSImage] = [:]
    private var inFlight: [String: Task<NSImage?, Never>] = [:]

    private init() {}

    func favicon(for pageURL: URL, linkHref: URL) async -> NSImage? {
        let key = Self.cacheKey(for: pageURL)
        if let hit = cache[key] { return hit }
        if let task = inFlight[key] { return await task.value }

        let task = Task<NSImage?, Never> { [linkHref] in
            guard let (data, _) = try? await URLSession.shared.data(from: linkHref),
                  let image = NSImage(data: data) else { return nil }
            return image
        }
        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        if let result { cache[key] = result }
        return result
    }

    func cached(for pageURL: URL) -> NSImage? {
        cache[Self.cacheKey(for: pageURL)]
    }

    static func cacheKey(for url: URL) -> String {
        url.host()?.lowercased() ?? url.absoluteString
    }
}
