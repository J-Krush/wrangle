import AppKit
import Foundation

/// Converts raw markdown text into a styled NSAttributedString for display in the editor.
///
/// The parser applies styling for common markdown elements while respecting code blocks
/// as protected zones where no further parsing occurs. When `hideMarkdownSyntax` is true
/// (writing mode), all syntax characters are hidden. When false (dev mode), all syntax
/// characters remain visible.
extension NSAttributedString.Key {
    static let bulletMarker = NSAttributedString.Key("com.Wrangle.bulletMarker")
    /// Marks a `- [ ]` or `- [x]` checkbox prefix for replacement in writing mode.
    /// Value is `true` (checked) or `false` (unchecked).
    static let checkboxMarker = NSAttributedString.Key("com.Wrangle.checkboxMarker")
    /// Marks a `|` pipe character in a table row for replacement with `\t` in writing mode.
    static let tableMarker = NSAttributedString.Key("com.Wrangle.tableMarker")
}

final class MarkdownParser: @unchecked Sendable {

    // MARK: - Cached Regex Patterns

    private static let codeBlockRegex = try! NSRegularExpression(
        pattern: "^```[^\\n]*\\n[\\s\\S]*?^```",
        options: [.anchorsMatchLines]
    )
    private static let inlineCodeRegex = try! NSRegularExpression(
        pattern: "`([^`\\n]+)`"
    )
    private static let headingRegex = try! NSRegularExpression(
        pattern: "^(#{1,6})( +)(.+)$",
        options: .anchorsMatchLines
    )
    private static let boldRegex = try! NSRegularExpression(
        pattern: "(\\*\\*|__)(.+?)(\\1)"
    )
    private static let italicStarRegex = try! NSRegularExpression(
        pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)"
    )
    private static let italicUnderRegex = try! NSRegularExpression(
        pattern: "(?<!_)_(?!_)(.+?)(?<!_)_(?!_)"
    )
    private static let strikethroughRegex = try! NSRegularExpression(
        pattern: "(~~)(.+?)(~~)"
    )
    private static let blockquoteRegex = try! NSRegularExpression(
        pattern: "^(>\\s?)(.*)$",
        options: .anchorsMatchLines
    )
    private static let checkboxRegex = try! NSRegularExpression(
        pattern: "^(\\s*)(- \\[)([ xX])(\\]\\s+)(.*)$",
        options: .anchorsMatchLines
    )
    private static let bulletListRegex = try! NSRegularExpression(
        pattern: "^(\\s*)[\\-\\*]\\s+(?!\\[[ xX]\\]\\s)(.*)$",
        options: .anchorsMatchLines
    )
    private static let numberedListRegex = try! NSRegularExpression(
        pattern: "^(\\s*)(?:\\d+|[a-zA-Z]+)\\.\\s+(.*)$",
        options: .anchorsMatchLines
    )
    private static let horizontalRuleRegex = try! NSRegularExpression(
        pattern: "^(---+|\\*\\*\\*+|___+)\\s*$",
        options: .anchorsMatchLines
    )
    private static let linkRegex = try! NSRegularExpression(
        pattern: "(\\[)([^\\]]+)(\\]\\()([^)]+)(\\))"
    )
    /// Matches a complete markdown table: header row + separator row + data rows.
    private static let tableRegex = try! NSRegularExpression(
        pattern: "^(\\|[^\\n]+\\|\\s*\\n)(\\|[\\s:]*-+[\\s:]*(?:\\|[\\s:]*-+[\\s:]*)*\\|\\s*\\n)((?:\\|[^\\n]+\\|\\s*\\n?)*)",
        options: .anchorsMatchLines
    )

    // MARK: - Protected Ranges

    /// Ranges that should not be processed for markdown (e.g., fenced code blocks).
    private var protectedRanges: [NSRange] = []

    /// When false, syntax characters are always visible (dev mode).
    private var shouldHideMarkdownSyntax = true

    // MARK: - Public API

    func parse(_ text: String, hideMarkdownSyntax: Bool = true, theme: Theme = .current) -> NSAttributedString {
        protectedRanges = []
        shouldHideMarkdownSyntax = hideMarkdownSyntax

        let baseStyle = baseParagraphStyle(theme: theme)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: theme.editorFont,
            .foregroundColor: theme.editorForeground,
            .paragraphStyle: baseStyle,
        ]

        let result = NSMutableAttributedString(string: text, attributes: baseAttributes)
        let fullRange = NSRange(location: 0, length: result.length)

        // 1. Code blocks (fenced) — must be first so content inside is protected
        applyCodeBlocks(in: result, fullRange: fullRange, theme: theme)

        // 2. Tables (before inline code so table pipes aren't treated as other syntax)
        applyTables(in: result, fullRange: fullRange, theme: theme)

        // 3. Inline code
        applyInlineCode(in: result, fullRange: fullRange, theme: theme)

        // 4. Headings
        applyHeadings(in: result, fullRange: fullRange, theme: theme)

        // 5. Bold
        applyBold(in: result, fullRange: fullRange, theme: theme)

        // 6. Italic
        applyItalic(in: result, fullRange: fullRange, theme: theme)

        // 7. Strikethrough
        applyStrikethrough(in: result, fullRange: fullRange, theme: theme)

        // 8. Blockquotes
        applyBlockquotes(in: result, fullRange: fullRange, theme: theme)

        // 9a. Checkboxes (before bullet lists so `- [ ]` isn't caught as a plain bullet)
        applyCheckboxes(in: result, fullRange: fullRange, theme: theme)

        // 9b. Bullet lists
        applyBulletLists(in: result, fullRange: fullRange, theme: theme)

        // 10. Numbered lists
        applyNumberedLists(in: result, fullRange: fullRange, theme: theme)

        // 11. Horizontal rules
        applyHorizontalRules(in: result, fullRange: fullRange, theme: theme)

        // 12. Links
        applyLinks(in: result, fullRange: fullRange, theme: theme)

        return result
    }

    // MARK: - Helpers

    private func baseParagraphStyle(theme: Theme) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = theme.lineSpacing
        style.paragraphSpacing = theme.paragraphSpacing
        return style
    }

    /// Whether a given range is fully contained within any protected range (code blocks / inline code).
    private func isProtected(_ range: NSRange) -> Bool {
        protectedRanges.contains { protectedRange in
            range.location >= protectedRange.location
                && (range.location + range.length) <= (protectedRange.location + protectedRange.length)
        }
    }

    /// Makes syntax characters invisible and collapses their width.
    /// Sets both transparent color and a near-zero font size so hidden
    /// characters take up virtually no space in the layout.
    private func hideSyntax(in attrStr: NSMutableAttributedString, range: NSRange) {
        guard shouldHideMarkdownSyntax else { return }
        let tinyFont = NSFont.systemFont(ofSize: 0.01)
        attrStr.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: tinyFont,
        ], range: range)
    }

    // MARK: - Element Parsers

    // 1. Fenced Code Blocks
    private func applyCodeBlocks(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.codeBlockRegex.matches(in: attrStr.string, range: fullRange)
        let nsString = attrStr.string as NSString

        for match in matches.reversed() {
            let range = match.range

            // Always apply code styling to the entire block
            attrStr.addAttributes([
                .font: theme.codeFont,
                .foregroundColor: theme.codeForeground,
            ], range: range)

            // Mark for card-style background drawing by EditorTextView
            attrStr.addAttribute(.codeBlockBackground, value: true, range: range)

            // Indent code content so text has padding inside the card
            let codeStyle = NSMutableParagraphStyle()
            codeStyle.headIndent = 16
            codeStyle.firstLineHeadIndent = 16
            codeStyle.lineSpacing = theme.lineSpacing
            codeStyle.paragraphSpacing = 2
            attrStr.addAttribute(.paragraphStyle, value: codeStyle, range: range)

            // Find opening fence line and closing fence line
            let openLineRange = nsString.lineRange(
                for: NSRange(location: range.location, length: 0)
            )
            let closeLineRange = nsString.lineRange(
                for: NSRange(location: max(range.location, range.location + range.length - 1), length: 0)
            )

            // Hide fence lines in writing mode
            if shouldHideMarkdownSyntax {
                hideFenceLine(in: attrStr, range: openLineRange, isOpening: true)
                hideFenceLine(in: attrStr, range: closeLineRange, isOpening: false)
            } else {
                // Add extra spacing below the closing fence in dev mode
                let closeStyle = NSMutableParagraphStyle()
                closeStyle.headIndent = 16
                closeStyle.firstLineHeadIndent = 16
                closeStyle.lineSpacing = theme.lineSpacing
                closeStyle.paragraphSpacing = 12
                attrStr.addAttribute(.paragraphStyle, value: closeStyle, range: closeLineRange)
            }

            protectedRanges.append(range)
        }
    }

    /// Collapses a fence line (```...) to near-zero height so it disappears visually.
    /// Reserves paragraph spacing to prevent the code block background card from overlapping adjacent lines.
    private func hideFenceLine(in attrStr: NSMutableAttributedString, range: NSRange, isOpening: Bool) {
        let collapsedStyle = NSMutableParagraphStyle()
        collapsedStyle.maximumLineHeight = 0.01
        collapsedStyle.minimumLineHeight = 0.01
        collapsedStyle.lineSpacing = 0
        // Reserve space for the background card expansion (12px each side)
        collapsedStyle.paragraphSpacingBefore = isOpening ? 12 : 0
        collapsedStyle.paragraphSpacing = isOpening ? 0 : 14

        attrStr.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 0.01),
            .paragraphStyle: collapsedStyle,
        ], range: range)
    }

    // 2. Tables
    private func applyTables(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.tableRegex.matches(in: attrStr.string, range: fullRange)
        let nsString = attrStr.string as NSString

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let headerRange = match.range(at: 1)
            let separatorRange = match.range(at: 2)
            let dataRange = match.range(at: 3)

            // Parse all rows to calculate column widths
            let allContentRows = collectTableRows(in: nsString, headerRange: headerRange, dataRange: dataRange)
            let columnWidths = calculateColumnWidths(rows: allContentRows, font: theme.editorFont)

            // Build tab stops from column widths
            let cellPadding: CGFloat = 12
            let tableInset: CGFloat = 16
            var tabStops: [NSTextTab] = []
            var cumulative: CGFloat = tableInset
            for width in columnWidths {
                cumulative += cellPadding
                tabStops.append(NSTextTab(textAlignment: .left, location: cumulative))
                cumulative += width + cellPadding
            }

            // Mark entire table for card background drawing
            attrStr.addAttribute(.tableBlock, value: true, range: range)

            // Apply paragraph style with tab stops to header row
            let headerStyle = NSMutableParagraphStyle()
            headerStyle.lineSpacing = theme.lineSpacing
            headerStyle.paragraphSpacing = 0
            headerStyle.paragraphSpacingBefore = 4
            headerStyle.headIndent = tableInset
            headerStyle.firstLineHeadIndent = tableInset
            headerStyle.tabStops = tabStops
            attrStr.addAttributes([
                .paragraphStyle: headerStyle,
                .font: NSFont.boldSystemFont(ofSize: theme.editorFont.pointSize),
            ], range: headerRange)

            // Mark header row for separator line drawing
            attrStr.addAttribute(.tableHeaderRow, value: true, range: headerRange)

            // Apply paragraph style to data rows
            if dataRange.length > 0 {
                let dataStyle = NSMutableParagraphStyle()
                dataStyle.lineSpacing = theme.lineSpacing
                dataStyle.paragraphSpacing = 0
                dataStyle.headIndent = tableInset
                dataStyle.firstLineHeadIndent = tableInset
                dataStyle.tabStops = tabStops
                attrStr.addAttribute(.paragraphStyle, value: dataStyle, range: dataRange)
            }

            // Add spacing after the table to prevent overlap with the next element.
            // This must be OUTSIDE the table range so the card background doesn't grow.
            let afterTable = NSMaxRange(range)
            if afterTable < attrStr.length {
                let afterLineRange = nsString.lineRange(for: NSRange(location: afterTable, length: 0))
                let afterStyle = baseParagraphStyle(theme: theme)
                afterStyle.paragraphSpacingBefore = 20
                attrStr.addAttribute(.paragraphStyle, value: afterStyle, range: afterLineRange)
            }

            // Mark pipe characters for replacement in writing mode
            if shouldHideMarkdownSyntax {
                markPipeCharacters(in: attrStr, range: headerRange)
                if dataRange.length > 0 {
                    markPipeCharacters(in: attrStr, range: dataRange)
                }

                // Collapse separator row to near-zero height
                hideSeparatorRow(in: attrStr, range: separatorRange)
            }

            protectedRanges.append(range)
        }
    }

    /// Collects cell content strings from header and data rows for width calculation.
    private func collectTableRows(in nsString: NSString, headerRange: NSRange, dataRange: NSRange) -> [[String]] {
        var rows: [[String]] = []

        func parseRow(_ lineRange: NSRange) {
            let line = nsString.substring(with: lineRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = line.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            // Drop leading/trailing empty entries from the split (before first | and after last |)
            let trimmed = parts.dropFirst().dropLast().map { String($0) }
            rows.append(Array(trimmed))
        }

        // Header row
        let headerLineRange = NSRange(location: headerRange.location,
                                       length: headerRange.length)
        parseRow(headerLineRange)

        // Data rows
        if dataRange.length > 0 {
            var offset = dataRange.location
            let end = dataRange.location + dataRange.length
            while offset < end {
                let lineRange = nsString.lineRange(for: NSRange(location: offset, length: 0))
                let clampedRange = NSRange(
                    location: lineRange.location,
                    length: min(lineRange.length, end - lineRange.location)
                )
                if clampedRange.length > 0 {
                    parseRow(clampedRange)
                }
                let next = NSMaxRange(lineRange)
                if next <= offset { break }
                offset = next
            }
        }

        return rows
    }

    /// Measures max column widths across all rows using the given font.
    private func calculateColumnWidths(rows: [[String]], font: NSFont) -> [CGFloat] {
        guard let firstRow = rows.first else { return [] }
        var widths = [CGFloat](repeating: 0, count: firstRow.count)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: font.pointSize)
        ]

        for (rowIndex, row) in rows.enumerated() {
            for (colIndex, cell) in row.enumerated() where colIndex < widths.count {
                let measureAttrs = rowIndex == 0 ? boldAttrs : attrs
                let cellWidth = NSAttributedString(string: cell, attributes: measureAttrs).size().width
                widths[colIndex] = max(widths[colIndex], cellWidth)
            }
        }

        // Ensure minimum column width
        return widths.map { max($0, 30) }
    }

    /// Marks each `|` character in the given range with `.tableMarker` for replacement with `\t`.
    private func markPipeCharacters(in attrStr: NSMutableAttributedString, range: NSRange) {
        let nsString = attrStr.string as NSString
        for i in 0..<range.length {
            let charIndex = range.location + i
            if nsString.character(at: charIndex) == 0x7C { // '|'
                attrStr.addAttribute(.tableMarker, value: true, range: NSRange(location: charIndex, length: 1))
            }
        }
    }

    /// Collapses the separator row (| --- | --- |) to near-zero height.
    private func hideSeparatorRow(in attrStr: NSMutableAttributedString, range: NSRange) {
        let collapsedStyle = NSMutableParagraphStyle()
        collapsedStyle.maximumLineHeight = 0.01
        collapsedStyle.minimumLineHeight = 0.01
        collapsedStyle.lineSpacing = 0
        collapsedStyle.paragraphSpacing = 0

        attrStr.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 0.01),
            .paragraphStyle: collapsedStyle,
        ], range: range)
    }

    // 3. Inline Code
    private func applyInlineCode(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.inlineCodeRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            attrStr.addAttributes([
                .font: theme.codeFont,
                .foregroundColor: theme.codeForeground,
                .backgroundColor: theme.codeBackground,
            ], range: range)

            // Hide backticks in writing mode
            let openTick = NSRange(location: range.location, length: 1)
            let closeTick = NSRange(location: range.location + range.length - 1, length: 1)
            hideSyntax(in: attrStr, range: openTick)
            hideSyntax(in: attrStr, range: closeTick)

            protectedRanges.append(range)
        }
    }

    // 4. Headings
    private func applyHeadings(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.headingRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let hashRange = match.range(at: 1)
            let spaceRange = match.range(at: 2)
            let level = hashRange.length

            // Apply heading style to entire line
            attrStr.addAttributes([
                .font: theme.headingFont(level: level),
                .foregroundColor: theme.headingColor,
            ], range: range)

            // Hide the "# " prefix in writing mode
            hideSyntax(in: attrStr, range: hashRange)
            hideSyntax(in: attrStr, range: spaceRange)
        }
    }

    // 5. Bold
    private func applyBold(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.boldRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let openRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let closeRange = match.range(at: 3)

            // Apply bold by enumerating font runs so inline code fonts are preserved
            attrStr.enumerateAttribute(.font, in: contentRange, options: []) { value, subRange, _ in
                let existingFont = value as? NSFont ?? theme.editorFont
                let boldFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .boldFontMask)
                attrStr.addAttribute(.font, value: boldFont, range: subRange)
            }

            // Hide ** markers in writing mode
            hideSyntax(in: attrStr, range: openRange)
            hideSyntax(in: attrStr, range: closeRange)
        }
    }

    // 6. Italic — uses two separate patterns to avoid unreliable backreferences
    private func applyItalic(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let patterns: [(NSRegularExpression, Int)] = [
            (Self.italicStarRegex, 1),
            (Self.italicUnderRegex, 1),
        ]

        for (pattern, _) in patterns {
            let matches = pattern.matches(in: attrStr.string, range: fullRange)

            for match in matches.reversed() {
                let range = match.range
                if isProtected(range) { continue }

                let contentRange = match.range(at: 1)

                // Apply italic by enumerating font runs so inline code/bold fonts are preserved
                attrStr.enumerateAttribute(.font, in: contentRange, options: []) { value, subRange, _ in
                    let existingFont = value as? NSFont ?? theme.editorFont
                    var italicFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .italicFontMask)
                    if italicFont == existingFont {
                        let desc = existingFont.fontDescriptor.withSymbolicTraits(.italic)
                        italicFont = NSFont(descriptor: desc, size: existingFont.pointSize) ?? italicFont
                    }
                    attrStr.addAttribute(.font, value: italicFont, range: subRange)
                }

                // Hide * or _ markers in writing mode
                let openMarker = NSRange(location: range.location, length: 1)
                let closeMarker = NSRange(location: range.location + range.length - 1, length: 1)
                hideSyntax(in: attrStr, range: openMarker)
                hideSyntax(in: attrStr, range: closeMarker)
            }
        }
    }

    // 7. Strikethrough
    private func applyStrikethrough(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.strikethroughRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let openRange = match.range(at: 1)
            let closeRange = match.range(at: 3)

            attrStr.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)

            // Hide ~~ markers in writing mode
            hideSyntax(in: attrStr, range: openRange)
            hideSyntax(in: attrStr, range: closeRange)
        }
    }

    // 8. Blockquotes
    private func applyBlockquotes(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.blockquoteRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let prefixRange = match.range(at: 1)

            let style = NSMutableParagraphStyle()
            style.lineSpacing = theme.lineSpacing
            style.paragraphSpacing = theme.paragraphSpacing
            style.headIndent = 24
            style.firstLineHeadIndent = 24

            attrStr.addAttributes([
                .foregroundColor: theme.blockquoteText,
                .paragraphStyle: style,
            ], range: range)

            // Hide "> " prefix in writing mode
            hideSyntax(in: attrStr, range: prefixRange)
        }
    }

    // 9a. Checkboxes (task lists)
    private func applyCheckboxes(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.checkboxRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let style = NSMutableParagraphStyle()
            style.lineSpacing = theme.lineSpacing
            style.paragraphSpacing = theme.paragraphSpacing / 2
            style.headIndent = 28
            style.firstLineHeadIndent = 12
            style.tabStops = [NSTextTab(textAlignment: .left, location: 28)]

            attrStr.addAttribute(.paragraphStyle, value: style, range: range)

            if shouldHideMarkdownSyntax {
                // Groups: 1=indent, 2="- [", 3=state char, 4="] ", 5=text
                let stateRange = match.range(at: 3)
                let stateChar = (attrStr.string as NSString).substring(with: stateRange)
                let isChecked = stateChar == "x" || stateChar == "X"

                // Mark the entire "- [x] " prefix (groups 2+3+4) for replacement
                let prefixStart = match.range(at: 2).location
                let prefixEnd = match.range(at: 4).location + match.range(at: 4).length
                let prefixRange = NSRange(location: prefixStart, length: prefixEnd - prefixStart)
                attrStr.addAttribute(.checkboxMarker, value: isChecked, range: prefixRange)

                // Apply strikethrough to checked items
                if isChecked {
                    let textRange = match.range(at: 5)
                    attrStr.addAttributes([
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                        .foregroundColor: NSColor.secondaryLabelColor,
                    ], range: textRange)
                }
            }
        }
    }

    // 9b. Bullet Lists
    private func applyBulletLists(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.bulletListRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let style = NSMutableParagraphStyle()
            style.lineSpacing = theme.lineSpacing
            style.paragraphSpacing = theme.paragraphSpacing / 2
            style.headIndent = 28
            style.firstLineHeadIndent = 12
            style.tabStops = [NSTextTab(textAlignment: .left, location: 28)]

            attrStr.addAttribute(.paragraphStyle, value: style, range: range)

            // Mark - or * for bullet replacement in writing mode
            if shouldHideMarkdownSyntax {
                let leadingWhitespaceRange = match.range(at: 1)
                let bulletCharLocation = leadingWhitespaceRange.location + leadingWhitespaceRange.length
                let bulletCharRange = NSRange(location: bulletCharLocation, length: 1)
                attrStr.addAttribute(.bulletMarker, value: true, range: bulletCharRange)
            }
        }
    }

    // 10. Numbered Lists
    private func applyNumberedLists(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.numberedListRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let style = NSMutableParagraphStyle()
            style.lineSpacing = theme.lineSpacing
            style.paragraphSpacing = theme.paragraphSpacing / 2
            style.headIndent = 28
            style.firstLineHeadIndent = 12
            style.tabStops = [NSTextTab(textAlignment: .left, location: 28)]

            attrStr.addAttribute(.paragraphStyle, value: style, range: range)
        }
    }

    // 11. Horizontal Rules
    private func applyHorizontalRules(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.horizontalRuleRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let style = NSMutableParagraphStyle()
            style.lineSpacing = theme.lineSpacing
            style.paragraphSpacing = theme.paragraphSpacing
            style.alignment = .center

            attrStr.addAttributes([
                .foregroundColor: theme.blockquoteBorder,
                .paragraphStyle: style,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: theme.blockquoteBorder,
            ], range: range)
        }
    }

    // 12. Links
    private func applyLinks(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        let matches = Self.linkRegex.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let urlRange = match.range(at: 4)
            let urlString = (attrStr.string as NSString).substring(with: urlRange)

            // Style the link text
            let textRange = match.range(at: 2)
            attrStr.addAttributes([
                .foregroundColor: theme.linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .link: urlString,
            ], range: textRange)

            // Also color the full range for consistent look
            attrStr.addAttribute(.foregroundColor, value: theme.linkColor, range: range)

            // Hide [, ](, url, ) in writing mode — show only the link text
            let openBracket = match.range(at: 1)
            let closeBracketParen = match.range(at: 3)
            let closeParenRange = match.range(at: 5)

            hideSyntax(in: attrStr, range: openBracket)
            hideSyntax(in: attrStr, range: closeBracketParen)
            hideSyntax(in: attrStr, range: urlRange)
            hideSyntax(in: attrStr, range: closeParenRange)
        }
    }
}
