import AppKit
import SwiftUI

/// An `NSViewRepresentable` that wraps an `NSTextView` for rich, inline-rendered
/// markdown editing. Raw markdown is stored in the binding; the view displays a
/// styled `NSAttributedString` produced by `MarkdownParser` and `XMLTagRenderer`.
///
/// The coordinator exposes methods for toolbar-driven formatting (insert at cursor,
/// wrap selection, insert line prefix). Cursor movement triggers restyle so that
/// syntax characters are revealed only on the active line (Obsidian-style editing).
struct MarkdownTextView: NSViewRepresentable {

    @Binding var text: String
    var document: EditorDocument?
    /// Optional shared context so external views (like toolbars) can drive formatting.
    var editorContext: EditorContext?
    var editingMode: EditingMode = .writing

    // MARK: - NSViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, document: document, editingMode: editingMode)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = EditorTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.usesFindPanel = true

        // Disable smart substitutions that interfere with markdown/code editing
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false

        // Layout and appearance
        let theme = Theme.current
        textView.backgroundColor = theme.editorBackground
        textView.insertionPointColor = theme.editorForeground
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.font = theme.editorFont
        textView.textColor = theme.editorForeground

        // Enable line wrapping at the scroll view width
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        // Continuous layout for smoother editing
        textView.layoutManager?.allowsNonContiguousLayout = false

        // Set delegates
        textView.delegate = context.coordinator
        textView.textStorage?.delegate = context.coordinator

        // Store a reference for later updates
        context.coordinator.textView = textView

        scrollView.documentView = textView

        // Apply initial content
        context.coordinator.setTextViewContent(text)

        // Publish coordinator to the editor context so toolbars can interact
        editorContext?.coordinator = context.coordinator

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        // Keep editor context reference up to date
        editorContext?.coordinator = context.coordinator

        // Sync editing mode and restyle if it changed
        let modeChanged = context.coordinator.editingMode != editingMode
        context.coordinator.editingMode = editingMode

        // Only push changes if the source of truth (binding) differs from what the
        // text view currently holds AND the change originated externally (not from typing).
        let currentPlain = textView.textStorage?.string ?? ""
        if currentPlain != text && !context.coordinator.isUpdatingFromTextView {
            context.coordinator.setTextViewContent(text)
        } else if modeChanged {
            context.coordinator.forceRestyle()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var text: Binding<String>
        var document: EditorDocument?
        weak var textView: NSTextView?
        var editingMode: EditingMode = .writing

        /// Guard against feedback loops: true while we are pushing changes from the
        /// text view back to the binding (so `updateNSView` won't re-enter).
        var isUpdatingFromTextView = false

        /// Guard against re-entrant styling triggered by our own attribute changes.
        private var isStyling = false

        private let parser = MarkdownParser()

        /// Track which line the cursor was on last, so we only restyle when it changes lines.
        private var lastCursorLineRange: NSRange?

        /// Whether this is a JSON document (uses different highlighter)
        var isJSON: Bool {
            document?.fileURL?.pathExtension.lowercased() == "json"
        }

        init(text: Binding<String>, document: EditorDocument?, editingMode: EditingMode = .writing) {
            self.text = text
            self.document = document
            self.editingMode = editingMode
        }

        // MARK: - Content Management

        /// Replaces the text view's content and re-applies styling.
        func setTextViewContent(_ plainText: String) {
            guard let textView else { return }

            isStyling = true
            defer { isStyling = false }

            let hidesSyntax = editingMode == .writing

            let styled: NSAttributedString
            if isJSON {
                styled = JsonSyntaxHighlighter().highlight(plainText, theme: .current)
            } else {
                styled = parser.parse(plainText, cursorPosition: nil, hideMarkdownSyntax: hidesSyntax, theme: .current)
            }

            // Preserve selection
            let selectedRanges = textView.selectedRanges

            textView.textStorage?.beginEditing()
            textView.textStorage?.setAttributedString(styled)

            // Apply XML tag rendering on top of markdown (not for JSON)
            if !isJSON, let storage = textView.textStorage {
                XMLTagRenderer.render(in: storage)
            }

            textView.textStorage?.endEditing()

            // Restore selection if still valid
            restoreSelection(selectedRanges, in: textView)

            // Update code block copy buttons
            (textView as? EditorTextView)?.updateCopyButtons()
        }

        /// Publicly accessible restyle, called when editing mode changes.
        func forceRestyle() {
            restyleInPlace()
        }

        /// Re-styles the current content in-place, preserving the cursor.
        private func restyleInPlace() {
            guard let textView, let storage = textView.textStorage else { return }

            isStyling = true
            defer { isStyling = false }

            let plainText = storage.string
            let hidesSyntax = editingMode == .writing
            // In dev mode, pass nil cursor so all lines get full styling without hiding
            let cursorPos = hidesSyntax ? currentCursorPosition() : nil

            let styled: NSAttributedString
            if isJSON {
                styled = JsonSyntaxHighlighter().highlight(plainText, theme: .current)
            } else {
                styled = parser.parse(plainText, cursorPosition: cursorPos, hideMarkdownSyntax: hidesSyntax, theme: .current)
            }

            let selectedRanges = textView.selectedRanges

            storage.beginEditing()

            // Replace attributes only, keeping the same string
            let fullRange = NSRange(location: 0, length: storage.length)
            styled.enumerateAttributes(in: fullRange) { attrs, range, _ in
                storage.setAttributes(attrs, range: range)
            }

            // Layer XML tag rendering on top (not for JSON)
            if !isJSON {
                XMLTagRenderer.render(in: storage)
            }

            storage.endEditing()

            // Restore selection
            restoreSelection(selectedRanges, in: textView)

            // Update code block copy buttons
            (textView as? EditorTextView)?.updateCopyButtons()
        }

        private func restoreSelection(_ selectedRanges: [NSValue], in textView: NSTextView) {
            let maxLength = textView.textStorage?.length ?? 0
            let restoredRanges = selectedRanges.compactMap { rangeValue -> NSValue? in
                let range = rangeValue.rangeValue
                if range.location <= maxLength {
                    let clampedLength = min(range.length, maxLength - range.location)
                    return NSValue(range: NSRange(location: range.location, length: clampedLength))
                }
                return nil
            }
            if !restoredRanges.isEmpty {
                textView.setSelectedRanges(restoredRanges, affinity: .downstream, stillSelecting: false)
            }
        }

        private func currentCursorPosition() -> Int? {
            guard let textView else { return nil }
            let range = textView.selectedRange()
            return range.location
        }

        private func currentCursorLineRange() -> NSRange? {
            guard let textView, let storage = textView.textStorage else { return nil }
            let cursorPos = textView.selectedRange().location
            guard cursorPos <= storage.length else { return nil }
            return (storage.string as NSString).lineRange(for: NSRange(location: cursorPos, length: 0))
        }

        // MARK: - Toolbar Interaction Methods

        /// Insert formatting prefix/suffix around the current selection or at cursor.
        /// Used by the EditorToolbar for wrap-style formatting (bold, italic, code, etc.)
        func insertFormatting(prefix: String, suffix: String) {
            guard let textView else { return }

            let selectedRange = textView.selectedRange()
            let storage = textView.textStorage?.string ?? ""
            let nsString = storage as NSString

            if selectedRange.length > 0 {
                // Wrap the selection
                let selectedText = nsString.substring(with: selectedRange)
                let replacement = prefix + selectedText + suffix
                textView.insertText(replacement, replacementRange: selectedRange)
            } else {
                // Insert at cursor with cursor positioned between prefix and suffix
                let replacement = prefix + suffix
                textView.insertText(replacement, replacementRange: selectedRange)
                // Move cursor between prefix and suffix
                let newPos = selectedRange.location + prefix.count
                textView.setSelectedRange(NSRange(location: newPos, length: 0))
            }
        }

        /// Insert a prefix at the start of the current line.
        /// Used by the EditorToolbar for line-level formatting (headings, lists, blockquotes).
        func insertLinePrefix(_ prefix: String) {
            guard let textView, let storage = textView.textStorage else { return }

            let cursorPos = textView.selectedRange().location
            let nsString = storage.string as NSString
            let lineRange = nsString.lineRange(for: NSRange(location: min(cursorPos, nsString.length), length: 0))

            // Check if there's already a heading/list prefix on this line
            let lineText = nsString.substring(with: lineRange)

            // For heading toggling: if line already starts with # prefix, replace it
            if prefix.hasPrefix("#") {
                // Remove any existing heading prefix
                if let headingMatch = try? NSRegularExpression(pattern: "^#{1,6}\\s+").firstMatch(
                    in: lineText, range: NSRange(location: 0, length: lineText.count)
                ) {
                    let existingPrefix = (lineText as NSString).substring(with: headingMatch.range)
                    if existingPrefix == prefix {
                        // Same heading level — toggle off (remove prefix)
                        let removeRange = NSRange(location: lineRange.location, length: headingMatch.range.length)
                        textView.insertText("", replacementRange: removeRange)
                    } else {
                        // Different heading level — replace
                        let removeRange = NSRange(location: lineRange.location, length: headingMatch.range.length)
                        textView.insertText(prefix, replacementRange: removeRange)
                    }
                    return
                }
            }

            // For blockquote/list toggling: if line already has the prefix, remove it
            if lineText.hasPrefix(prefix) {
                let removeRange = NSRange(location: lineRange.location, length: prefix.count)
                textView.insertText("", replacementRange: removeRange)
                return
            }

            // Insert the prefix at the start of the line
            let insertPos = lineRange.location
            textView.insertText(prefix, replacementRange: NSRange(location: insertPos, length: 0))
        }

        /// Insert a block of text at the cursor position.
        func insertBlock(_ block: String) {
            guard let textView else { return }
            let selectedRange = textView.selectedRange()
            textView.insertText(block, replacementRange: selectedRange)
        }

        // MARK: - NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard !isStyling else { return }

            let newText = textView.textStorage?.string ?? ""

            // Push plain text back to the binding
            isUpdatingFromTextView = true
            text.wrappedValue = newText
            document?.content = newText
            document?.markDirty()
            isUpdatingFromTextView = false

            // Re-apply styling after the user's edit
            restyleInPlace()

            // Update cursor line tracking
            lastCursorLineRange = currentCursorLineRange()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isStyling else { return }

            // Check if cursor moved to a different line — if so, restyle to
            // reveal syntax on the new line and hide it on the old one.
            let newLineRange = currentCursorLineRange()
            if newLineRange != lastCursorLineRange {
                lastCursorLineRange = newLineRange
                restyleInPlace()
            }
        }

        // MARK: - NSTextStorageDelegate

        func textStorage(
            _ textStorage: NSTextStorage,
            didProcessEditing editedMask: NSTextStorageEditActions,
            range editedRange: NSRange,
            changeInLength delta: Int
        ) {
            // Styling is handled in textDidChange and textViewDidChangeSelection.
        }
    }
}
