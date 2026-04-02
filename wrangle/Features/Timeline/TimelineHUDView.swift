//
//  TimelineHUDView.swift
//  Wrangle
//
//  Continuous interactive timeline bar at the bottom of the app.
//  Always shows project-colored pills across full history.
//  Drag to scrub and preview past workspace states.
//  Pin the preview on release, then Restore or dismiss.

import SwiftUI
import SwiftData

struct TimelineHUDView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let appState: AppState
    @Query private var rooms: [Room]
    @State private var viewModel = TimelineScrubberViewModel()
    @State private var hoveredSpanID: String?
    @State private var trackWidth: CGFloat = 1

    private var showPopover: Bool {
        viewModel.scrubPreview != nil && viewModel.isScrubbing
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                // Timeline label
                Text("timeline")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(width: 50, alignment: .leading)
                    .padding(.leading, 8)

                // Main band + ticks area
                VStack(spacing: 2) {
                    bandTrack
                        .frame(height: 12)
                        .padding(.top, 4)
                    tickBar
                        .padding(.bottom, 2)
                }
                .contentShape(Rectangle())
                .gesture(scrubGesture)
                .overlay(alignment: .top) {
                    if showPopover, let preview = viewModel.scrubPreview,
                       let fraction = viewModel.scrubFraction {
                        scrubPopover(preview: preview, fraction: fraction)
                    }
                }

                // Zoom controls (left = zoom out, right = zoom in)
                HStack(spacing: 3) {
                    Button { viewModel.zoomOut() } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canZoomOut)
                    .opacity(viewModel.canZoomOut ? 0.6 : 0.2)

                    Text(viewModel.currentZoomLabel)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .frame(width: 22)

                    Button { viewModel.zoomIn() } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canZoomIn)
                    .opacity(viewModel.canZoomIn ? 0.6 : 0.2)
                }
                .padding(.trailing, 8)
                .padding(.leading, 6)
            }
            .frame(height: 44)
            .background(appState.isInPlayback
                ? Color(nsColor: Theme.playbackChromeBackground)
                : Color(nsColor: Theme.chromeBackground)
            )
        }
        .task {
            viewModel.configure(engineClient: coordinator.engineClient)
            await viewModel.loadDashboard()
        }
        .onChange(of: appState.isInPlayback) { _, isPlayback in
            if !isPlayback {
                // Playback was dismissed externally (e.g. banner "Back to now") -- reset scrub state
                viewModel.resetScrubState(appState: appState)
            }
        }
    }

    // MARK: - Band Track

    @ViewBuilder
    private var bandTrack: some View {
        GeometryReader { geo in
            let _ = updateTrackWidth(geo.size.width)
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: .separatorColor).opacity(0.15))

                if viewModel.spans.isEmpty {
                    Text("no activity yet")
                        .font(.system(size: 9))
                        .foregroundStyle(.quaternary)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.spans) { span in
                        TimelineBandView(
                            span: span,
                            totalStartMs: viewModel.displayStartMs,
                            totalEndMs: viewModel.displayEndMs,
                            isHovered: hoveredSpanID == span.id
                        )
                        .onHover { isHovered in
                            hoveredSpanID = isHovered ? span.id : nil
                        }
                        .help(tooltipText(for: span))
                    }
                }

                // Scrub indicator line
                if let fraction = viewModel.scrubFraction {
                    Rectangle()
                        .fill(.white)
                        .frame(width: 1.5)
                        .offset(x: fraction * geo.size.width)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    // MARK: - Time Ticks

    private var tickBar: some View {
        let ticks = viewModel.timeTicks(count: 5)
        return HStack {
            ForEach(Array(ticks.enumerated()), id: \.offset) { _, tick in
                if tick.fraction == 0 {
                    Text(tick.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if tick.fraction >= 0.99 {
                    Text(tick.label)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text(tick.label)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .font(.system(size: 9))
        .foregroundStyle(.quaternary)
    }

    // MARK: - Scrub Gesture

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let x = value.location.x - 12
                let fraction = x / max(trackWidth, 1)
                viewModel.scrubTo(fraction: fraction, rooms: rooms, appState: appState)
            }
            .onEnded { _ in
                viewModel.endScrub(appState: appState, rooms: rooms)
            }
    }

    private func updateTrackWidth(_ width: CGFloat) -> Bool {
        Task { @MainActor in
            if trackWidth != width { trackWidth = width }
        }
        return true
    }

    // MARK: - Scrub Popover

    @ViewBuilder
    private func scrubPopover(preview: ScrubPreview, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Room header
            HStack(spacing: 5) {
                if let hex = preview.roomColorHex {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 8, height: 8)
                }
                Text(preview.roomName)
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Text(preview.formattedTime)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // Tab list
            ForEach(Array(preview.tabs.prefix(6).enumerated()), id: \.offset) { _, tab in
                HStack(spacing: 5) {
                    Image(systemName: tabIcon(for: tab))
                        .font(.system(size: 9))
                        .foregroundStyle(tabColor(for: tab))
                        .frame(width: 12)
                    Text(tabLabel(for: tab))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if tab.isActive {
                        Circle()
                            .fill(.green)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            if preview.tabs.count > 6 {
                Text("+\(preview.tabs.count - 6) more")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Text(preview.summary)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .padding(.top, 1)
        }
        .frame(width: 200)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        }
        // Position above the scrubber, tracking the scrub position horizontally
        .offset(
            x: max(0, min(trackWidth - 220, fraction * trackWidth - 100)),
            y: -56
        )
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func tabIcon(for tab: TabSnapshot) -> String {
        switch tab.kind {
        case "terminal":
            if tab.metadata["agent_type"] == "claude" { return "sparkle" }
            if tab.metadata["agent_type"] == "gemini" { return "sparkle" }
            return "terminal"
        case "browser": return "globe"
        default: return "doc.text"
        }
    }

    private func tabColor(for tab: TabSnapshot) -> Color {
        switch tab.kind {
        case "terminal":
            if tab.metadata["agent_type"] == "claude" { return .orange }
            if tab.metadata["agent_type"] == "gemini" { return .blue }
            return .mint
        case "browser": return .blue
        default: return .gray
        }
    }

    private func tabLabel(for tab: TabSnapshot) -> String {
        if let title = tab.title, !title.isEmpty { return title }
        if let path = tab.filePath { return String(path.split(separator: "/").last ?? "untitled") }
        if let url = tab.url { return url }
        return "untitled"
    }

    private func tooltipText(for span: TimelineSpan) -> String {
        let roomName = viewModel.roomName(for: span, rooms: rooms)
        let durationMin = (span.endMs - span.startMs) / 60_000
        if durationMin < 60 {
            return "\(roomName) - \(durationMin)m"
        }
        let hours = durationMin / 60
        let mins = durationMin % 60
        return "\(roomName) - \(hours)h \(mins)m"
    }
}
