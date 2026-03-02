import Foundation

/// Pure string helpers for line-level editing operations.
/// Isolates string logic from NSTextView concerns so it's testable.
enum LineOperations {

    /// Expands an NSRange to cover complete lines in the given string.
    static func expandToFullLines(in string: NSString, range: NSRange) -> NSRange {
        string.lineRange(for: range)
    }

    /// Prepends `indent` (default 4 spaces) to each line in the text.
    static func indentLines(_ text: String, indent: String = "    ") -> String {
        let lines = text.components(separatedBy: "\n")
        // Don't indent a trailing empty line (artifact of lineRange ending at \n)
        return lines.enumerated().map { index, line in
            if index == lines.count - 1 && line.isEmpty { return line }
            return indent + line
        }.joined(separator: "\n")
    }

    /// Removes up to `width` leading spaces (or 1 tab) per line.
    static func dedentLines(_ text: String, width: Int = 4) -> String {
        let lines = text.components(separatedBy: "\n")
        return lines.enumerated().map { index, line in
            if index == lines.count - 1 && line.isEmpty { return line }
            if line.hasPrefix("\t") {
                return String(line.dropFirst())
            }
            var removed = 0
            var start = line.startIndex
            while removed < width, start < line.endIndex, line[start] == " " {
                start = line.index(after: start)
                removed += 1
            }
            return String(line[start...])
        }.joined(separator: "\n")
    }

    /// Return value for smart-enter continuation detection.
    enum ContinuationAction {
        /// Insert newline + the given prefix to continue the list/quote.
        case continueWith(String)
        /// Clear the empty prefix line (exit list mode).
        /// `clearRange` is relative to the line start.
        case exitList(clearLength: Int)
        /// No special handling — use default newline.
        case none
    }

    // Cached regexes for continuation detection
    private static let bulletRegex = try! NSRegularExpression(pattern: #"^(\s*[-*]\s+)(\S.*)$"#)
    private static let emptyBulletRegex = try! NSRegularExpression(pattern: #"^(\s*[-*]\s+)$"#)
    private static let numberedRegex = try! NSRegularExpression(pattern: #"^(\s*)(\d+)(\.\s+)(\S.*)$"#)
    private static let emptyNumberedRegex = try! NSRegularExpression(pattern: #"^(\s*)(\d+)(\.\s+)$"#)
    private static let blockquoteRegex = try! NSRegularExpression(pattern: #"^(>\s?)(\S.*)$"#)
    private static let emptyBlockquoteRegex = try! NSRegularExpression(pattern: #"^(>\s?)$"#)

    /// Detects whether the given line text should trigger smart-enter continuation.
    /// Only triggers when cursor is at end of line (`cursorAtEOL` = true).
    static func detectContinuationPrefix(for lineText: String, cursorAtEOL: Bool) -> ContinuationAction {
        guard cursorAtEOL else { return .none }

        let nsLine = lineText as NSString
        let fullRange = NSRange(location: 0, length: nsLine.length)

        // Empty bullet line → exit
        if let m = emptyBulletRegex.firstMatch(in: lineText, range: fullRange) {
            return .exitList(clearLength: m.range.length)
        }
        // Bullet with content → continue
        if let m = bulletRegex.firstMatch(in: lineText, range: fullRange) {
            let prefix = nsLine.substring(with: m.range(at: 1))
            // Normalize to "- " preserving indent
            let indent = prefix.prefix(while: { $0 == " " || $0 == "\t" })
            return .continueWith(indent + "- ")
        }

        // Empty numbered line → exit
        if let m = emptyNumberedRegex.firstMatch(in: lineText, range: fullRange) {
            return .exitList(clearLength: m.range.length)
        }
        // Numbered with content → continue with incremented number
        if let m = numberedRegex.firstMatch(in: lineText, range: fullRange) {
            let indent = nsLine.substring(with: m.range(at: 1))
            let numStr = nsLine.substring(with: m.range(at: 2))
            let suffix = nsLine.substring(with: m.range(at: 3))
            let nextNum = (Int(numStr) ?? 0) + 1
            return .continueWith(indent + "\(nextNum)" + suffix)
        }

        // Empty blockquote → exit
        if let m = emptyBlockquoteRegex.firstMatch(in: lineText, range: fullRange) {
            return .exitList(clearLength: m.range.length)
        }
        // Blockquote with content → continue
        if blockquoteRegex.firstMatch(in: lineText, range: fullRange) != nil {
            return .continueWith("> ")
        }

        return .none
    }
}
