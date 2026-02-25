import AppKit
import SwiftUI

/// An `NSViewRepresentable` that wraps an `NSTextView` for rich, inline-rendered
/// markdown editing. Raw markdown is stored in the binding; the view displays a
/// styled `NSAttributedString` produced by `MarkdownParser` and `XMLTagRenderer`.
///
/// The coordinator exposes methods for toolbar-driven formatting (insert at cursor,
/// wrap selection, insert line prefix). In writing mode, all syntax characters are
/// hidden. In dev mode, all syntax characters are visible.
struct MarkdownTextView: NSViewRepresentable {

    @Binding var text: String
    var document: EditorDocument?
    /// Optional shared context so external views (like toolbars) can drive formatting.
    var editorContext: EditorContext?
    var editingMode: EditingMode = .writing
    @Environment(\.colorScheme) private var colorScheme

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
        textView.textContainerInset = NSSize(width: 35, height: 50)
        textView.font = theme.editorFont
        textView.textColor = theme.editorForeground

        // Enable line wrapping at the scroll view width
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        // Non-contiguous layout: skip off-screen text during initial layout
        textView.layoutManager?.allowsNonContiguousLayout = true

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
        context.coordinator.editorContext = editorContext

        // Wire formatting delegate for keyboard shortcuts
        textView.formattingDelegate = context.coordinator

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        // Keep editor context reference up to date
        editorContext?.coordinator = context.coordinator
        context.coordinator.editorContext = editorContext

        // Detect document switch (since we no longer use .id(doc.id))
        let documentChanged = context.coordinator.documentID != document?.id
        if documentChanged {
            context.coordinator.document = document
            context.coordinator.documentID = document?.id
        }

        // Detect appearance change and update NSTextView colors + restyle
        let appearanceChanged = context.coordinator.lastColorScheme != colorScheme
        if appearanceChanged {
            context.coordinator.lastColorScheme = colorScheme
            let theme = Theme.current
            textView.backgroundColor = theme.editorBackground
            textView.insertionPointColor = theme.editorForeground
            textView.textColor = theme.editorForeground
        }

        // Sync editing mode and restyle if it changed
        let modeChanged = context.coordinator.editingMode != editingMode
        context.coordinator.editingMode = editingMode

        // Only push changes if the source of truth (binding) differs from what the
        // text view currently holds AND the change originated externally (not from typing).
        let currentPlain: String
        if let storage = textView.textStorage {
            currentPlain = context.coordinator.rawText(from: storage)
        } else {
            currentPlain = ""
        }
        if modeChanged || appearanceChanged {
            context.coordinator.forceRestyle()
        } else if currentPlain != text && !context.coordinator.isUpdatingFromTextView {
            context.coordinator.setTextViewContent(text)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate, EditorTextViewFormattingDelegate {
        var text: Binding<String>
        var document: EditorDocument?
        var documentID: UUID?
        weak var textView: NSTextView?
        weak var editorContext: EditorContext?
        var editingMode: EditingMode = .writing
        var lastColorScheme: ColorScheme?

        /// Guard against feedback loops: true while we are pushing changes from the
        /// text view back to the binding (so `updateNSView` won't re-enter).
        var isUpdatingFromTextView = false

        /// Guard against re-entrant styling triggered by our own attribute changes.
        private var isStyling = false

        /// Incremented on every `setTextViewContent` call so stale async results are discarded.
        private var parseGeneration: Int = 0

        private let parser = MarkdownParser()

        /// Whether this is a JSON document (uses different highlighter)
        var isJSON: Bool {
            document?.fileURL?.pathExtension.lowercased() == "json"
        }

        init(text: Binding<String>, document: EditorDocument?, editingMode: EditingMode = .writing) {
            self.text = text
            self.document = document
            self.documentID = document?.id
            self.editingMode = editingMode
        }

        // MARK: - Content Management

        /// Replaces the text view's content and re-applies styling.
        ///
        /// Phase 1 (immediate): set plain text with base styling so the user sees content instantly.
        /// Phase 2 (async): parse on a background thread, then apply attributes on main thread.
        func setTextViewContent(_ plainText: String) {
            guard let textView, let storage = textView.textStorage else { return }

            // Bump generation so any in-flight async parse is discarded
            parseGeneration += 1
            let currentGeneration = parseGeneration

            // --- Phase 1: Immediate plain-text display ---
            isStyling = true
            let theme = Theme.current
            let baseAttributes: [NSAttributedString.Key: Any] = [
                .font: theme.editorFont,
                .foregroundColor: theme.editorForeground,
            ]
            let plain = NSAttributedString(string: plainText, attributes: baseAttributes)

            let selectedRanges = textView.selectedRanges
            storage.beginEditing()
            storage.setAttributedString(plain)
            storage.endEditing()
            restoreSelection(selectedRanges, in: textView)
            isStyling = false

            // --- Phase 2: Async styled parse ---
            let hidesSyntax = editingMode == .writing
            let isJSONDoc = isJSON

            Task {
                let styled = await Task.detached {
                    if isJSONDoc {
                        return await JsonSyntaxHighlighter().highlight(plainText, theme: theme)
                    } else {
                        let bgParser = await MarkdownParser()
                        return await bgParser.parse(plainText, hideMarkdownSyntax: hidesSyntax, theme: theme)
                    }
                }.value
                self.applyParsedStyling(styled, isJSON: isJSONDoc, generation: currentGeneration)
            }
        }

        /// Applies the parsed attributed string's attributes to the text storage,
        /// but only if the generation matches (i.e., user hasn't switched files since).
        private func applyParsedStyling(_ styled: NSAttributedString, isJSON isJSONDoc: Bool, generation: Int) {
            guard let textView, let storage = textView.textStorage else { return }
            guard generation == parseGeneration else { return }
            // Guard against content mismatch (e.g., user typed while parse was in flight)
            guard storage.string == styled.string else { return }

            isStyling = true
            defer { isStyling = false }

            let selectedRanges = textView.selectedRanges

            storage.beginEditing()
            // Apply attributes only (same approach as restyleInPlace)
            let fullRange = NSRange(location: 0, length: storage.length)
            styled.enumerateAttributes(in: fullRange) { attrs, range, _ in
                storage.setAttributes(attrs, range: range)
            }

            // Layer XML tag rendering on top (not for JSON)
            if !isJSONDoc {
                XMLTagRenderer.render(in: storage)
            }

            // Replace bullet markers with • in the storage
            if !isJSONDoc {
                applyBulletMarkers(in: storage)
            }
            storage.endEditing()

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

            let plainText = rawText(from: storage)
            let hidesSyntax = editingMode == .writing

            let styled: NSAttributedString
            if isJSON {
                styled = JsonSyntaxHighlighter().highlight(plainText, theme: .current)
            } else {
                styled = parser.parse(plainText, hideMarkdownSyntax: hidesSyntax, theme: .current)
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

            // Replace bullet markers with • in the storage
            if !isJSON {
                applyBulletMarkers(in: storage)
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

        // MARK: - Bullet Marker Helpers

        /// Replaces `-`/`*` with `•` at positions marked with .bulletMarker
        private func applyBulletMarkers(in storage: NSTextStorage) {
            var ranges: [NSRange] = []
            storage.enumerateAttribute(.bulletMarker, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
                if value != nil { ranges.append(range) }
            }
            for range in ranges.reversed() {
                let attrs = storage.attributes(at: range.location, effectiveRange: nil)
                storage.replaceCharacters(in: range, with: NSAttributedString(string: "•", attributes: attrs))
            }
        }

        /// Reads raw text from storage, reversing any bullet marker replacements
        func rawText(from storage: NSTextStorage) -> String {
            let mutable = NSMutableString(string: storage.string)
            var positions: [Int] = []
            storage.enumerateAttribute(.bulletMarker, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
                if value != nil { positions.append(range.location) }
            }
            for pos in positions.reversed() {
                mutable.replaceCharacters(in: NSRange(location: pos, length: 1), with: "-")
            }
            return mutable as String
        }

        // MARK: - NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard !isStyling else { return }

            let newText: String
            if let storage = textView.textStorage {
                newText = rawText(from: storage)
            } else {
                newText = ""
            }

            // Push plain text back to the binding
            isUpdatingFromTextView = true
            defer { isUpdatingFromTextView = false }
            text.wrappedValue = newText
            document?.content = newText
            document?.markDirty()

            // Re-apply styling after the user's edit
            restyleInPlace()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            editorContext?.activeFormats = detectActiveFormats()
        }

        // MARK: - Active Format Detection

        // Compiled regexes for format detection (static to avoid recompilation)
        private static let headingRegex = try! NSRegularExpression(pattern: "^(#{1,6})\\s+", options: .anchorsMatchLines)
        private static let blockquoteRegex = try! NSRegularExpression(pattern: "^>\\s?", options: .anchorsMatchLines)
        private static let bulletRegex = try! NSRegularExpression(pattern: "^\\s*[-*]\\s+", options: .anchorsMatchLines)
        private static let numberedRegex = try! NSRegularExpression(pattern: "^\\s*\\d+\\.\\s+", options: .anchorsMatchLines)
        private static let boldRegex = try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*|__(.+?)__")
        private static let italicStarRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)")
        private static let italicUnderRegex = try! NSRegularExpression(pattern: "(?<!_)_(?!_)(.+?)(?<!_)_(?!_)")
        private static let strikethroughRegex = try! NSRegularExpression(pattern: "~~(.+?)~~")
        private static let inlineCodeRegex = try! NSRegularExpression(pattern: "`([^`\\n]+)`")
        private static let codeBlockRegex = try! NSRegularExpression(pattern: "^```[^\\n]*\\n[\\s\\S]*?^```", options: .anchorsMatchLines)

        private func detectActiveFormats() -> ActiveFormats {
            guard let textView, let storage = textView.textStorage else { return ActiveFormats() }

            var formats = ActiveFormats()
            let cursorPos = textView.selectedRange().location
            let text = storage.string
            let nsString = text as NSString
            guard cursorPos <= nsString.length else { return formats }

            let safePos = min(cursorPos, nsString.length)
            let lineRange = nsString.lineRange(for: NSRange(location: safePos, length: 0))
            let lineText = nsString.substring(with: lineRange)
            let lineNS = lineText as NSString
            let lineFullRange = NSRange(location: 0, length: lineNS.length)

            // Line-level: heading
            if let m = Self.headingRegex.firstMatch(in: lineText, range: lineFullRange) {
                formats.heading = m.range(at: 1).length
            }
            // Line-level: blockquote
            if Self.blockquoteRegex.firstMatch(in: lineText, range: lineFullRange) != nil {
                formats.blockquote = true
            }
            // Line-level: bullet list
            if Self.bulletRegex.firstMatch(in: lineText, range: lineFullRange) != nil {
                formats.bulletList = true
            }
            // Line-level: numbered list
            if Self.numberedRegex.firstMatch(in: lineText, range: lineFullRange) != nil {
                formats.numberedList = true
            }

            // Inline formats: check if cursor falls within any match on the current line
            let cursorInLine = cursorPos - lineRange.location

            func cursorInMatch(_ regex: NSRegularExpression) -> Bool {
                for match in regex.matches(in: lineText, range: lineFullRange) {
                    let r = match.range
                    if cursorInLine >= r.location && cursorInLine <= r.location + r.length {
                        return true
                    }
                }
                return false
            }

            formats.bold = cursorInMatch(Self.boldRegex)
            formats.italic = cursorInMatch(Self.italicStarRegex) || cursorInMatch(Self.italicUnderRegex)
            formats.strikethrough = cursorInMatch(Self.strikethroughRegex)
            formats.inlineCode = cursorInMatch(Self.inlineCodeRegex)

            // Code block: check if cursor is inside a fenced code block
            let fullRange = NSRange(location: 0, length: nsString.length)
            for match in Self.codeBlockRegex.matches(in: text, range: fullRange) {
                let r = match.range
                if cursorPos >= r.location && cursorPos <= r.location + r.length {
                    formats.codeBlock = true
                    break
                }
            }

            return formats
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
