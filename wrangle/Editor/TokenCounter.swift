import Foundation
import SwiftUI

struct TokenCounter {
    /// Approximate token count using a word-based heuristic.
    ///
    /// Average English text produces roughly 1.3 tokens per word, while code and
    /// structured content (JSON, XML, prompts) skews higher because punctuation
    /// and special characters tend to become individual tokens.
    static func count(_ text: String) -> Int {
        guard !text.isEmpty else { return 0 }

        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let wordCount = words.count

        // Heuristic: count special characters that typically become separate tokens
        let specialChars = text.filter { "{}[]()<>|/\\@#$%^&*+=~`".contains($0) }.count

        // Each word averages ~1.3 tokens, special chars are often individual tokens
        let estimate = Int(Double(wordCount) * 1.3) + (specialChars / 2)
        return max(estimate, 1)
    }

    /// Human-friendly string, e.g. "3.2K" for large counts.
    static func formattedCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }

    /// Color hint for status bar — green is safe, red is dangerously large.
    static func colorForCount(_ count: Int) -> Color {
        switch count {
        case ..<4000: return .green
        case 4000..<8000: return .yellow
        case 8000..<32000: return .orange
        default: return .red
        }
    }
}
