import AppKit
import Foundation
@preconcurrency import SwiftTerm

/// Transparent overlay that renders underlines and hover cursors over
/// auto-detected URLs in the terminal. Sits above `URLAwareTerminalView` inside
/// `TerminalContainerView`. Passes through all mouse events — SwiftTerm handles
/// click routing itself (via the payload atoms we set on matched cells).
final class URLOverlayView: NSView {

    weak var terminalView: URLAwareTerminalView?

    /// Cached metrics refreshed on each draw.
    private var cellWidth: CGFloat = 0
    private var cellHeight: CGFloat = 0

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    /// Make the overlay invisible to event routing. Cmd+click lands on the
    /// terminal beneath us, where SwiftTerm's own mouseUp handler fires
    /// `requestOpenLink` for cells with a hyperlink payload.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let terminalView else { return }
        let spans = terminalView.detector.spans
        guard !spans.isEmpty else { return }
        refreshMetrics(for: terminalView)
        guard cellWidth > 0, cellHeight > 0 else { return }

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.controlAccentColor.withAlphaComponent(0.75).cgColor)
        ctx.setLineWidth(1.0)

        let yDisp = terminalView.terminal.buffer.yDisp
        let rows = terminalView.terminal.rows

        for viewportRow in 0..<rows {
            let absoluteRow = yDisp + viewportRow
            guard let rowSpans = spans[absoluteRow] else { continue }
            for span in rowSpans {
                let rect = cellRect(
                    viewportRow: viewportRow,
                    startCol: span.startCol,
                    endCol: span.endCol
                )
                guard rect.intersects(dirtyRect) else { continue }
                // Underline sits near the bottom of the cell.
                let underlineY = rect.maxY - 2
                ctx.beginPath()
                ctx.move(to: CGPoint(x: rect.minX, y: underlineY))
                ctx.addLine(to: CGPoint(x: rect.maxX, y: underlineY))
                ctx.strokePath()
            }
        }
        ctx.restoreGState()
    }

    // MARK: - Cursor

    override func resetCursorRects() {
        super.resetCursorRects()
        guard let terminalView else { return }
        let spans = terminalView.detector.spans
        guard !spans.isEmpty else { return }
        refreshMetrics(for: terminalView)
        guard cellWidth > 0, cellHeight > 0 else { return }

        let yDisp = terminalView.terminal.buffer.yDisp
        for viewportRow in 0..<terminalView.terminal.rows {
            let absoluteRow = yDisp + viewportRow
            guard let rowSpans = spans[absoluteRow] else { continue }
            for span in rowSpans {
                let rect = cellRect(
                    viewportRow: viewportRow,
                    startCol: span.startCol,
                    endCol: span.endCol
                )
                addCursorRect(rect, cursor: .pointingHand)
            }
        }
    }

    // MARK: - Helpers

    private func refreshMetrics(for tv: URLAwareTerminalView) {
        let cols = CGFloat(max(tv.terminal.cols, 1))
        let rows = CGFloat(max(tv.terminal.rows, 1))
        cellWidth = tv.bounds.width / cols
        cellHeight = tv.bounds.height / rows
    }

    private func cellRect(viewportRow: Int, startCol: Int, endCol: Int) -> NSRect {
        let x = CGFloat(startCol) * cellWidth
        let y = CGFloat(viewportRow) * cellHeight
        let width = CGFloat(endCol - startCol + 1) * cellWidth
        return NSRect(x: x, y: y, width: width, height: cellHeight)
    }
}
