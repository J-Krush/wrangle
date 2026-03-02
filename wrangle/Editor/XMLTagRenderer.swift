import AppKit
import Foundation

extension NSAttributedString.Key {
    static let xmlTag = NSAttributedString.Key("xmlTag")
    /// Marks the opening tag line of a foldable XML block. Value is `[String: Any]` with keys `"offset"` (Int) and `"color"` (NSColor).
    static let xmlTagFoldable = NSAttributedString.Key("xmlTagFoldable")
}

/// Applies special styling to XML tags commonly found in AI prompt files.
///
/// Tags like `<instructions>`, `<tools>`, `<examples>`, and `<artifacts>` get
/// distinct colors, while their inner content receives a subtle indent. Tags
/// inside code blocks are left untouched.
class XMLTagRenderer {

    // MARK: - Tag Color Categories

    private static let tagColorMap: [String: NSColor] = [
        "instructions": .systemBlue,
        "system": .systemBlue,
        "tools": .systemTeal,
        "tool": .systemTeal,
        "examples": .systemPurple,
        "example": .systemPurple,
        "artifacts": .systemOrange,
        "artifact": .systemOrange,
    ]

    /// Fallback color for tags that don't appear in the map.
    private static let defaultTagColor: NSColor = .systemGray

    // MARK: - Cached Regex Patterns

    /// Matches opening, closing, and self-closing XML tags: `<tag>`, `</tag>`, `<tag/>`
    private static let tagMarkerPattern = try! NSRegularExpression(
        pattern: "<(/?)([a-zA-Z][a-zA-Z0-9_-]*)\\s*/?>",
        options: []
    )

    /// Matches XML declarations and DOCTYPE: `<?xml ...?>`, `<!DOCTYPE ...>`
    private static let declarationPattern = try! NSRegularExpression(
        pattern: "<[?!][^>]+>",
        options: []
    )

    // MARK: - Public API

    /// Scans the attributed string for XML tags and applies colored styling.
    /// Skips any range that already has a monospace (code) font.
    ///
    /// - Parameters:
    ///   - foldingEnabled: When true, marks opening tag lines with `.xmlTagFoldable` and
    ///     collapses content for tags whose offset appears in `collapsedOffsets`.
    ///   - collapsedOffsets: Character offsets of opening `<` characters whose content should be collapsed.
    static func render(
        in attributedString: NSMutableAttributedString,
        theme: Theme = .current,
        foldingEnabled: Bool = false,
        collapsedOffsets: Set<Int> = []
    ) {
        let fullString = attributedString.string
        let fullRange = NSRange(location: 0, length: attributedString.length)

        // Collect code ranges to skip
        let codeRanges = collectCodeRanges(in: attributedString, theme: theme)

        // 1. Style opening, closing, and self-closing XML tags
        styleTagMarkers(in: attributedString, fullString: fullString, fullRange: fullRange, codeRanges: codeRanges, theme: theme)

        // 2. Style XML declarations (<?xml ...?> and <!DOCTYPE ...>)
        styleDeclarations(in: attributedString, fullString: fullString, fullRange: fullRange, codeRanges: codeRanges, theme: theme)

        // 3. Style content between matched opening and closing tags
        styleTagContent(
            in: attributedString,
            fullString: fullString,
            fullRange: fullRange,
            codeRanges: codeRanges,
            foldingEnabled: foldingEnabled,
            collapsedOffsets: collapsedOffsets,
            theme: theme
        )
    }

    // MARK: - Internals

    /// Collects ranges in the attributed string that use the code font (fenced blocks / inline code).
    private static func collectCodeRanges(in attributedString: NSMutableAttributedString, theme: Theme) -> [NSRange] {
        var codeRanges: [NSRange] = []
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            guard let font = value as? NSFont else { return }
            // Detect code font by checking if it's monospaced or matches the theme code font
            if font.fontName == theme.codeFont.fontName || font.isFixedPitch {
                codeRanges.append(range)
            }
        }
        return codeRanges
    }

    /// Whether the range overlaps with any code range.
    private static func isInsideCode(_ range: NSRange, codeRanges: [NSRange]) -> Bool {
        codeRanges.contains { NSIntersectionRange($0, range).length > 0 }
    }

    /// Resolve the color for a tag name, using the theme's xmlTagColors first, then the built-in map, then gray.
    private static func colorForTag(_ tagName: String, theme: Theme) -> NSColor {
        let lower = tagName.lowercased()
        if let themeColor = theme.xmlTagColors[lower] {
            return themeColor
        }
        return tagColorMap[lower] ?? defaultTagColor
    }

    // MARK: - Tag Marker Styling

    /// Matches `<tagname>`, `</tagname>`, and `<tagname/>` and applies colored bold styling.
    private static func styleTagMarkers(
        in attributedString: NSMutableAttributedString,
        fullString: String,
        fullRange: NSRange,
        codeRanges: [NSRange],
        theme: Theme
    ) {
        let matches = tagMarkerPattern.matches(in: fullString, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isInsideCode(range, codeRanges: codeRanges) { continue }

            let tagNameRange = match.range(at: 2)
            let tagName = (fullString as NSString).substring(with: tagNameRange)
            let color = colorForTag(tagName, theme: theme)

            // Bold + colored for the entire tag marker
            let boldFont = NSFont.boldSystemFont(ofSize: theme.editorFont.pointSize)
            attributedString.addAttributes([
                .foregroundColor: color,
                .font: boldFont,
                .xmlTag: tagName,
            ], range: range)
        }
    }

    // MARK: - Tag Content Styling

    /// Finds matching `<tag>...</tag>` pairs using a stack-based approach and indents
    /// the content between them. When `foldingEnabled`, marks opening tag lines with
    /// `.xmlTagFoldable` and collapses content for offsets present in `collapsedOffsets`.
    /// Only multi-line pairs get fold triangles — single-line pairs like `<key>foo</key>` are skipped.
    private static func styleTagContent(
        in attributedString: NSMutableAttributedString,
        fullString: String,
        fullRange: NSRange,
        codeRanges: [NSRange],
        foldingEnabled: Bool,
        collapsedOffsets: Set<Int>,
        theme: Theme
    ) {
        let nsString = fullString as NSString
        let pairs = findTagPairs(in: fullString, fullRange: fullRange, codeRanges: codeRanges)

        // Track ranges that have been collapsed so child pairs inside them are skipped
        var collapsedRanges: [NSRange] = []

        for pair in pairs.reversed() {
            let tagOffset = pair.openRange.location

            // Skip pairs whose opening tag is inside an already-collapsed region
            if collapsedRanges.contains(where: { NSLocationInRange(tagOffset, $0) }) { continue }

            // Only show fold triangle if pair spans multiple lines
            let openLine = nsString.lineRange(for: NSRange(location: pair.openRange.location, length: 0))
            let closeLine = nsString.lineRange(for: NSRange(location: pair.closeRange.location, length: 0))
            let spansMultipleLines = openLine.location != closeLine.location

            if foldingEnabled && spansMultipleLines {
                // Store offset + color so EditorTextView can draw color-matched triangles
                let color = colorForTag(pair.tagName, theme: theme)
                let foldInfo: [String: Any] = ["offset": tagOffset, "color": color]
                attributedString.addAttribute(.xmlTagFoldable, value: foldInfo, range: openLine)
            }

            if foldingEnabled && spansMultipleLines && collapsedOffsets.contains(tagOffset) {
                // Collapse everything after the opening tag line through end of closing tag
                let collapseStart = openLine.location + openLine.length
                let matchEnd = pair.closeRange.location + pair.closeRange.length
                guard collapseStart < matchEnd else { continue }

                let collapseRange = NSRange(location: collapseStart, length: matchEnd - collapseStart)
                collapseLines(in: attributedString, range: collapseRange)
                collapsedRanges.append(collapseRange)
            } else if pair.contentRange.length > 0 {
                // Apply a subtle left indent to the content between tags
                let style = NSMutableParagraphStyle()
                style.lineSpacing = theme.lineSpacing
                style.paragraphSpacing = theme.paragraphSpacing
                style.headIndent = 20
                style.firstLineHeadIndent = 20

                attributedString.addAttribute(.paragraphStyle, value: style, range: pair.contentRange)
            }
        }
    }

    // MARK: - Tag Pair Discovery

    /// Walks all tag markers with a stack to find every matched `<tag>...</tag>` pair,
    /// including nested ones. Self-closing tags (`<br/>`) are skipped.
    private static func findTagPairs(
        in fullString: String,
        fullRange: NSRange,
        codeRanges: [NSRange]
    ) -> [(tagName: String, openRange: NSRange, closeRange: NSRange, contentRange: NSRange)] {
        let nsString = fullString as NSString
        let matches = tagMarkerPattern.matches(in: fullString, range: fullRange)

        var stack: [(tagName: String, range: NSRange)] = []
        var pairs: [(tagName: String, openRange: NSRange, closeRange: NSRange, contentRange: NSRange)] = []

        for match in matches {
            let range = match.range
            if isInsideCode(range, codeRanges: codeRanges) { continue }

            // Skip self-closing tags like <br/>
            let matchStr = nsString.substring(with: range)
            if matchStr.hasSuffix("/>") { continue }

            let isClosing = match.range(at: 1).length > 0
            let tagName = nsString.substring(with: match.range(at: 2))

            if isClosing {
                // Pop the most recent matching opening tag from the stack
                if let idx = stack.lastIndex(where: { $0.tagName == tagName }) {
                    let opening = stack[idx]
                    stack.remove(at: idx)

                    let contentStart = opening.range.location + opening.range.length
                    let contentEnd = range.location
                    let contentRange = NSRange(location: contentStart, length: contentEnd - contentStart)

                    pairs.append((tagName: tagName, openRange: opening.range, closeRange: range, contentRange: contentRange))
                }
            } else {
                stack.append((tagName: tagName, range: range))
            }
        }

        return pairs
    }

    // MARK: - Declaration Styling

    /// Styles `<?xml ...?>` and `<!DOCTYPE ...>` with muted italic to distinguish
    /// boilerplate metadata from content tags.
    private static func styleDeclarations(
        in attributedString: NSMutableAttributedString,
        fullString: String,
        fullRange: NSRange,
        codeRanges: [NSRange],
        theme: Theme
    ) {
        let matches = declarationPattern.matches(in: fullString, range: fullRange)

        for match in matches {
            let range = match.range
            if isInsideCode(range, codeRanges: codeRanges) { continue }

            let italicFont = NSFontManager.shared.convert(theme.editorFont, toHaveTrait: .italicFontMask)
            attributedString.addAttributes([
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: italicFont,
            ], range: range)
        }
    }

    // MARK: - Collapse Helpers

    /// Collapses lines to near-zero height so they disappear visually.
    /// Same technique used by `MarkdownParser.hideFenceLine()`.
    private static func collapseLines(in attrStr: NSMutableAttributedString, range: NSRange) {
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
}
