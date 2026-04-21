import AppKit
import SwiftUI

/// A thin, draggable resize handle that owns both its hover cursor and its drag
/// tracking through AppKit directly — no SwiftUI `.onHover` and no
/// `NSCursor.push`/`pop`. AppKit's cursor-rect and mouse-event machinery handle
/// both concerns, so the window's cursor stack stays clean (the bug we hit when
/// two SwiftUI handles were leaking orphaned `pop()` calls onto the stack and
/// flickering the editor's I-beam cursor to arrow).
///
/// Consumers supply an axis and a drag callback. The callback receives the
/// cumulative translation since `mouseDown`, matching SwiftUI `DragGesture`
/// semantics so swap sites stay mechanical.
struct ResizeHandle: NSViewRepresentable {
    enum Axis { case horizontal, vertical }

    let axis: Axis
    let onDragged: (CGFloat) -> Void
    let onEnded: () -> Void

    func makeNSView(context: Context) -> ResizeHandleNSView {
        let view = ResizeHandleNSView()
        view.axis = axis
        view.onDragged = onDragged
        view.onEnded = onEnded
        return view
    }

    func updateNSView(_ nsView: ResizeHandleNSView, context: Context) {
        nsView.axis = axis
        nsView.onDragged = onDragged
        nsView.onEnded = onEnded
    }
}

final class ResizeHandleNSView: NSView {
    var axis: ResizeHandle.Axis = .horizontal
    var onDragged: ((CGFloat) -> Void)?
    var onEnded: (() -> Void)?

    private var dragStart: NSPoint?

    override func resetCursorRects() {
        super.resetCursorRects()
        let cursor: NSCursor = axis == .horizontal ? .resizeLeftRight : .resizeUpDown
        addCursorRect(bounds, cursor: cursor)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragStart = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart else { return }
        let current = event.locationInWindow
        let translation: CGFloat = axis == .horizontal
            ? current.x - start.x
            : current.y - start.y
        onDragged?(translation)
    }

    override func mouseUp(with event: NSEvent) {
        dragStart = nil
        onEnded?()
    }
}
