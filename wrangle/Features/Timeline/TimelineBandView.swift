//
//  TimelineBandView.swift
//  Wrangle
//
//  Renders a single colored pill band in the timeline scrubber.
//  Used for both room-level spans (dashboard) and tab-level spans (room view).

import SwiftUI

// MARK: - Room Span Band (Dashboard Mode)

struct TimelineBandView: View {
    let span: TimelineSpan
    let totalStartMs: Int64
    let totalEndMs: Int64
    let isHovered: Bool

    private var color: Color {
        Color(hex: span.colorHex) ?? .gray
    }

    private var startFraction: Double {
        let range = Double(totalEndMs - totalStartMs)
        guard range > 0 else { return 0 }
        return Double(span.startMs - totalStartMs) / range
    }

    private var widthFraction: Double {
        let range = Double(totalEndMs - totalStartMs)
        guard range > 0 else { return 0 }
        return Double(span.endMs - span.startMs) / range
    }

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let x = startFraction * totalWidth
            let w = max(widthFraction * totalWidth, 4) // minimum 4px for visibility

            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .opacity(isHovered ? 0.65 : 0.85)
                .frame(width: w, height: geo.size.height)
                .offset(x: x)
        }
    }
}

// MARK: - Tab Span Band (Room Mode)

struct TimelineTabBandView: View {
    let span: TimelineTabSpan
    let totalStartMs: Int64
    let totalEndMs: Int64
    let isHovered: Bool

    private var startFraction: Double {
        let range = Double(totalEndMs - totalStartMs)
        guard range > 0 else { return 0 }
        return Double(span.startMs - totalStartMs) / range
    }

    private var widthFraction: Double {
        let range = Double(totalEndMs - totalStartMs)
        guard range > 0 else { return 0 }
        return Double(span.endMs - span.startMs) / range
    }

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let x = startFraction * totalWidth
            let w = max(widthFraction * totalWidth, 4)

            RoundedRectangle(cornerRadius: 4)
                .fill(span.color)
                .opacity(isHovered ? 0.65 : 0.85)
                .frame(width: w, height: geo.size.height)
                .offset(x: x)
        }
    }
}

// Color(hex:) extension defined in TerminalDirectoryPicker.swift
