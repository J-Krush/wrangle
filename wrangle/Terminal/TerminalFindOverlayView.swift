import AppKit
import Foundation
@preconcurrency import SwiftTerm

@MainActor
protocol TerminalFindControlling: AnyObject {
    func recomputeFindMatches()
    func advanceFindMatch(backwards: Bool)
    func invalidateFindOverlay()
}

/// Transparent overlay that highlights find-in-page matches over the terminal.
/// Modeled on `URLOverlayView`. Matches in the visible viewport get a yellow
/// background; the current match is orange.
final class TerminalFindOverlayView: NSView {

    weak var terminalView: LocalProcessTerminalView?
    weak var session: TerminalSession?

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let terminalView, let terminal = terminalView.terminal,
              let session, session.isFindBarVisible else { return }
        let matches = session.findMatches
        guard !matches.isEmpty else { return }

        let cols = max(terminal.cols, 1)
        let rows = max(terminal.rows, 1)
        let cellWidth = bounds.width / CGFloat(cols)
        let cellHeight = bounds.height / CGFloat(rows)
        guard cellWidth > 0, cellHeight > 0 else { return }

        let yDisp = terminal.buffer.yDisp
        let visibleStart = yDisp
        let visibleEnd = yDisp + rows

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }

        for (i, match) in matches.enumerated() {
            guard match.row >= visibleStart, match.row < visibleEnd else { continue }
            let viewportRow = match.row - yDisp
            let rect = NSRect(
                x: CGFloat(match.col) * cellWidth,
                y: CGFloat(viewportRow) * cellHeight,
                width: CGFloat(match.length) * cellWidth,
                height: cellHeight
            )
            let color: NSColor = (i == session.findCurrentIndex)
                ? NSColor.systemOrange.withAlphaComponent(0.55)
                : NSColor.systemYellow.withAlphaComponent(0.40)
            ctx.setFillColor(color.cgColor)
            ctx.fill(rect)
        }
    }
}
