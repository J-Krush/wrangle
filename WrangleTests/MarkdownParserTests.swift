import AppKit
import Testing
@testable import Wrangle

@MainActor
@Suite("MarkdownParser")
struct MarkdownParserTests {

    let parser = MarkdownParser()
    let theme = Theme.light

    // MARK: - Helpers

    private func font(in attrStr: NSAttributedString, at location: Int) -> NSFont? {
        guard location < attrStr.length else { return nil }
        return attrStr.attribute(.font, at: location, effectiveRange: nil) as? NSFont
    }

    private func color(in attrStr: NSAttributedString, at location: Int) -> NSColor? {
        guard location < attrStr.length else { return nil }
        return attrStr.attribute(.foregroundColor, at: location, effectiveRange: nil) as? NSColor
    }

    private func fontTraits(in attrStr: NSAttributedString, at location: Int) -> NSFontTraitMask {
        guard let f = font(in: attrStr, at: location) else { return [] }
        return NSFontManager.shared.traits(of: f)
    }

    // MARK: - Headings

    @Test("Headings get correct font size per level")
    func headings() {
        for level in 1...6 {
            let hashes = String(repeating: "#", count: level)
            let result = parser.parse("\(hashes) Heading", hideMarkdownSyntax: false, theme: theme)
            let expectedFont = theme.headingFont(level: level)
            // Check the heading text portion (after "# ")
            let textLocation = level + 1 // hashes + space
            let actualFont = font(in: result, at: textLocation)
            #expect(actualFont == expectedFont, "Level \(level) heading font mismatch")
        }
    }

    @Test("Heading syntax hidden in writing mode")
    func headingSyntaxHidden() {
        let result = parser.parse("# Hello", hideMarkdownSyntax: true, theme: theme)
        let hashColor = color(in: result, at: 0)
        #expect(hashColor == NSColor.clear)
    }

    // MARK: - Bold

    @Test("Bold text has bold trait")
    func bold() {
        let result = parser.parse("**bold text**", hideMarkdownSyntax: false, theme: theme)
        // "bold" starts at index 2
        let traits = fontTraits(in: result, at: 2)
        #expect(traits.contains(.boldFontMask))
    }

    // MARK: - Italic

    @Test("Italic with asterisk has italic trait")
    func italicStar() {
        let result = parser.parse("*italic text*", hideMarkdownSyntax: false, theme: theme)
        let traits = fontTraits(in: result, at: 1)
        #expect(traits.contains(.italicFontMask))
    }

    @Test("Italic with underscore has italic trait")
    func italicUnderscore() {
        let result = parser.parse("_italic text_", hideMarkdownSyntax: false, theme: theme)
        let traits = fontTraits(in: result, at: 1)
        #expect(traits.contains(.italicFontMask))
    }

    // MARK: - Code Blocks

    @Test("Fenced code block gets code font")
    func codeBlock() {
        let md = "```\nlet x = 1\n```"
        let result = parser.parse(md, hideMarkdownSyntax: false, theme: theme)
        // Content "let x = 1" starts after "```\n" (4 chars)
        let contentFont = font(in: result, at: 4)
        #expect(contentFont == theme.codeFont)
    }

    @Test("Code block content is protected from markdown parsing")
    func codeBlockProtected() {
        let md = "```\n**not bold**\n```"
        let result = parser.parse(md, hideMarkdownSyntax: false, theme: theme)
        // Inside code block, "**not bold**" should NOT be bold
        let traits = fontTraits(in: result, at: 6) // "n" in "not"
        #expect(!traits.contains(.boldFontMask))
    }

    // MARK: - Inline Code

    @Test("Inline code gets code font")
    func inlineCode() {
        let result = parser.parse("use `code` here", hideMarkdownSyntax: false, theme: theme)
        // "code" starts at index 5 (after "use `")
        let contentFont = font(in: result, at: 5)
        #expect(contentFont == theme.codeFont)
    }

    @Test("Inline code backticks hidden in writing mode")
    func inlineCodeHidden() {
        let result = parser.parse("use `code` here", hideMarkdownSyntax: true, theme: theme)
        // Opening backtick at index 4
        let tickColor = color(in: result, at: 4)
        #expect(tickColor == NSColor.clear)
    }

    // MARK: - Links

    @Test("Link text gets link color")
    func linkColor() {
        let result = parser.parse("[click here](https://example.com)", hideMarkdownSyntax: false, theme: theme)
        // "click here" starts at index 1
        let linkTextColor = color(in: result, at: 1)
        #expect(linkTextColor == theme.linkColor)
    }

    @Test("Link has .link attribute with URL")
    func linkAttribute() {
        let result = parser.parse("[text](https://example.com)", hideMarkdownSyntax: false, theme: theme)
        // "text" is at index 1
        let linkValue = result.attribute(.link, at: 1, effectiveRange: nil) as? String
        #expect(linkValue == "https://example.com")
    }

    // MARK: - Strikethrough

    @Test("Strikethrough has strikethrough attribute")
    func strikethrough() {
        let result = parser.parse("~~struck~~", hideMarkdownSyntax: false, theme: theme)
        let attr = result.attribute(.strikethroughStyle, at: 3, effectiveRange: nil) as? Int
        #expect(attr == NSUnderlineStyle.single.rawValue)
    }

    // MARK: - Blockquotes

    @Test("Blockquote gets blockquote text color")
    func blockquote() {
        let result = parser.parse("> quoted text", hideMarkdownSyntax: false, theme: theme)
        let textColor = color(in: result, at: 2)
        #expect(textColor == theme.blockquoteText)
    }

    // MARK: - Horizontal Rules

    @Test("Horizontal rules detected", arguments: ["---", "***", "___"])
    func horizontalRules(rule: String) {
        let result = parser.parse(rule, hideMarkdownSyntax: false, theme: theme)
        let attr = result.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
        #expect(attr == NSUnderlineStyle.single.rawValue)
    }

    // MARK: - Lists

    @Test("Bullet list gets paragraph style with headIndent 28")
    func bulletList() {
        let result = parser.parse("- item one", hideMarkdownSyntax: false, theme: theme)
        let paraStyle = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(paraStyle?.headIndent == 28)
    }

    @Test("Numbered list gets paragraph style with headIndent 28")
    func numberedList() {
        let result = parser.parse("1. item one", hideMarkdownSyntax: false, theme: theme)
        let paraStyle = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(paraStyle?.headIndent == 28)
    }

    // MARK: - Dev Mode vs Writing Mode

    @Test("Dev mode keeps syntax visible")
    func devModeSyntaxVisible() {
        let result = parser.parse("**bold**", hideMarkdownSyntax: false, theme: theme)
        let markerColor = color(in: result, at: 0) // first "*"
        #expect(markerColor != NSColor.clear)
    }

    @Test("Writing mode hides syntax")
    func writingModeHidesSyntax() {
        let result = parser.parse("**bold**", hideMarkdownSyntax: true, theme: theme)
        let markerColor = color(in: result, at: 0) // first "*"
        #expect(markerColor == NSColor.clear)
    }
}
