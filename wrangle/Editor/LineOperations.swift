import Foundation

enum OrderedListStyle {
    case numeric      // 1, 2, 3
    case lowerAlpha   // a, b, c
    case upperAlpha   // A, B, C
    case lowerRoman   // i, ii, iii
    case upperRoman   // I, II, III
}

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

    // MARK: - List Line Detection

    private static let listLineRegex = try! NSRegularExpression(pattern: #"^\s*(?:[-*+]|(?:\d+|[a-zA-Z]+)\.)\s"#)

    static func isListLine(_ text: String) -> Bool {
        let range = NSRange(location: 0, length: (text as NSString).length)
        return listLineRegex.firstMatch(in: text, range: range) != nil
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
    private static let orderedRegex = try! NSRegularExpression(pattern: #"^(\s*)(\d+|[a-zA-Z]+)(\.\s+)(\S.*)$"#)
    private static let emptyOrderedRegex = try! NSRegularExpression(pattern: #"^(\s*)(\d+|[a-zA-Z]+)(\.\s+)$"#)
    private static let blockquoteRegex = try! NSRegularExpression(pattern: #"^(>\s?)(\S.*)$"#)
    private static let emptyBlockquoteRegex = try! NSRegularExpression(pattern: #"^(>\s?)$"#)

    /// Detects whether the given line text should trigger smart-enter continuation.
    /// Only triggers when cursor is at end of line (`cursorAtEOL` = true).
    static func detectContinuationPrefix(
        for lineText: String,
        cursorAtEOL: Bool,
        orderedListStyleHint: OrderedListStyle? = nil
    ) -> ContinuationAction {
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

        // Empty ordered line → exit
        if let m = emptyOrderedRegex.firstMatch(in: lineText, range: fullRange) {
            return .exitList(clearLength: m.range.length)
        }
        // Ordered with content → continue with incremented marker
        if let m = orderedRegex.firstMatch(in: lineText, range: fullRange) {
            let indent = nsLine.substring(with: m.range(at: 1))
            let marker = nsLine.substring(with: m.range(at: 2))
            let suffix = nsLine.substring(with: m.range(at: 3))
            // Use explicit style hint if set, otherwise infer from indent level
            let effectiveHint = orderedListStyleHint ?? styleForIndentLevel(indent.count / 4)
            let nextMarker = nextOrderedMarker(after: marker, styleHint: effectiveHint)
            return .continueWith(indent + nextMarker + suffix)
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

    // MARK: - Ordered List Helpers

    /// Determines the next ordered list marker.
    /// Single chars like "i" default to alpha unless styleHint says roman.
    private static func nextOrderedMarker(after marker: String, styleHint: OrderedListStyle?) -> String {
        // 1. Numeric
        if let num = Int(marker) { return "\(num + 1)" }

        // 2. Multi-char: check if valid roman numeral
        if marker.count > 1 {
            if let roman = romanToInt(marker.lowercased()) {
                let next = intToRoman(roman + 1)
                return marker.first!.isUppercase ? next.uppercased() : next
            }
        }

        // 3. Single char with roman style hint
        if marker.count == 1, let hint = styleHint,
           (hint == .lowerRoman || hint == .upperRoman) {
            if let roman = romanToInt(marker.lowercased()) {
                let next = intToRoman(roman + 1)
                return hint == .upperRoman ? next.uppercased() : next
            }
        }

        // 4. Alpha: "a" → "b", "z" → "aa", "A" → "B"
        return nextAlpha(after: marker)
    }

    private static let romanValues: [(String, Int)] = [
        ("m", 1000), ("cm", 900), ("d", 500), ("cd", 400),
        ("c", 100), ("xc", 90), ("l", 50), ("xl", 40),
        ("x", 10), ("ix", 9), ("v", 5), ("iv", 4), ("i", 1)
    ]

    static func romanToInt(_ s: String) -> Int? {
        var result = 0
        var remaining = s[s.startIndex...]
        for (roman, value) in romanValues {
            while remaining.hasPrefix(roman) {
                result += value
                remaining = remaining.dropFirst(roman.count)
            }
        }
        // Valid only if we consumed the entire string and got a positive result
        guard remaining.isEmpty && result > 0 else { return nil }
        // Validate by round-tripping
        guard intToRoman(result) == s else { return nil }
        return result
    }

    static func intToRoman(_ n: Int) -> String {
        var result = ""
        var remaining = n
        for (roman, value) in romanValues {
            while remaining >= value {
                result += roman
                remaining -= value
            }
        }
        return result
    }

    private static func nextAlpha(after marker: String) -> String {
        guard let last = marker.last, let ascii = last.asciiValue else { return marker }
        if last == "z" { return marker + "a" }
        if last == "Z" { return marker + "A" }
        return String(marker.dropLast()) + String(UnicodeScalar(ascii + 1))
    }

    // MARK: - Multi-line Prefix Toggle

    /// Regex to detect any ordered list marker at line start: "1. ", "a. ", "IV. ", etc.
    private static let orderedPrefixRegex = try! NSRegularExpression(pattern: #"^(\s*)(\d+|[a-zA-Z]+)\.\s+"#)
    /// Regex to detect bullet prefix at line start: "- ", "* "
    private static let bulletPrefixRegex = try! NSRegularExpression(pattern: #"^(\s*)[-*+]\s+"#)

    /// Returns (indent length, total prefix length) for an ordered list prefix, or nil if none found.
    /// E.g. "    1. text" → (indent: 4, total: 7)
    static func orderedPrefixLength(in line: String) -> (indent: Int, total: Int)? {
        let range = NSRange(location: 0, length: (line as NSString).length)
        guard let m = orderedPrefixRegex.firstMatch(in: line, range: range) else { return nil }
        return (indent: m.range(at: 1).length, total: m.range.length)
    }

    /// Returns (indent length, total prefix length) for a bullet list prefix, or nil if none found.
    /// E.g. "    - text" → (indent: 4, total: 6)
    static func bulletPrefixLength(in line: String) -> (indent: Int, total: Int)? {
        let range = NSRange(location: 0, length: (line as NSString).length)
        guard let m = bulletPrefixRegex.firstMatch(in: line, range: range) else { return nil }
        return (indent: m.range(at: 1).length, total: m.range.length)
    }

    /// Toggles a line prefix across multiple lines.
    /// For numbered/alpha/roman lists, generates sequential markers.
    /// If ALL non-empty lines already have the same list type, removes them (toggle off).
    static func toggleLinePrefixes(lines: [String], prefix: String) -> String {
        let isBullet = prefix == "- " || prefix == "* " || prefix == "+ "

        let nonEmptyLines = lines.enumerated().filter { !$1.isEmpty }

        // Helper: extract (indent, content after prefix) from a line, stripping only the marker
        func splitListPrefix(_ line: String) -> (indent: String, content: String) {
            let ns = line as NSString
            let range = NSRange(location: 0, length: ns.length)
            if let m = orderedPrefixRegex.firstMatch(in: line, range: range) {
                let indent = ns.substring(with: m.range(at: 1))
                let content = ns.substring(from: m.range.location + m.range.length)
                return (indent, content)
            }
            if let m = bulletPrefixRegex.firstMatch(in: line, range: range) {
                let indent = ns.substring(with: m.range(at: 1))
                let content = ns.substring(from: m.range.location + m.range.length)
                return (indent, content)
            }
            return ("", line)
        }

        // Check what existing prefixes the non-empty lines have
        let allHaveBullets = nonEmptyLines.allSatisfy { _, line in
            bulletPrefixLength(in: line) != nil
        }
        let allHaveOrdered = nonEmptyLines.allSatisfy { _, line in
            orderedPrefixLength(in: line) != nil
        }

        if isBullet {
            if allHaveBullets {
                // Check if they all match the exact requested prefix (with indent) → toggle off
                let allExactMatch = nonEmptyLines.allSatisfy { _, line in
                    let trimmed = String(line.drop(while: { $0 == " " || $0 == "\t" }))
                    return trimmed.hasPrefix(prefix)
                }
                if allExactMatch {
                    return lines.map { line in
                        guard !line.isEmpty else { return line }
                        let (indent, content) = splitListPrefix(line)
                        return indent + content
                    }.joined(separator: "\n")
                }
            }

            // Strip any existing list prefix, preserve indent, apply bullet
            if allHaveBullets || allHaveOrdered {
                return lines.map { line in
                    guard !line.isEmpty else { return line }
                    let (indent, content) = splitListPrefix(line)
                    return indent + prefix + content
                }.joined(separator: "\n")
            }

            return lines.map { line in
                guard !line.isEmpty else { return line }
                return prefix + line
            }.joined(separator: "\n")

        } else {
            // Ordered list: detect style from prefix
            let style = detectStyleFromPrefix(prefix)

            if allHaveOrdered {
                // Check if all lines already have the same style → toggle off
                let allSameStyle = nonEmptyLines.allSatisfy { _, line in
                    let trimmed = String(line.drop(while: { $0 == " " || $0 == "\t" }))
                    let existingStyle = detectStyleFromPrefix(String(trimmed.prefix(while: { $0 != " " })) + " ")
                    return existingStyle == style
                }
                if allSameStyle {
                    return lines.map { line in
                        guard !line.isEmpty else { return line }
                        let (indent, content) = splitListPrefix(line)
                        return indent + content
                    }.joined(separator: "\n")
                }
            }

            // Strip any existing list prefix, preserve indent, apply ordered with new style
            let hasExistingPrefix = allHaveOrdered || allHaveBullets

            var counter = 1
            return lines.map { line in
                guard !line.isEmpty else { return line }
                let marker = markerForIndex(counter, style: style)
                counter += 1
                if hasExistingPrefix {
                    let (indent, content) = splitListPrefix(line)
                    return indent + marker + ". " + content
                }
                return marker + ". " + line
            }.joined(separator: "\n")
        }
    }

    private static func detectStyleFromPrefix(_ prefix: String) -> OrderedListStyle {
        let trimmed = prefix.trimmingCharacters(in: .whitespaces)
        let marker = trimmed.replacingOccurrences(of: ". ", with: "").replacingOccurrences(of: ".", with: "")
        if Int(marker) != nil { return .numeric }
        if marker == marker.lowercased() {
            if romanToInt(marker) != nil && (marker == "i" || marker.count > 1) { return .lowerRoman }
            return .lowerAlpha
        }
        if marker == marker.uppercased() {
            if romanToInt(marker.lowercased()) != nil && (marker == "I" || marker.count > 1) { return .upperRoman }
            return .upperAlpha
        }
        return .numeric
    }

    private static func markerForIndex(_ index: Int, style: OrderedListStyle) -> String {
        switch style {
        case .numeric:
            return "\(index)"
        case .lowerAlpha:
            return alphaForIndex(index, uppercase: false)
        case .upperAlpha:
            return alphaForIndex(index, uppercase: true)
        case .lowerRoman:
            return intToRoman(index)
        case .upperRoman:
            return intToRoman(index).uppercased()
        }
    }

    private static func alphaForIndex(_ index: Int, uppercase: Bool) -> String {
        let base: UnicodeScalar = uppercase ? "A" : "a"
        if index <= 26 {
            return String(UnicodeScalar(base.value + UInt32(index - 1))!)
        }
        // Beyond 26: "aa", "ab", etc.
        let first = alphaForIndex((index - 1) / 26, uppercase: uppercase)
        let second = String(UnicodeScalar(base.value + UInt32((index - 1) % 26))!)
        return first + second
    }

    // MARK: - Indent-Level Style Mapping

    /// Maps indentation depth to the expected ordered list style:
    /// level 0 → 1, 2, 3  |  level 1 → a, b, c  |  level 2+ → i, ii, iii
    static func styleForIndentLevel(_ level: Int) -> OrderedListStyle {
        switch level {
        case 0: return .numeric
        case 1: return .lowerAlpha
        default: return .lowerRoman
        }
    }

    /// After indent/dedent, converts ordered list markers to match the expected style
    /// for their new indentation level. Resets marker to 1 when style changes.
    static func adjustOrderedMarkersForIndent(_ text: String, indentWidth: Int = 4) -> String {
        let lines = text.components(separatedBy: "\n")
        return lines.map { line in
            guard let existing = orderedPrefixLength(in: line) else { return line }
            let ns = line as NSString
            let indentStr = ns.substring(to: existing.indent)
            let level = existing.indent / indentWidth
            let expectedStyle = styleForIndentLevel(level)

            // Detect current style from the marker portion
            let markerPortion = ns.substring(with: NSRange(location: existing.indent, length: existing.total - existing.indent))
            let currentStyle = detectStyleFromPrefix(markerPortion)

            guard currentStyle != expectedStyle else { return line }

            // Convert: reset to first marker of new style
            let newMarker = markerForIndex(1, style: expectedStyle)
            let content = ns.substring(from: existing.total)
            return indentStr + newMarker + ". " + content
        }.joined(separator: "\n")
    }
}
