import AppKit
import Foundation

/// Converts raw markdown text into a styled NSAttributedString for display in the editor.
///
/// The parser applies styling for common markdown elements while respecting code blocks
/// as protected zones where no further parsing occurs. When a cursor position is provided,
/// the line containing the cursor reveals raw syntax (Obsidian-style editing). On all other
/// lines, markdown syntax characters (# for headings, ** for bold, etc.) are hidden by
/// making them transparent.
class MarkdownParser {

    // MARK: - Protected Ranges

    /// Ranges that should not be processed for markdown (e.g., fenced code blocks).
    private var protectedRanges: [NSRange] = []

    /// When false, syntax characters are always visible (dev mode).
    private var shouldHideMarkdownSyntax = true

    // MARK: - Public API

    func parse(_ text: String, cursorPosition: Int? = nil, hideMarkdownSyntax: Bool = true, theme: Theme = .current) -> NSAttributedString {
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

        // Determine the cursor line range so we can skip hiding syntax on that line
        let cursorLineRange: NSRange? = cursorPosition.flatMap { pos in
            guard pos >= 0, pos <= text.count else { return nil }
            let nsString = text as NSString
            let clamped = min(pos, nsString.length)
            return nsString.lineRange(for: NSRange(location: clamped, length: 0))
        }

        // 1. Code blocks (fenced) — must be first so content inside is protected
        applyCodeBlocks(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 2. Inline code
        applyInlineCode(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 3. Headings
        applyHeadings(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 4. Bold
        applyBold(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 5. Italic
        applyItalic(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 6. Strikethrough
        applyStrikethrough(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 7. Blockquotes
        applyBlockquotes(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 8. Bullet lists
        applyBulletLists(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 9. Numbered lists
        applyNumberedLists(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 10. Horizontal rules
        applyHorizontalRules(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        // 11. Links
        applyLinks(in: result, fullRange: fullRange, cursorLineRange: cursorLineRange, theme: theme)

        return result
    }

    // MARK: - Helpers

    private func baseParagraphStyle(theme: Theme) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = theme.lineSpacing
        style.paragraphSpacing = theme.paragraphSpacing
        return style
    }

    /// Whether a given range overlaps with any protected range (code blocks / inline code).
    private func isProtected(_ range: NSRange) -> Bool {
        protectedRanges.contains { NSIntersectionRange($0, range).length > 0 }
    }

    /// Whether a given range falls on the cursor's line (should reveal raw syntax).
    private func isOnCursorLine(_ range: NSRange, cursorLineRange: NSRange?) -> Bool {
        guard let cursorLine = cursorLineRange else { return false }
        return NSIntersectionRange(cursorLine, range).length > 0
    }

    /// Returns true when the match should be skipped entirely.
    private func shouldSkip(_ range: NSRange, cursorLineRange: NSRange?) -> Bool {
        isProtected(range) || isOnCursorLine(range, cursorLineRange: cursorLineRange)
    }

    private func regex(_ pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: options)
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
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("^```[^\\n]*\\n[\\s\\S]*?^```", options: [.anchorsMatchLines]) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)
        let nsString = attrStr.string as NSString

        for match in matches.reversed() {
            let range = match.range

            // Check if cursor is anywhere inside this code block
            let cursorInBlock = cursorLineRange.map {
                NSIntersectionRange($0, range).length > 0
            } ?? false

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

            // Hide fence lines when cursor is not in the block
            if !cursorInBlock && shouldHideMarkdownSyntax {
                hideFenceLine(in: attrStr, range: openLineRange)
                hideFenceLine(in: attrStr, range: closeLineRange)
            }

            protectedRanges.append(range)
        }
    }

    /// Collapses a fence line (```...) to near-zero height so it disappears visually.
    private func hideFenceLine(in attrStr: NSMutableAttributedString, range: NSRange) {
        let collapsedStyle = NSMutableParagraphStyle()
        collapsedStyle.maximumLineHeight = 0.01
        collapsedStyle.minimumLineHeight = 0.01
        collapsedStyle.lineSpacing = 0
        collapsedStyle.paragraphSpacing = 0
        collapsedStyle.paragraphSpacingBefore = 0

        attrStr.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 0.01),
            .paragraphStyle: collapsedStyle,
        ], range: range)
    }

    // 2. Inline Code
    private func applyInlineCode(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("`([^`\\n]+)`") else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let onCursor = isOnCursorLine(range, cursorLineRange: cursorLineRange)

            attrStr.addAttributes([
                .font: theme.codeFont,
                .foregroundColor: theme.codeForeground,
                .backgroundColor: theme.codeBackground,
            ], range: range)

            // Hide backticks when not on cursor line
            if !onCursor {
                let openTick = NSRange(location: range.location, length: 1)
                let closeTick = NSRange(location: range.location + range.length - 1, length: 1)
                hideSyntax(in: attrStr, range: openTick)
                hideSyntax(in: attrStr, range: closeTick)
            }

            protectedRanges.append(range)
        }
    }

    // 3. Headings
    private func applyHeadings(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("^(#{1,6})( +)(.+)$", options: .anchorsMatchLines) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let onCursor = isOnCursorLine(range, cursorLineRange: cursorLineRange)
            let hashRange = match.range(at: 1)
            let spaceRange = match.range(at: 2)
            let level = hashRange.length

            // Apply heading style to entire line
            attrStr.addAttributes([
                .font: theme.headingFont(level: level),
                .foregroundColor: theme.headingColor,
            ], range: range)

            // Hide the "# " prefix when not on cursor line
            if !onCursor {
                hideSyntax(in: attrStr, range: hashRange)
                hideSyntax(in: attrStr, range: spaceRange)
            }
        }
    }

    // 4. Bold
    private func applyBold(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("(\\*\\*|__)(.+?)(\\1)") else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let onCursor = isOnCursorLine(range, cursorLineRange: cursorLineRange)
            let openRange = match.range(at: 1)
            let closeRange = match.range(at: 3)

            // Apply bold to full match
            let existingFont = attrStr.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont ?? theme.editorFont
            let boldFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .boldFontMask)
            attrStr.addAttribute(.font, value: boldFont, range: range)

            // Hide ** markers when not on cursor line
            if !onCursor {
                hideSyntax(in: attrStr, range: openRange)
                hideSyntax(in: attrStr, range: closeRange)
            }
        }
    }

    // 5. Italic
    private func applyItalic(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("(?<![\\*_])(\\*|_)(?!\\1)(.+?)(?<!\\1)\\1(?!\\1)") else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let onCursor = isOnCursorLine(range, cursorLineRange: cursorLineRange)
            let markerRange = match.range(at: 1)
            let markerLen = markerRange.length

            // Apply italic
            let existingFont = attrStr.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont ?? theme.editorFont
            let italicFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .italicFontMask)
            attrStr.addAttribute(.font, value: italicFont, range: range)

            // Hide * or _ markers when not on cursor line
            if !onCursor {
                let openMarker = NSRange(location: range.location, length: markerLen)
                let closeMarker = NSRange(location: range.location + range.length - markerLen, length: markerLen)
                hideSyntax(in: attrStr, range: openMarker)
                hideSyntax(in: attrStr, range: closeMarker)
            }
        }
    }

    // 6. Strikethrough
    private func applyStrikethrough(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("(~~)(.+?)(~~)") else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let onCursor = isOnCursorLine(range, cursorLineRange: cursorLineRange)
            let openRange = match.range(at: 1)
            let closeRange = match.range(at: 3)

            attrStr.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)

            // Hide ~~ markers when not on cursor line
            if !onCursor {
                hideSyntax(in: attrStr, range: openRange)
                hideSyntax(in: attrStr, range: closeRange)
            }
        }
    }

    // 7. Blockquotes
    private func applyBlockquotes(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("^(>\\s?)(.*)$", options: .anchorsMatchLines) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let onCursor = isOnCursorLine(range, cursorLineRange: cursorLineRange)
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

            // Hide "> " prefix when not on cursor line
            if !onCursor {
                hideSyntax(in: attrStr, range: prefixRange)
            }
        }
    }

    // 8. Bullet Lists
    private func applyBulletLists(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("^(\\s*)[\\-\\*]\\s+(.+)$", options: .anchorsMatchLines) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if shouldSkip(range, cursorLineRange: cursorLineRange) { continue }

            let style = NSMutableParagraphStyle()
            style.lineSpacing = theme.lineSpacing
            style.paragraphSpacing = theme.paragraphSpacing / 2
            style.headIndent = 28
            style.firstLineHeadIndent = 12
            style.tabStops = [NSTextTab(textAlignment: .left, location: 28)]

            attrStr.addAttribute(.paragraphStyle, value: style, range: range)
        }
    }

    // 9. Numbered Lists
    private func applyNumberedLists(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("^(\\s*)\\d+\\.\\s+(.+)$", options: .anchorsMatchLines) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if shouldSkip(range, cursorLineRange: cursorLineRange) { continue }

            let style = NSMutableParagraphStyle()
            style.lineSpacing = theme.lineSpacing
            style.paragraphSpacing = theme.paragraphSpacing / 2
            style.headIndent = 28
            style.firstLineHeadIndent = 12
            style.tabStops = [NSTextTab(textAlignment: .left, location: 28)]

            attrStr.addAttribute(.paragraphStyle, value: style, range: range)
        }
    }

    // 10. Horizontal Rules
    private func applyHorizontalRules(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        guard let pattern = regex("^(---+|\\*\\*\\*+|___+)\\s*$", options: .anchorsMatchLines) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if shouldSkip(range, cursorLineRange: cursorLineRange) { continue }

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

    // 11. Links
    private func applyLinks(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        cursorLineRange: NSRange?,
        theme: Theme
    ) {
        // Pattern: [text](url) with capture groups: 1=[ 2=text 3=]( 4=url 5=)
        guard let pattern = regex("(\\[)([^\\]]+)(\\]\\()([^)]+)(\\))") else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isProtected(range) { continue }

            let onCursor = isOnCursorLine(range, cursorLineRange: cursorLineRange)
            let urlRange = match.range(at: 4)
            let urlString = (attrStr.string as NSString).substring(with: urlRange)

            // Style the link text
            let textRange = match.range(at: 2)
            attrStr.addAttributes([
                .foregroundColor: theme.linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .link: urlString,
                .cursor: NSCursor.pointingHand,
            ], range: textRange)

            // Also color the full range for consistent look
            attrStr.addAttribute(.foregroundColor, value: theme.linkColor, range: range)

            // Hide [, ](, url, ) when not on cursor line — show only the link text
            if !onCursor {
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
}
