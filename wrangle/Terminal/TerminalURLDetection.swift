import AppKit
import Foundation
@preconcurrency import SwiftTerm

/// Detects plain-text URLs in the terminal buffer, annotates them for Cmd+click,
/// and exposes their positions so an overlay view can draw visual underlines.
///
/// SwiftTerm only auto-detects URLs when the producing tool emits OSC 8 hyperlink
/// escape sequences — most CLIs don't. This class closes that gap by scanning the
/// visible buffer after each burst of output and (a) calling `setPayload` on
/// matched `CharData` ranges so SwiftTerm's own Cmd+click handling reaches
/// `requestOpenLink`, and (b) publishing the matched row/col spans for drawing.
///
/// Thread: all access MUST be on the main actor since it mutates the terminal
/// buffer SwiftTerm reads from its own draw loop.
@MainActor
final class TerminalURLDetector {

    /// One detected URL span within a single buffer row.
    struct Span: Equatable {
        /// CircularList row index (i.e. `viewportRow + yDisp`) — matches how
        /// `MacTerminalView.getPayload` indexes `displayBuffer.lines` when the
        /// user Cmd+clicks. Spans stored under this key are rendered by looking
        /// up `spans[viewportRow + yDisp]` at draw time.
        let row: Int
        /// Column of the first URL character (inclusive).
        let startCol: Int
        /// Column of the last URL character (inclusive).
        let endCol: Int
        /// The URL string (trimmed of trailing punctuation).
        let url: String
    }

    /// All URL spans currently marked in the buffer. Keyed by CircularList row.
    private(set) var spans: [Int: [Span]] = [:]

    /// Cache: URL string → TinyAtom. Reuses atoms across scans so we don't exhaust
    /// SwiftTerm's 16-bit atom table in long sessions.
    private var atomCache: [String: TinyAtom] = [:]

    /// Matches http:// and https:// URLs. Conservative character class — stops at
    /// whitespace and common delimiters. Trailing punctuation is trimmed separately.
    private static let urlRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"https?://[^\s<>"'`{}|\\^\[\]()]+"#,
            options: []
        )
    }()

    private static let trailingJunk: Set<Character> = [
        ".", ",", ";", ":", "!", "?", ")", "]", "}", ">", "'", "\"", "`"
    ]

    /// Scans the visible region of `terminal` for URLs, annotates matched cells
    /// with a payload atom (enabling Cmd+click), and refreshes `spans`.
    func rescan(terminal: Terminal) {
        var newSpans: [Int: [Span]] = [:]
        let rows = terminal.rows
        let yDisp = terminal.buffer.yDisp

        for viewportRow in 0..<rows {
            // getLine(row:) accesses buffer.lines[row + yDisp], the same CircularList
            // index that MacTerminalView.getPayload uses on Cmd+click. Using the
            // scroll-invariant variant instead would desync once `linesTop` increments.
            guard let line = terminal.getLine(row: viewportRow) else { continue }
            let circularRow = viewportRow + yDisp

            let (rowText, colMap) = extractText(from: line, terminal: terminal, cols: terminal.cols)
            guard !rowText.isEmpty else { continue }

            let nsText = rowText as NSString
            let matches = Self.urlRegex.matches(in: rowText, range: NSRange(location: 0, length: nsText.length))
            guard !matches.isEmpty else { continue }

            var rowSpans: [Span] = []
            for match in matches {
                var range = match.range
                // Trim trailing punctuation we overshot.
                while range.length > 0 {
                    let lastChar = nsText.character(at: range.location + range.length - 1)
                    guard let scalar = Unicode.Scalar(lastChar) else { break }
                    if Self.trailingJunk.contains(Character(scalar)) {
                        range.length -= 1
                    } else {
                        break
                    }
                }
                guard range.length > 0 else { continue }

                let url = nsText.substring(with: range)
                guard let startCol = colMap[safe: range.location],
                      let endCol = colMap[safe: range.location + range.length - 1]
                else { continue }

                annotate(line: line, from: startCol, to: endCol, url: url)
                rowSpans.append(Span(row: circularRow, startCol: startCol, endCol: endCol, url: url))
            }
            if !rowSpans.isEmpty {
                newSpans[circularRow] = rowSpans
            }
        }

        spans = newSpans
    }

    /// Clears all cached state. Call when the terminal is reset (e.g. `clear`).
    func reset() {
        spans.removeAll()
        atomCache.removeAll()
    }

    // MARK: - Private

    /// Walks a BufferLine and assembles its printable text, tracking the mapping
    /// from character index → column so we can translate regex ranges back to
    /// column ranges (CJK double-width cells mean indices and columns diverge).
    private func extractText(from line: BufferLine, terminal: Terminal, cols: Int) -> (text: String, colMap: [Int]) {
        var text = ""
        var colMap: [Int] = []
        text.reserveCapacity(cols)
        colMap.reserveCapacity(cols)

        for col in 0..<cols {
            let cd = line[col]
            let ch = terminal.getCharacter(for: cd)
            // Skip null fillers used for unused / double-width trailing cells.
            guard ch != "\0" else { continue }
            text.append(ch)
            colMap.append(col)
        }
        return (text, colMap)
    }

    /// Marks cells `from..=to` on `line` with a payload pointing at `url`.
    /// Setting payload makes SwiftTerm's built-in Cmd+click handler route the
    /// click to `TerminalViewDelegate.requestOpenLink`, which our coordinator
    /// overrides to dispatch via LinkRouter.
    private func annotate(line: BufferLine, from: Int, to: Int, url: String) {
        // SwiftTerm's urlAndParamsFrom parser expects "params;url" (the OSC 8
        // payload format). We have no params, so store ";url" — the leading
        // semicolon yields split.count == 2, and the parser returns (url, [:]).
        let payload = ";" + url
        let atom: TinyAtom
        if let cached = atomCache[payload] {
            atom = cached
        } else if let fresh = TinyAtom.lookup(value: payload) {
            atomCache[payload] = fresh
            atom = fresh
        } else {
            return
        }

        for col in from...to {
            var cd = line[col]
            cd.setPayload(atom: atom)
            line[col] = cd
        }
    }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
