//
//  TimelineScrubberViewModel.swift
//  Wrangle
//
//  Queries the Rust engine for timeline data, computes adaptive time ranges,
//  manages scrub interaction state, and provides both room-level and tab-level spans.

import Foundation
import SwiftUI

// MARK: - Scrub Preview

struct ScrubPreview {
    let timestampMs: Int64
    let roomName: String
    let roomColorHex: String?
    let tabs: [TabSnapshot]
    let summary: String     // e.g. "2 terminals, 1 browser, 1 file"

    var formattedTime: String {
        let date = Date(timeIntervalSince1970: Double(timestampMs) / 1000)
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }

        let formatter = DateFormatter()
        if interval < 172800 {
            formatter.dateFormat = "h:mm a 'yesterday'"
        } else {
            formatter.dateFormat = "h:mm a, MMM d"
        }
        return formatter.string(from: date)
    }

    static func from(tabs: [TabSnapshot]) -> String {
        var counts: [String: Int] = [:]
        for tab in tabs {
            let kind = TabSpanKind.from(tabSnapshot: tab)
            counts[kind.displayName, default: 0] += 1
        }
        let parts = counts.sorted { $0.value > $1.value }
            .map { "\($0.value) \($0.key)\($0.value > 1 ? "s" : "")" }
        return parts.isEmpty ? "no activity" : parts.joined(separator: ", ")
    }
}

// MARK: - View Model

@MainActor
@Observable
class TimelineScrubberViewModel {
    // Data
    var spans: [TimelineSpan] = []
    var events: [TimelineEvent] = []
    var tabSpans: [TimelineTabSpan] = []
    var isLoading = false

    // Adaptive display range (computed from actual data)
    var displayStartMs: Int64 = 0
    var displayEndMs: Int64 = 0

    // Scrub interaction
    var scrubFraction: Double?       // nil = live, 0.0-1.0 = position
    var scrubPreview: ScrubPreview?
    var isScrubbing = false

    private weak var engineClient: EngineClient?
    private var lastQueryRange: (start: Int64, end: Int64)?
    private var refreshTask: Task<Void, Never>?
    private var scrubTask: Task<Void, Never>?

    private static let minRangeMs: Int64 = 5 * 60 * 1000        // 5 minutes minimum
    private static let queryWindowMs: Int64 = 7 * 24 * 3600_000 // 7 days lookback

    // Zoom levels (display range durations)
    static let zoomLevels: [(label: String, ms: Int64)] = [
        ("15m", 15 * 60 * 1000),
        ("1h", 1 * 3600_000),
        ("4h", 4 * 3600_000),
        ("1d", 24 * 3600_000),
        ("3d", 3 * 24 * 3600_000),
        ("1w", 7 * 24 * 3600_000),
        ("all", 0), // 0 = adaptive (fit all data)
    ]
    var zoomIndex: Int = 6 // default to "all"

    func configure(engineClient: EngineClient) {
        self.engineClient = engineClient
    }

    // MARK: - Loading

    /// Load timeline in dashboard mode (all rooms, adaptive range).
    func loadDashboard() async {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let start = now - Self.queryWindowMs
        await loadRange(startMs: start, endMs: now, roomID: nil)
    }

    /// Load timeline in room mode (specific room, adaptive range).
    func loadRoom(_ roomID: String) async {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let start = now - Self.queryWindowMs
        await loadRange(startMs: start, endMs: now, roomID: roomID)
    }

    private func loadRange(startMs: Int64, endMs: Int64, roomID: String?) async {
        guard let engineClient else { return }
        isLoading = true
        lastQueryRange = (startMs, endMs)

        if let result = await engineClient.queryTimeline(startMs: startMs, endMs: endMs, roomID: roomID) {
            self.spans = result.spans
            self.events = result.events
            computeAdaptiveRange(now: endMs)
        }
        isLoading = false
    }

    // MARK: - Zoom

    var currentZoomLabel: String {
        Self.zoomLevels[zoomIndex].label
    }

    func zoomIn() {
        if zoomIndex > 0 {
            zoomIndex -= 1
            applyZoom()
        }
    }

    func zoomOut() {
        if zoomIndex < Self.zoomLevels.count - 1 {
            zoomIndex += 1
            applyZoom()
        }
    }

    var canZoomIn: Bool { zoomIndex > 0 }
    var canZoomOut: Bool { zoomIndex < Self.zoomLevels.count - 1 }

    private func applyZoom() {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let zoomMs = Self.zoomLevels[zoomIndex].ms

        if zoomMs == 0 {
            // "all" -- adaptive
            computeAdaptiveRange(now: now)
        } else {
            displayEndMs = now
            displayStartMs = now - zoomMs
        }
    }

    /// Compute display range from actual data, stretching to fill.
    private func computeAdaptiveRange(now: Int64) {
        // If a specific zoom level is set (not "all"), use that
        let zoomMs = Self.zoomLevels[zoomIndex].ms
        if zoomMs > 0 {
            displayEndMs = now
            displayStartMs = now - zoomMs
            return
        }

        guard let earliest = spans.first?.startMs else {
            displayEndMs = now
            displayStartMs = now - Self.minRangeMs
            return
        }

        let latest = max(spans.last?.endMs ?? now, now)
        let range = latest - earliest

        if range < Self.minRangeMs {
            displayStartMs = earliest - (Self.minRangeMs - range) / 2
            displayEndMs = latest + (Self.minRangeMs - range) / 2
        } else {
            let padding = max(range / 50, 30_000)
            displayStartMs = earliest - padding
            displayEndMs = latest
        }
    }

    // MARK: - Scrubbing

    /// The last snapshot result fetched during scrub (available for restore).
    private(set) var lastScrubResult: SnapshotQueryResult?

    /// Whether the preview is pinned (drag ended but user hasn't dismissed or restored).
    var isPreviewPinned = false

    /// Room/viewMode that was active before scrubbing started, for "Back to now".
    private var preScrubRoomID: String?
    private var preScrubViewMode: ViewMode = .dashboard

    /// Called during drag gesture. Fraction is 0.0 (left/past) to 1.0 (right/now).
    func scrubTo(fraction: Double, rooms: [Room], appState: AppState) {
        let clamped = max(0, min(1, fraction))
        scrubFraction = clamped

        // Save pre-scrub state on first drag
        if !isScrubbing {
            preScrubRoomID = appState.selectedRoomID
            preScrubViewMode = appState.viewMode
        }

        isScrubbing = true
        isPreviewPinned = false

        let timestampMs = displayStartMs + Int64(Double(displayEndMs - displayStartMs) * clamped)

        // Debounce the actual query
        scrubTask?.cancel()
        scrubTask = Task {
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            await fetchScrubPreview(at: timestampMs, rooms: rooms, appState: appState)
        }
    }

    /// Called when drag ends. Playback is already active from the drag -- just pin the preview.
    func endScrub(appState: AppState, rooms: [Room]) {
        isScrubbing = false
        scrubTask?.cancel()
        if scrubPreview != nil {
            isPreviewPinned = true
        }
    }

    /// Restore the scrubbed workspace into the present, then reset to "now".
    func restore(appState: AppState) {
        appState.restoreFromPlayback()
        resetToNow()
    }

    /// Dismiss playback and scrub state. Restore pre-scrub view.
    func dismissPreview(appState: AppState) {
        appState.exitPlayback()
        // Restore the room/view that was active before scrubbing
        appState.selectedRoomID = preScrubRoomID
        appState.viewMode = preScrubViewMode
        resetToNow()
    }

    /// Called externally when playback is dismissed (e.g. from banner button).
    /// Resets scrub visuals and restores pre-scrub room.
    func resetScrubState(appState: AppState) {
        appState.selectedRoomID = preScrubRoomID
        appState.viewMode = preScrubViewMode
        resetToNow()
    }

    /// Reset all scrub state back to live/now.
    private func resetToNow() {
        isScrubbing = false
        isPreviewPinned = false
        scrubFraction = nil
        scrubPreview = nil
        lastScrubResult = nil
        scrubTask?.cancel()
    }

    private func fetchScrubPreview(at timestampMs: Int64, rooms: [Room], appState: AppState) async {
        guard let engineClient else { return }
        guard let result = await engineClient.querySnapshot(atMs: timestampMs) else { return }

        lastScrubResult = result

        let roomName = rooms.first { $0.id == result.roomID }?.name ?? "Unknown"
        let roomColor = rooms.first { $0.id == result.roomID }?.colorHex

        // Switch to the room and enter playback so RoomOverviewView shows snapshot tabs
        if appState.selectedRoomID != result.roomID {
            appState.selectedRoomID = result.roomID
        }
        appState.viewMode = .roomOverview

        let preview = ScrubPreview(
            timestampMs: result.timestampMs,
            roomName: roomName,
            roomColorHex: roomColor,
            tabs: result.workspace.tabs,
            summary: ScrubPreview.from(tabs: result.workspace.tabs)
        )
        scrubPreview = preview

        // Set playback state so RoomOverviewView renders from snapshot data
        appState.enterPlayback(TimelinePlayback(
            snapshot: result,
            roomName: roomName,
            roomColorHex: roomColor,
            formattedTime: preview.formattedTime
        ))
    }

    // MARK: - Tab Span Computation (Room Mode)

    /// Compute tab-level activity spans from room-level snapshots.
    /// Groups consecutive snapshots where the same tab types are present.
    func computeTabSpans(from snapshots: [TabSnapshot], startMs: Int64, endMs: Int64) {
        // For now, derive from the room-level spans + current visible tabs
        // Full implementation would query multiple snapshots and diff them
        // This simplified version creates one span per active tab type in the current room
        var result: [TimelineTabSpan] = []

        // Group tabs by kind and create spans across the room's time range
        var kindGroups: [TabSpanKind: [TabSnapshot]] = [:]
        for tab in snapshots {
            let kind = TabSpanKind.from(tabSnapshot: tab)
            kindGroups[kind, default: []].append(tab)
        }

        for (kind, tabs) in kindGroups {
            let label = tabs.first?.title ?? kind.displayName
            result.append(TimelineTabSpan(
                kind: kind,
                label: label,
                startMs: startMs,
                endMs: endMs
            ))
        }

        tabSpans = result.sorted { $0.startMs < $1.startMs }
    }

    // MARK: - Refresh

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            if let range = lastQueryRange {
                await loadRange(startMs: range.start, endMs: range.end, roomID: nil)
            } else {
                await loadDashboard()
            }
        }
    }

    // MARK: - Display Helpers

    var displayRangeMs: Int64 {
        max(displayEndMs - displayStartMs, 1)
    }

    func roomName(for span: TimelineSpan, rooms: [Room]) -> String {
        rooms.first { $0.id == span.roomID }?.name ?? "Unknown"
    }

    /// Generate evenly-spaced time tick labels for the display range.
    func timeTicks(count: Int = 5) -> [(label: String, fraction: Double)] {
        let range = Double(displayRangeMs)
        guard range > 0 else { return [] }

        let now = Date()
        var ticks: [(label: String, fraction: Double)] = []

        for i in 0..<count {
            let fraction = Double(i) / Double(count - 1)
            let ms = displayStartMs + Int64(fraction * Double(displayRangeMs))
            let date = Date(timeIntervalSince1970: Double(ms) / 1000)
            let label = formatTickLabel(date: date, now: now, totalRangeMs: displayRangeMs)
            ticks.append((label, fraction))
        }

        return ticks
    }

    private func formatTickLabel(date: Date, now: Date, totalRangeMs: Int64) -> String {
        let interval = now.timeIntervalSince(date)

        // For ranges under 2 hours, show clock times
        if totalRangeMs < 2 * 3600_000 {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }

        // For ranges under 24 hours, show relative or clock
        if totalRangeMs < 24 * 3600_000 {
            if interval < 60 { return "now" }
            if interval < 3600 { return "\(Int(interval / 60))m ago" }
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }

        // For multi-day ranges, show day labels
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "today" }
        if interval < 172800 { return "yesterday" }

        let days = Int(interval / 86400)
        return "\(days)d ago"
    }
}
