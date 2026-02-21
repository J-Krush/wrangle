import Foundation

/// Shared context that bridges the EditorToolbar (SwiftUI) with the
/// MarkdownTextView coordinator (AppKit). The toolbar calls methods on
/// this object, which forwards them to the coordinator's NSTextView.
@Observable
class EditorContext {
    /// Set by MarkdownTextView when it creates / updates the coordinator.
    weak var coordinator: MarkdownTextView.Coordinator?

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
