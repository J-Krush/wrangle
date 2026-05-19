import AppKit
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
@MainActor
@Observable
class EditorContext {
    /// Set by MarkdownTextView when it creates / updates the coordinator.
    weak var coordinator: MarkdownTextView.Coordinator?

    /// Currently active formats at the cursor position.
    var activeFormats = ActiveFormats()

    // MARK: - Find-in-Page

    var isFindBarVisible: Bool = false
    var findQuery: String = ""
    var findCaseSensitive: Bool = false
    var findMatches: [NSRange] = []
    var findCurrentIndex: Int = 0   // -1 when no matches

    func toggleFindBar() {
        if isFindBarVisible {
            closeFindBar()
        } else {
            isFindBarVisible = true
        }
    }

    func closeFindBar() {
        isFindBarVisible = false
        findQuery = ""
        findMatches = []
        findCurrentIndex = 0
    }

    /// Recompute matches for the current query and select the first one (if any).
    func recomputeMatches() {
        findMatches = coordinator?.findAll(findQuery, caseSensitive: findCaseSensitive) ?? []
        findCurrentIndex = findMatches.isEmpty ? 0 : 0
        if let first = findMatches.first {
            coordinator?.selectMatch(first)
        }
    }

    func advanceMatch(backwards: Bool = false) {
        guard !findMatches.isEmpty else { return }
        let count = findMatches.count
        let next = backwards
            ? (findCurrentIndex - 1 + count) % count
            : (findCurrentIndex + 1) % count
        findCurrentIndex = next
        coordinator?.selectMatch(findMatches[next])
    }

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

    /// Set the ordered list style hint for smart continuation.
    func setOrderedListStyle(_ style: OrderedListStyle) {
        coordinator?.orderedListStyleHint = style
    }

    func indentSelectedLines() { coordinator?.indentSelectedLines() }
    func dedentSelectedLines() { coordinator?.dedentSelectedLines() }
    func deleteCurrentLine() { coordinator?.deleteCurrentLine() }
    func moveLineUp() { coordinator?.moveLineUp() }
    func moveLineDown() { coordinator?.moveLineDown() }
    func duplicateLineUp() { coordinator?.duplicateLineUp() }
    func duplicateLineDown() { coordinator?.duplicateLineDown() }
    func insertBlankLineBelow() { coordinator?.insertBlankLineBelow() }
    func insertBlankLineAbove() { coordinator?.insertBlankLineAbove() }
    func clearLinePrefix() { coordinator?.clearLinePrefix() }
}
