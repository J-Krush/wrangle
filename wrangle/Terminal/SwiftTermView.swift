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
        super.init(frame: .zero)

        // Use manual frame management (not AutoLayout) so that setFrameSize:
        // is called on the terminal view during layout(). AutoLayout's internal
        // frame-setting bypasses setFrameSize:, which means SwiftTerm never
        // calls processSizeChange and keeps its initial 0×0 col/row count.
        addSubview(terminalView)
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
    @Environment(\.colorScheme) private var colorScheme

    static func == (lhs: SwiftTermView, rhs: SwiftTermView) -> Bool {
        lhs.session === rhs.session && lhs.isActive == rhs.isActive
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeNSView(context: Context) -> TerminalContainerView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        terminalView.processDelegate = context.coordinator
        context.coordinator.terminalView = terminalView

        // Apply theme
        context.coordinator.configureAppearance(terminalView)

        // Shift+Return handling for TUI apps (e.g., Claude Code multi-line input)
        context.coordinator.installKeyboardMonitor(for: terminalView)

        let container = TerminalContainerView(terminalView: terminalView)
        container.isActive = isActive
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
        container.isActive = isActive

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

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate, TerminalProcessController {
        let session: TerminalSession
        weak var terminalView: LocalProcessTerminalView?
        var lastColorScheme: ColorScheme?
        var isActive: Bool = false
        var processStarted: Bool = false
        fileprivate var keyboardMonitor: Any?

        init(session: TerminalSession) {
            self.session = session
            super.init()
            session.emulator.processController = self
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
    }
}
