import Foundation
import Testing
@preconcurrency import SwiftTerm

/// Regression tests for the two patches carried on the SwiftTerm fork the
/// project pins (J-Krush/SwiftTerm, branch `wrangle-patches`). If these fail
/// after moving the pin, the fixes regressed or were lost in the update; both
/// are candidates for upstreaming to migueldeicaza/SwiftTerm, after which the
/// pin can return to a stock release.
struct SwiftTermVendorPatchTests {

    private final class CapturingDelegate: TerminalDelegate {
        var sent: [UInt8] = []
        var titles: [String] = []
        func send(source: Terminal, data: ArraySlice<UInt8>) { sent.append(contentsOf: data) }
        func setTerminalTitle(source: Terminal, title: String) { titles.append(title) }
    }

    /// A feed-chunk boundary inside a multi-byte UTF-8 character of an OSC
    /// title used to end the OSC early (0x9c, the middle byte of '✳' and of
    /// every Claude Code spinner glyph, doubles as the 8-bit ST control) and
    /// spilled the rest of the title into the screen buffer.
    @Test func oscTitleSurvivesChunkSplitInsideUTF8Character() {
        let delegate = CapturingDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 40, rows: 5))

        let bytes = Array("\u{1b}]0;✳ Claude Code\u{07}hello".utf8)
        // Split inside '✳' (e2 9c b3): ESC ] 0 ; occupy indexes 0-3, e2 is 4.
        let splitAt = 5
        terminal.feed(buffer: bytes[0..<splitAt])
        terminal.feed(buffer: bytes[splitAt...])

        let row0 = terminal.getText(
            start: Position(col: 0, row: 0),
            end: Position(col: 39, row: 0)
        )
        #expect(row0.hasPrefix("hello"), "screen row got polluted by OSC payload: \(row0)")
        #expect(delegate.titles == ["✳ Claude Code"])
    }

    /// Hover motion reports carry "no button" flags (3) plus the motion bit
    /// (32). The SGR encoder used to detect release via `flags & 3 == 3`
    /// without excluding motion, sending hovers as left-button releases,
    /// which made mouse-reporting TUIs (Claude Code) click buttons on hover.
    @Test func hoverMotionIsNotEncodedAsLeftButtonRelease() {
        let delegate = CapturingDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 40, rows: 5))

        // Any-event mouse tracking + SGR encoding, as Claude Code enables.
        terminal.feed(text: "\u{1b}[?1003h\u{1b}[?1006h")
        delegate.sent.removeAll()

        let flags = terminal.encodeButton(
            button: 0, release: true, shift: false, meta: false, control: false
        )
        terminal.sendMotion(buttonFlags: flags, x: 4, y: 2, pixelX: 0, pixelY: 0)

        let report = String(bytes: delegate.sent, encoding: .utf8) ?? ""
        #expect(report == "\u{1b}[<35;5;3M", "hover must be motion-no-button 'M', got: \(report)")
    }
}
