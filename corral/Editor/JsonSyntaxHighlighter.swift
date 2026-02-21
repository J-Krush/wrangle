import AppKit
import Foundation

/// Applies syntax coloring to JSON text for display in an NSTextView.
///
/// Colors JSON elements in a consistent scheme: keys in cyan, strings in green,
/// numbers in orange, booleans in purple, null in gray, and structural characters
/// in a dimmed foreground. The underlying text is always raw JSON; only the
/// attributed string presentation changes.
class JsonSyntaxHighlighter {

    // MARK: - Public API

    /// Apply JSON syntax highlighting to the given text.
    ///
    /// Returns a fully-attributed string using monospace font and token-based
    /// coloring. All previous attributes are replaced.
    func highlight(_ text: String, theme: Theme = .current) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: [
            .font: theme.codeFont,
            .foregroundColor: theme.editorForeground,
        ])

        let fullRange = NSRange(location: 0, length: result.length)

        // Apply in order so that keys (step 2) override the green applied to
        // all strings in step 1.
        applyStrings(in: result, fullRange: fullRange, theme: theme)
        applyKeys(in: result, fullRange: fullRange, theme: theme)
        applyNumbers(in: result, fullRange: fullRange, theme: theme)
        applyBooleans(in: result, fullRange: fullRange, theme: theme)
        applyNull(in: result, fullRange: fullRange, theme: theme)
        applyStructural(in: result, fullRange: fullRange, theme: theme)

        return result
    }

    // MARK: - Prettify / Minify

    /// Format a JSON string with pretty-printed indentation and sorted keys.
    static func prettify(_ json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return prettyString
    }

    /// Minify a JSON string by removing unnecessary whitespace.
    static func minify(_ json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let minData = try? JSONSerialization.data(withJSONObject: object, options: []),
              let minString = String(data: minData, encoding: .utf8) else {
            return nil
        }
        return minString
    }

    // MARK: - Private Helpers

    private func regex(_ pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: options)
    }

    // MARK: - 1. String Values (green)

    /// Matches any double-quoted string, handling escaped characters.
    private func applyStrings(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        guard let pattern = regex(#""([^"\\]|\\.)*""#) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches {
            attrStr.addAttribute(
                .foregroundColor,
                value: NSColor.systemGreen,
                range: match.range
            )
        }
    }

    // MARK: - 2. Keys (cyan) — overrides green from step 1

    /// Matches a double-quoted string followed by optional whitespace and a colon.
    /// Only the quoted key portion is colored; the colon is handled separately.
    private func applyKeys(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        guard let pattern = regex(#""([^"\\]|\\.)*"\s*(?=:)"#) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches {
            attrStr.addAttribute(
                .foregroundColor,
                value: NSColor.systemCyan,
                range: match.range
            )
        }
    }

    // MARK: - 3. Numbers (orange)

    /// Matches JSON number literals (integers, decimals, scientific notation).
    /// The lookbehind ensures we only match numbers in value positions.
    private func applyNumbers(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        guard let pattern = regex(#"(?<=[:,\[\s])\s*-?\d+\.?\d*(?:[eE][+-]?\d+)?"#) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches {
            // Trim leading whitespace from the match to color only the number
            let matchedText = (attrStr.string as NSString).substring(with: match.range)
            let trimmed = matchedText.trimmingCharacters(in: .whitespaces)
            let leadingSpaces = matchedText.count - trimmed.count
            let numberRange = NSRange(
                location: match.range.location + leadingSpaces,
                length: trimmed.count
            )
            guard numberRange.length > 0 else { continue }

            attrStr.addAttribute(
                .foregroundColor,
                value: NSColor.systemOrange,
                range: numberRange
            )
        }
    }

    // MARK: - 4. Booleans (purple)

    private func applyBooleans(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        guard let pattern = regex(#"\b(true|false)\b"#) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches {
            attrStr.addAttribute(
                .foregroundColor,
                value: NSColor.systemPurple,
                range: match.range
            )
        }
    }

    // MARK: - 5. Null (gray)

    private func applyNull(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        guard let pattern = regex(#"\bnull\b"#) else { return }
        let matches = pattern.matches(in: attrStr.string, range: fullRange)

        for match in matches {
            attrStr.addAttribute(
                .foregroundColor,
                value: NSColor.systemGray,
                range: match.range
            )
        }
    }

    // MARK: - 6. Structural Characters (dimmed)

    /// Colors braces, brackets, colons, and commas with a semi-transparent foreground.
    private func applyStructural(
        in attrStr: NSMutableAttributedString,
        fullRange: NSRange,
        theme: Theme
    ) {
        // Use a character set approach for precise single-character matching
        let structuralCharacters: Set<Character> = ["{", "}", "[", "]", ",", ":"]
        let dimmedColor = theme.editorForeground.withAlphaComponent(0.5)
        let text = attrStr.string

        for (index, char) in text.enumerated() {
            guard structuralCharacters.contains(char) else { continue }

            let range = NSRange(location: index, length: 1)

            // Only color structural characters that are not inside a string.
            // Check if the current foreground is green (string) or cyan (key);
            // if so, skip — those are quoted content.
            if let currentColor = attrStr.attribute(.foregroundColor, at: index, effectiveRange: nil) as? NSColor {
                if currentColor == NSColor.systemGreen || currentColor == NSColor.systemCyan {
                    continue
                }
            }

            attrStr.addAttribute(.foregroundColor, value: dimmedColor, range: range)
        }
    }
}
