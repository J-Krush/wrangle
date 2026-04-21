import AppKit
import Foundation
@preconcurrency import SwiftTerm

/// `LocalProcessTerminalView` subclass that scans the terminal buffer for
/// plain-text URLs after each burst of output, attaches OSC-8-style hyperlink
/// payloads to matched cells (so SwiftTerm's own Cmd+click handler finds them),
/// and exposes span metadata for the sibling `URLOverlayView` to draw underlines.
///
/// Click routing itself is done by `LinkInterceptingTerminalDelegate` below —
/// SwiftTerm's `requestOpenLink` lives in a protocol extension default, which
/// uses static dispatch, so a subclass override isn't visible through the
/// witness table. Replacing the `terminalDelegate` with a proxy is the clean
/// way to intercept the call.
final class URLAwareTerminalView: LocalProcessTerminalView {

    let detector = TerminalURLDetector()

    /// Called on the main actor after each rescan finishes. Lets the overlay
    /// know it should redraw.
    var onSpansChanged: (() -> Void)?

    /// Debouncer for buffer rescans. `dataReceived` fires in bursts; scanning
    /// after every slice would be wasteful.
    private var rescanTask: Task<Void, Never>?

    override func dataReceived(slice: ArraySlice<UInt8>) {
        super.dataReceived(slice: slice)
        scheduleRescan()
    }

    override func scrolled(source: TerminalView, position: Double) {
        super.scrolled(source: source, position: position)
        // Rescan the newly visible rows so scrollback URLs pick up underlines too.
        scheduleRescan()
    }

    private func scheduleRescan() {
        rescanTask?.cancel()
        rescanTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled, let self else { return }
            self.detector.rescan(terminal: self.terminal)
            self.onSpansChanged?()
        }
    }
}

/// Proxy `TerminalViewDelegate` that intercepts `requestOpenLink` and forwards
/// every other protocol method back to the wrapped `LocalProcessTerminalView`.
///
/// Needed because `LocalProcessTerminalView` already conforms to
/// `TerminalViewDelegate` at the superclass level and relies on the protocol
/// extension default for `requestOpenLink`. Swift resolves extension defaults
/// via static dispatch, so a subclass-provided override doesn't replace the
/// witness — we have to swap in a different delegate instance entirely.
final class LinkInterceptingTerminalDelegate: NSObject, TerminalViewDelegate {

    weak var wrapped: LocalProcessTerminalView?
    var onOpenLink: ((_ link: String, _ params: [String: String]) -> Void)?

    init(wrapping: LocalProcessTerminalView) {
        self.wrapped = wrapping
    }

    // MARK: Intercepted

    func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {
        if let onOpenLink {
            onOpenLink(link, params)
            return
        }
        // Fallback mirrors SwiftTerm's default behavior.
        if let fixedUp = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: fixedUp) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: Forwarded to LocalProcessTerminalView

    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        wrapped?.sizeChanged(source: source, newCols: newCols, newRows: newRows)
    }
    func setTerminalTitle(source: TerminalView, title: String) {
        wrapped?.setTerminalTitle(source: source, title: title)
    }
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        wrapped?.hostCurrentDirectoryUpdate(source: source, directory: directory)
    }
    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        wrapped?.send(source: source, data: data)
    }
    func scrolled(source: TerminalView, position: Double) {
        wrapped?.scrolled(source: source, position: position)
    }
    func clipboardCopy(source: TerminalView, content: Data) {
        wrapped?.clipboardCopy(source: source, content: content)
    }
    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
        wrapped?.rangeChanged(source: source, startY: startY, endY: endY)
    }

    // MARK: Extension defaults LocalProcessTerminalView doesn't override

    func bell(source: TerminalView) {
        NSSound.beep()
    }
    func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {
        // no-op — matches SwiftTerm's default implementation
    }
}
