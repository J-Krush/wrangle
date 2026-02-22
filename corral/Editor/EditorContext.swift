import Foundation

/// Tracks which markdown formatting is active at the current cursor position.
struct ActiveFormats: Equatable {
    var heading: Int = 0 // 0 = none, 1–6 = heading level
    var bold = false
    var italic = false
    var strikethrough = false
    var inlineCode = false
    var bulletList = false
    var numberedList = false
    var blockquote = false
    var codeBlock = false
}

/// Shared context that bridges the EditorToolbar (SwiftUI) with the
/// MarkdownTextView coordinator (AppKit). The toolbar calls methods on
/// this object, which forwards them to the coordinator's NSTextView.
@Observable
class EditorContext {
    /// Set by MarkdownTextView when it creates / updates the coordinator.
    weak var coordinator: MarkdownTextView.Coordinator?

    /// Currently active formats at the cursor position.
    var activeFormats = ActiveFormats()

    /// Wrap the current selection (or insert at cursor) with prefix and suffix.
    func insertFormatting(prefix: String, suffix: String) {
        coordinator?.insertFormatting(prefix: prefix, suffix: suffix)
    }

    /// Insert a prefix at the start of the current line (toggles if already present).
    func insertLinePrefix(_ prefix: String) {
        coordinator?.insertLinePrefix(prefix)
    }

    /// Insert a standalone block of text at the cursor position.
    func insertBlock(_ block: String) {
        coordinator?.insertBlock(block)
    }
}
