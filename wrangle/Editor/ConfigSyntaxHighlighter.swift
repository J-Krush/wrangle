//
//  ConfigSyntaxHighlighter.swift
//  Wrangle
//

import AppKit

/// Syntax highlighter for config/code files that should NOT get markdown rendering.
/// Provides monospace font with comment highlighting for .env, .gitignore, shell, and similar files.
final class ConfigSyntaxHighlighter: Sendable {

    private static let commentPattern = try! NSRegularExpression(
        pattern: #"^\s*#.*$"#,
        options: .anchorsMatchLines
    )

    /// Apply config-style syntax highlighting (monospace, comment coloring).
    func highlight(_ text: String, theme: Theme = .current) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        let result = NSMutableAttributedString(string: text, attributes: [
            .font: theme.codeFont,
            .foregroundColor: theme.editorForeground,
            .paragraphStyle: paragraphStyle,
        ])

        let fullRange = NSRange(location: 0, length: result.length)

        // Highlight # comments in a dimmed color
        let commentColor = theme.editorForeground.withAlphaComponent(0.45)
        let matches = Self.commentPattern.matches(in: text, range: fullRange)
        for match in matches {
            result.addAttribute(.foregroundColor, value: commentColor, range: match.range)
            let italicFont = NSFontManager.shared.convert(theme.codeFont, toHaveTrait: .italicFontMask)
            result.addAttribute(.font, value: italicFont, range: match.range)
        }

        return result
    }
}
