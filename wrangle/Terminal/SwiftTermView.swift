//
//  SwiftTermView.swift
//  wrangle
//

@preconcurrency import SwiftTerm
import SwiftUI
import AppKit

/// Protocol allowing TerminalEmulator (state model) to delegate actions
/// to the SwiftTermView.Coordinator which owns the actual process.
@MainActor
protocol TerminalProcessController: AnyObject {
    func terminateProcess()
    func restartProcess(in directory: URL?)
    func sendString(_ string: String)
}

// MARK: - TerminalContainerView (drag-and-drop target)

/// Wraps a `LocalProcessTerminalView` to add file drag-and-drop support.
/// We can't subclass `LocalProcessTerminalView` (it's `public`, not `open`),
/// so this container registers for dragged types and forwards dropped file
/// paths as shell-escaped text into the terminal process.
class TerminalContainerView: NSView {
    let terminalView: LocalProcessTerminalView
    /// Overlay sibling that draws URL underlines + hover cursors. Only present
    /// when the terminal view is the URL-aware subclass.
    private let urlOverlay: URLOverlayView?
    /// Overlay sibling that highlights find-in-page matches. Always present so
    /// the controller can invalidate it on demand.
    let findOverlay = TerminalFindOverlayView(frame: .zero)
    /// Called once when the container first receives a non-zero frame, so the
    /// shell process can start with the correct terminal column/row count.
    var onFirstLayout: (() -> Void)?
    var isActive: Bool = false {
        didSet {
            guard isActive != oldValue else { return }
            if isActive {
                registerForDraggedTypes([.fileURL])
            } else {
                unregisterDraggedTypes()
            }
        }
    }

    /// Insets applied around the terminal view for visual padding.
    /// These are handled here (not via SwiftUI .padding()) so SwiftTerm's
    /// frame and reported terminal dimensions stay in sync.
    private static let insets = NSEdgeInsets(top: 6, left: 8, bottom: 0, right: 8)

    init(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        if let urlAware = terminalView as? URLAwareTerminalView {
            let overlay = URLOverlayView(frame: .zero)
            overlay.terminalView = urlAware
            self.urlOverlay = overlay
        } else {
            self.urlOverlay = nil
        }
        super.init(frame: .zero)

        // Use manual frame management (not AutoLayout) so that setFrameSize:
        // is called on the terminal view during layout(). AutoLayout's internal
        // frame-setting bypasses setFrameSize:, which means SwiftTerm never
        // calls processSizeChange and keeps its initial 0×0 col/row count.
        addSubview(terminalView)
        if let overlay = urlOverlay {
            addSubview(overlay, positioned: .above, relativeTo: terminalView)

            // Repaint overlay + refresh cursor rects whenever the detector
            // finds a new set of URL spans.
            (terminalView as? URLAwareTerminalView)?.onSpansChanged = { [weak self] in
                guard let self, let overlay = self.urlOverlay else { return }
                overlay.needsDisplay = true
                self.window?.invalidateCursorRects(for: overlay)
            }
        }
        findOverlay.terminalView = terminalView
        addSubview(findOverlay, positioned: .above, relativeTo: urlOverlay ?? terminalView)
        // Drag type registration is managed dynamically via isActive didSet
    }

    override func layout() {
        super.layout()
        // Manually position the terminal view with insets. Using manual frame
        // management instead of AutoLayout ensures setFrameSize: is called,
        // which triggers SwiftTerm's processSizeChange to update col/row count.
        let insets = Self.insets
        let termFrame = NSRect(
            x: insets.left,
            y: insets.bottom,
            width: max(0, bounds.width - insets.left - insets.right),
            height: max(0, bounds.height - insets.top - insets.bottom)
        )
        // Only set frame when it actually changed — setting it during a mouse
        // drag interrupts SwiftTerm's selection tracking.
        if terminalView.frame != termFrame {
            terminalView.frame = termFrame
        }
        // Overlay shadows the terminal frame exactly.
        if let overlay = urlOverlay, overlay.frame != termFrame {
            overlay.frame = termFrame
        }
        if findOverlay.frame != termFrame {
            findOverlay.frame = termFrame
        }

        if bounds.width > 0, let callback = onFirstLayout {
            onFirstLayout = nil
            callback()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Hit Testing

    /// Inactive terminals must be fully transparent to AppKit event routing.
    /// SwiftUI's `.allowsHitTesting(false)` only gates SwiftUI-level events;
    /// stacked NSViewRepresentable views still receive AppKit drag-and-drop
    /// and mouse events. Returning nil here ensures only the active terminal
    /// participates in hit testing, drag destination resolution, and focus.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard isActive else { return nil }
        return super.hitTest(point)
    }

    // MARK: - Mouse Selection (Option-key toggle)

    /// Monitor that restores mouse reporting after an Option-drag selection.
    private var mouseUpMonitor: Any?

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(terminalView)

        // Hold Option to enable mouse reporting for TUI apps (vim, htop, etc.).
        // Default is text selection; Option+click temporarily forwards mouse
        // events to the running program instead.
        if event.modifierFlags.contains(.option) && !terminalView.allowMouseReporting {
            terminalView.allowMouseReporting = true

            // Use a local event monitor to catch mouseUp reliably — the container
            // won't receive it because AppKit routes drag/up to the terminal view.
            mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] upEvent in
                guard let self else { return upEvent }
                self.terminalView.allowMouseReporting = false
                if let monitor = self.mouseUpMonitor {
                    NSEvent.removeMonitor(monitor)
                    self.mouseUpMonitor = nil
                }
                return upEvent
            }
        }

        super.mouseDown(with: event)
    }

    // MARK: - NSDraggingDestination

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard isActive else { return [] }
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) ? .copy : []
    }

    override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard isActive else { return false }
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard isActive else { return false }
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !urls.isEmpty else {
            return false
        }
        let paths = urls.map { shellEscape($0.path(percentEncoded: false)) }
        let text = paths.joined(separator: " ")
        guard let data = text.data(using: .utf8) else { return false }
        terminalView.process.send(data: ArraySlice(data))
        return true
    }

    private func shellEscape(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

// MARK: - SwiftTermView

struct SwiftTermView: NSViewRepresentable, Equatable {
    let session: TerminalSession
    var isActive: Bool = false
    /// Passed through so OSC 8 hyperlink clicks (e.g. from Claude Code) route
    /// through LinkRouter instead of bouncing out to Safari via NSWorkspace.open.
    let appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    static func == (lhs: SwiftTermView, rhs: SwiftTermView) -> Bool {
        lhs.session === rhs.session && lhs.isActive == rhs.isActive && lhs.appState === rhs.appState
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session, appState: appState)
    }

    func makeNSView(context: Context) -> TerminalContainerView {
        let terminalView = URLAwareTerminalView(frame: .zero)
        terminalView.processDelegate = context.coordinator
        context.coordinator.terminalView = terminalView

        // Intercept Cmd+click on hyperlink-payload cells so URLs open in-app.
        // SwiftTerm's default TerminalViewDelegate extension opens via NSWorkspace,
        // and a subclass override isn't dispatched (see LinkInterceptingTerminalDelegate
        // docstring). Replacing the terminalDelegate with our proxy is the fix.
        let interceptor = LinkInterceptingTerminalDelegate(wrapping: terminalView)
        interceptor.onOpenLink = { [weak coordinator = context.coordinator] link, _ in
            guard let coordinator, let appState = coordinator.appState else { return }
            _ = LinkRouter.open(
                link,
                relativeTo: coordinator.session.emulator.workingDirectory,
                appState: appState
            )
        }
        terminalView.terminalDelegate = interceptor
        context.coordinator.linkInterceptor = interceptor

        // Apply theme
        context.coordinator.configureAppearance(terminalView)

        // Shift+Return handling for TUI apps (e.g., Claude Code multi-line input)
        context.coordinator.installKeyboardMonitor(for: terminalView)

        let container = TerminalContainerView(terminalView: terminalView)
        container.isActive = isActive
        container.isHidden = !isActive
        container.findOverlay.session = session
        context.coordinator.container = container
        context.coordinator.isActive = isActive

        // Defer process start until the container has a valid frame so SwiftTerm
        // calculates the correct terminal column/row count. Starting with frame
        // .zero causes misaligned cursor positioning in TUI banners (e.g., Claude
        // Code's startup header overlapping text).
        let coordinator = context.coordinator
        container.onFirstLayout = { [weak coordinator] in
            guard let coordinator else { return }
            coordinator.processStarted = true
            coordinator.startProcess(in: terminalView)
        }

        return container
    }

    func updateNSView(_ container: TerminalContainerView, context: Context) {
        let terminalView = container.terminalView

        // Detect activation transition to force SwiftTerm dimension recalculation
        let wasActive = context.coordinator.isActive

        // Sync isActive state to coordinator and container
        context.coordinator.isActive = isActive
        context.coordinator.appState = appState
        container.isActive = isActive
        container.isHidden = !isActive

        // Force SwiftTerm to recalculate cols/rows when tab becomes active.
        // Inactive terminals in the ZStack may miss frame changes during resize.
        if isActive && !wasActive && context.coordinator.processStarted {
            terminalView.setFrameSize(terminalView.frame.size)
            terminalView.needsDisplay = true
        }

        if context.coordinator.lastColorScheme != colorScheme {
            context.coordinator.lastColorScheme = colorScheme
            context.coordinator.configureAppearance(terminalView)
        }

        // When this terminal tab becomes active, claim keyboard focus
        if isActive, let window = terminalView.window, window.firstResponder !== terminalView {
            window.makeFirstResponder(terminalView)
        }
    }

    static func dismantleNSView(_ container: TerminalContainerView, coordinator: Coordinator) {
        coordinator.isActive = false
        container.isActive = false
        if let monitor = coordinator.keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            coordinator.keyboardMonitor = nil
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate, TerminalProcessController, TerminalFindControlling {
        let session: TerminalSession
        weak var appState: AppState?
        weak var terminalView: LocalProcessTerminalView?
        weak var container: TerminalContainerView?
        var lastColorScheme: ColorScheme?
        var isActive: Bool = false
        var processStarted: Bool = false
        fileprivate var keyboardMonitor: Any?
        /// Strong-held proxy that intercepts URL Cmd+clicks. SwiftTerm holds the
        /// `terminalDelegate` weakly, so the coordinator must retain it.
        var linkInterceptor: LinkInterceptingTerminalDelegate?

        init(session: TerminalSession, appState: AppState) {
            self.session = session
            self.appState = appState
            super.init()
            session.emulator.processController = self
            session.findController = self
        }

        deinit {
            if let monitor = keyboardMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        /// Intercepts special key combinations and sends appropriate escape sequences.
        func installKeyboardMonitor(for terminalView: LocalProcessTerminalView) {
            keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak terminalView] event in
                guard let self, self.isActive,
                      let terminalView,
                      let window = terminalView.window,
                      window.firstResponder === terminalView else {
                    return event
                }

                // CMD+F: toggle find bar (consume so shell doesn't see it).
                let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                if mods == .command,
                   event.charactersIgnoringModifiers?.lowercased() == "f" {
                    MainActor.assumeIsolated {
                        self.session.toggleFindBar()
                    }
                    return nil
                }

                // Shift+Return: send kitty keyboard protocol ESC[13;2u
                if event.keyCode == 36 && event.modifierFlags.contains(.shift) {
                    let escSeq: [UInt8] = [0x1B, 0x5B, 0x31, 0x33, 0x3B, 0x32, 0x75]
                    terminalView.process.send(data: ArraySlice(escSeq))
                    return nil
                }

                // fn+Arrow keys (Home/End/PageUp/PageDown)
                if let escSeq = Self.fnKeySequence(for: event) {
                    terminalView.process.send(data: ArraySlice(escSeq))
                    return nil
                }

                return event
            }
        }

        /// Returns the escape sequence for fn+arrow key events, or nil if not applicable.
        private static func fnKeySequence(for event: NSEvent) -> [UInt8]? {
            // These keyCodes are generated when fn+arrow is pressed on macOS
            switch event.keyCode {
            case 115: // Home (fn+Left)
                return [0x1B, 0x5B, 0x48]           // ESC[H
            case 119: // End (fn+Right)
                return [0x1B, 0x5B, 0x46]           // ESC[F
            case 116: // Page Up (fn+Up)
                return [0x1B, 0x5B, 0x35, 0x7E]     // ESC[5~
            case 121: // Page Down (fn+Down)
                return [0x1B, 0x5B, 0x36, 0x7E]     // ESC[6~
            case 117: // Forward Delete (fn+Delete)
                return [0x1B, 0x5B, 0x33, 0x7E]     // ESC[3~
            default:
                return nil
            }
        }

        // MARK: - Process Lifecycle

        func startProcess(in terminalView: LocalProcessTerminalView) {
            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

            // Build environment inheriting parent's env
            var env = ProcessInfo.processInfo.environment
            env["TERM"] = "xterm-256color"
            env["COLORTERM"] = "truecolor"
            env["LANG"] = "en_US.UTF-8"
            env["WRANGLE_SESSION_ID"] = session.id.uuidString
            let envStrings = env.map { "\($0.key)=\($0.value)" }

            let currentDir = session.workingDirectory?.path(percentEncoded: false)

            terminalView.startProcess(
                executable: shell,
                args: ["-l"],
                environment: envStrings,
                currentDirectory: currentDir
            )

            session.emulator.isRunning = true

            // Send pending command (e.g., Claude Code launch) after shell initializes
            if let command = session.pendingCommand {
                session.pendingCommand = nil
                Task { @MainActor [weak terminalView] in
                    try? await Task.sleep(for: .milliseconds(500))
                    guard let data = command.data(using: .utf8) else { return }
                    terminalView?.process.send(data: ArraySlice(data))
                }
            }
        }

        func configureAppearance(_ terminalView: LocalProcessTerminalView) {
            let theme = Theme.current
            terminalView.nativeForegroundColor = theme.terminalForeground
            terminalView.nativeBackgroundColor = theme.terminalBackground
            terminalView.selectedTextBackgroundColor = theme.terminalSelection
            terminalView.caretColor = theme.terminalCursor
            terminalView.font = theme.terminalFont
            terminalView.optionAsMetaKey = true
            terminalView.allowMouseReporting = false
            TerminalPalette.install(on: terminalView)
        }

        // MARK: - LocalProcessTerminalViewDelegate

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            Task { @MainActor in
                session.emulator.terminalCols = newCols
                session.emulator.terminalRows = newRows
            }
        }

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            Task { @MainActor in
                session.emulator.title = title

                // Downgrade auto-detected Claude sessions when title reverts to a shell name
                if session.wasAutoDetected {
                    let genericShells: Set<String> = ["bash", "zsh", "sh", "fish", "tcsh", "csh", "ksh", "dash"]
                    if genericShells.contains(title.lowercased()) {
                        session.downgradeFromClaudeSession()
                    }
                }
            }
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            guard let dir = directory else { return }
            Task { @MainActor in
                session.emulator.workingDirectory = URL(fileURLWithPath: dir)
                session.updateDetectedClaudeFile()
                session.refreshSessionContext()
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            Task { @MainActor in
                session.emulator.isRunning = false
                session.handleProcessExit()
            }
        }

        // MARK: - TerminalProcessController

        func terminateProcess() {
            terminalView?.terminate()
        }

        func restartProcess(in directory: URL?) {
            terminateProcess()
            if let directory {
                session.emulator.workingDirectory = directory
            }
            if let tv = terminalView {
                startProcess(in: tv)
            }
        }

        func sendString(_ string: String) {
            guard let data = string.data(using: .utf8) else { return }
            terminalView?.process.send(data: ArraySlice(data))
        }

        // MARK: - TerminalFindControlling

        /// Walk every line of the visible scrollback (rows 0..<rows of the visible
        /// window plus what's above it, up through the bottom of the buffer) and
        /// collect every match. Uses public SwiftTerm APIs only — `getCharData`
        /// and `getText` — so we don't depend on internal buffer types.
        func recomputeFindMatches() {
            guard let terminalView, let terminal = terminalView.terminal else { return }
            let query = session.findQuery
            guard !query.isEmpty else {
                session.findMatches = []
                session.findCurrentIndex = 0
                container?.findOverlay.needsDisplay = true
                return
            }

            // Pull the entire scrollback as a string, one row per line. We pass a huge
            // end-row that getText clamps to lines.count-1 internally.
            let cols = max(terminal.cols, 1)
            let endRow = 1_000_000
            let fullText = terminal.getText(
                start: Position(col: 0, row: 0),
                end: Position(col: cols - 1, row: endRow)
            )

            // Convert to per-row strings. SwiftTerm's getText emits each line as the
            // visible characters concatenated — there is no implicit newline between
            // rows, so we need a different approach. Walk row-by-row using getText
            // for each row (1 row = one Position-pair). This is O(rows * chars) but
            // scrollback is bounded.
            session.findMatches = []
            session.findCurrentIndex = 0

            // We don't know the exact total scrollback length via public API, so use
            // the same trick: ask getText for one row at a time starting at row 0 and
            // stop when we get an empty result for several rows in a row (rare in real
            // shells, but a safety net).
            //
            // Better: use getCharData(col:row:) for the visible window, plus walk
            // upward from yDisp to row 0 using the same. This bounds work to the
            // current buffer extent without needing internal APIs.
            _ = fullText  // silence unused-warning; we use the row-by-row path below

            let yDisp = terminal.buffer.yDisp
            let rows = terminal.rows
            // Search range: from row 0 up to yDisp + rows. Anything past that is the
            // alternate screen and not part of normal scrollback we care about.
            let searchEnd = yDisp + rows
            let options: NSString.CompareOptions = session.findCaseSensitive ? [] : [.caseInsensitive]

            for row in 0..<searchEnd {
                let line = terminal.getText(
                    start: Position(col: 0, row: row),
                    end: Position(col: cols - 1, row: row)
                )
                guard !line.isEmpty else { continue }
                let ns = line as NSString
                var searchRange = NSRange(location: 0, length: ns.length)
                while searchRange.length > 0 {
                    let found = ns.range(of: query, options: options, range: searchRange)
                    guard found.location != NSNotFound else { break }
                    session.findMatches.append(TerminalSession.FindMatch(
                        row: row,
                        col: found.location,
                        length: found.length
                    ))
                    let next = found.location + max(found.length, 1)
                    if next >= ns.length { break }
                    searchRange = NSRange(location: next, length: ns.length - next)
                }
            }

            // Default to the first match in (or nearest below) the visible viewport.
            if let firstVisible = session.findMatches.firstIndex(where: { $0.row >= yDisp }) {
                session.findCurrentIndex = firstVisible
                scrollToCurrentMatch()
            } else if !session.findMatches.isEmpty {
                session.findCurrentIndex = 0
                scrollToCurrentMatch()
            }
            container?.findOverlay.needsDisplay = true
        }

        func advanceFindMatch(backwards: Bool) {
            guard !session.findMatches.isEmpty else { return }
            let count = session.findMatches.count
            session.findCurrentIndex = backwards
                ? (session.findCurrentIndex - 1 + count) % count
                : (session.findCurrentIndex + 1) % count
            scrollToCurrentMatch()
            container?.findOverlay.needsDisplay = true
        }

        func invalidateFindOverlay() {
            container?.findOverlay.needsDisplay = true
        }

        private func scrollToCurrentMatch() {
            guard let terminalView, let terminal = terminalView.terminal,
                  session.findMatches.indices.contains(session.findCurrentIndex) else { return }
            let match = session.findMatches[session.findCurrentIndex]
            let rows = terminal.rows
            let halfWindow = max(rows / 2, 1)
            let target = max(0, match.row - halfWindow)
            if terminal.buffer.yDisp != target {
                terminal.buffer.yDisp = target
                terminalView.needsDisplay = true
            }
        }
    }
}
