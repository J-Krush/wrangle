import AppKit
import Foundation

extension NSAttributedString.Key {
    static let xmlTag = NSAttributedString.Key("xmlTag")
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

    // MARK: - Public API

    /// Scans the attributed string for XML tags and applies colored styling.
    /// Skips any range that already has a monospace (code) font.
    static func render(in attributedString: NSMutableAttributedString, theme: Theme = .current) {
        let fullString = attributedString.string
        let fullRange = NSRange(location: 0, length: attributedString.length)

        // Collect code ranges to skip
        let codeRanges = collectCodeRanges(in: attributedString, theme: theme)

        // 1. Style opening, closing, and self-closing XML tags
        styleTagMarkers(in: attributedString, fullString: fullString, fullRange: fullRange, codeRanges: codeRanges, theme: theme)

        // 2. Style content between matched opening and closing tags
        styleTagContent(in: attributedString, fullString: fullString, fullRange: fullRange, codeRanges: codeRanges, theme: theme)
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
        // Pattern matches: <tagname>, </tagname>, <tagname />, <tagname/>
        guard let pattern = try? NSRegularExpression(
            pattern: "<(/?)([a-zA-Z][a-zA-Z0-9_-]*)\\s*/?>",
            options: []
        ) else { return }

        let matches = pattern.matches(in: fullString, range: fullRange)

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

    /// Finds matching `<tag>...</tag>` pairs and indents the content between them.
    private static func styleTagContent(
        in attributedString: NSMutableAttributedString,
        fullString: String,
        fullRange: NSRange,
        codeRanges: [NSRange],
        theme: Theme
    ) {
        // Match paired tags with content: <tag>...content...</tag>
        // Using a non-greedy match for the content portion
        guard let pattern = try? NSRegularExpression(
            pattern: "<([a-zA-Z][a-zA-Z0-9_-]*)(?:\\s[^>]*)?>([\\s\\S]*?)</\\1>",
            options: []
        ) else { return }

        let matches = pattern.matches(in: fullString, range: fullRange)

        for match in matches.reversed() {
            let range = match.range
            if isInsideCode(range, codeRanges: codeRanges) { continue }

            let contentRange = match.range(at: 2)
            guard contentRange.length > 0 else { continue }

            // Apply a subtle left indent to the content between tags
            let style = NSMutableParagraphStyle()
            style.lineSpacing = theme.lineSpacing
            style.paragraphSpacing = theme.paragraphSpacing
            style.headIndent = 20
            style.firstLineHeadIndent = 20

            attributedString.addAttribute(.paragraphStyle, value: style, range: contentRange)
        }
    }
}
