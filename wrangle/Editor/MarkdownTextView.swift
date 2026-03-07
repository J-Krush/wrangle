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
    @AppStorage("showLineNumbers") private var showLineNumbers: Bool = true

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

        // Set default paragraph style so empty lines match styled lines (consistent lineSpacing)
        let baseParagraph = NSMutableParagraphStyle()
        baseParagraph.lineSpacing = theme.lineSpacing
        textView.defaultParagraphStyle = baseParagraph

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

        // Wire XML fold toggle callback
        textView.onXMLCollapseToggle = { [weak coordinator = context.coordinator] offset in
            coordinator?.toggleXMLCollapse(at: offset)
        }

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
            context.coordinator.collapsedXMLTagOffsets.removeAll()
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

        // Toggle line numbers and sync editing mode
        if let editorTV = textView as? EditorTextView {
            editorTV.editingMode = editingMode
            let shouldShow = editingMode == .dev && showLineNumbers
            if editorTV.showLineNumbers != shouldShow {
                editorTV.showLineNumbers = shouldShow
                editorTV.needsDisplay = true
            }
        }

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

        /// Style hint for ordered list continuation (set via toolbar dropdown).
        var orderedListStyleHint: OrderedListStyle?

        /// Guard against re-entrant styling triggered by our own attribute changes.
        private var isStyling = false

        /// Tags currently collapsed by the user (keyed by character offset of opening `<`).
        var collapsedXMLTagOffsets: Set<Int> = []

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
            textView.undoManager?.disableUndoRegistration()
            storage.beginEditing()
            storage.setAttributedString(plain)
            storage.endEditing()
            textView.undoManager?.enableUndoRegistration()
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

            textView.undoManager?.disableUndoRegistration()
            defer { textView.undoManager?.enableUndoRegistration() }

            storage.beginEditing()
            // Apply attributes only (same approach as restyleInPlace)
            let fullRange = NSRange(location: 0, length: storage.length)
            styled.enumerateAttributes(in: fullRange) { attrs, range, _ in
                storage.setAttributes(attrs, range: range)
            }

            // Layer XML tag rendering on top (not for JSON)
            if !isJSONDoc {
                let foldEnabled = editingMode == .writing
                XMLTagRenderer.render(
                    in: storage,
                    foldingEnabled: foldEnabled,
                    collapsedOffsets: foldEnabled ? collapsedXMLTagOffsets : []
                )
            }

            // Replace bullet markers with • in the storage
            if !isJSONDoc {
                applyBulletMarkers(in: storage)
            }
            storage.endEditing()

            restoreSelection(selectedRanges, in: textView)

            // Sync fold state to the text view for triangle drawing
            if let editorTV = textView as? EditorTextView {
                editorTV.xmlCollapsedOffsets = collapsedXMLTagOffsets
                editorTV.updateCopyButtons()
            }
        }

        /// Publicly accessible restyle, called when editing mode changes.
        func forceRestyle() {
            restyleInPlace()
        }

        /// Toggles collapse for the XML tag at the given character offset, then restyles.
        func toggleXMLCollapse(at offset: Int) {
            if collapsedXMLTagOffsets.contains(offset) {
                collapsedXMLTagOffsets.remove(offset)
            } else {
                collapsedXMLTagOffsets.insert(offset)
            }
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

            textView.undoManager?.disableUndoRegistration()
            defer { textView.undoManager?.enableUndoRegistration() }

            storage.beginEditing()

            // Restore • back to - so parser regex matches on next restyle
            restoreBulletMarkers(in: storage)

            // Replace attributes only, keeping the same string
            let fullRange = NSRange(location: 0, length: storage.length)
            styled.enumerateAttributes(in: fullRange) { attrs, range, _ in
                storage.setAttributes(attrs, range: range)
            }

            // Layer XML tag rendering on top (not for JSON)
            if !isJSON {
                let foldEnabled = editingMode == .writing
                XMLTagRenderer.render(
                    in: storage,
                    foldingEnabled: foldEnabled,
                    collapsedOffsets: foldEnabled ? collapsedXMLTagOffsets : []
                )
            }

            // Replace bullet markers with • in the storage
            if !isJSON {
                applyBulletMarkers(in: storage)
            }

            storage.endEditing()

            // Restore selection
            restoreSelection(selectedRanges, in: textView)

            // Sync fold state to the text view for triangle drawing
            if let editorTV = textView as? EditorTextView {
                editorTV.xmlCollapsedOffsets = collapsedXMLTagOffsets
                editorTV.updateCopyButtons()
            }
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


        // MARK: - Undo Helpers

        /// Breaks undo coalescing so the next edit starts a fresh undo group.
        private func breakUndo() {
            textView?.breakUndoCoalescing()
        }

        // MARK: - Toolbar Interaction Methods

        /// Insert formatting prefix/suffix around the current selection or at cursor.
        /// Used by the EditorToolbar for wrap-style formatting (bold, italic, code, etc.)
        func insertFormatting(prefix: String, suffix: String) {
            guard let textView else { return }
            breakUndo()

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

        // Cached regex for heading prefix detection
        private static let linePrefixHeadingRegex = try! NSRegularExpression(pattern: "^#{1,6}\\s+")

        /// Insert a prefix at the start of the current line (or all selected lines).
        /// Used by the EditorToolbar for line-level formatting (headings, lists, blockquotes).
        func insertLinePrefix(_ prefix: String) {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let sel = textView.selectedRange()
            let nsString = rawText(from: storage) as NSString

            // Multi-line selection: apply prefix to every non-empty line
            if sel.length > 0 {
                let lineRange = LineOperations.expandToFullLines(in: nsString, range: sel)
                let lineText = nsString.substring(with: lineRange)
                let lines = lineText.components(separatedBy: "\n")
                let nonEmptyCount = lines.filter({ !$0.isEmpty }).count

                if nonEmptyCount > 1 {
                    let result = LineOperations.toggleLinePrefixes(lines: lines, prefix: prefix)
                    textView.insertText(result, replacementRange: lineRange)
                    textView.setSelectedRange(NSRange(location: lineRange.location, length: (result as NSString).length))
                    return
                }
            }

            // Single-line logic
            let cursorPos = sel.location
            let lineRange = nsString.lineRange(for: NSRange(location: min(cursorPos, nsString.length), length: 0))
            let lineText = nsString.substring(with: lineRange)

            // For heading toggling: if line already starts with # prefix, replace it
            if prefix.hasPrefix("#") {
                if let headingMatch = Self.linePrefixHeadingRegex.firstMatch(
                    in: lineText, range: NSRange(location: 0, length: lineText.count)
                ) {
                    let existingPrefix = (lineText as NSString).substring(with: headingMatch.range)
                    if existingPrefix == prefix {
                        let removeRange = NSRange(location: lineRange.location, length: headingMatch.range.length)
                        textView.insertText("", replacementRange: removeRange)
                    } else {
                        let removeRange = NSRange(location: lineRange.location, length: headingMatch.range.length)
                        textView.insertText(prefix, replacementRange: removeRange)
                    }
                    return
                }
            }

            // Detect whether the new prefix is ordered or bullet
            let newIsOrdered = !prefix.hasPrefix("-") && !prefix.hasPrefix("*") && !prefix.hasPrefix("+") && !prefix.hasPrefix(">") && !prefix.hasPrefix("#")
            let newIsBullet = prefix == "- " || prefix == "* " || prefix == "+ "

            // Check for existing ordered list prefix on the line
            if let existing = LineOperations.orderedPrefixLength(in: lineText) {
                if newIsOrdered || newIsBullet {
                    let trimmed = String(lineText.drop(while: { $0 == " " || $0 == "\t" }))
                    if trimmed.hasPrefix(prefix) {
                        // Exact same marker → toggle off (remove marker, keep indent)
                        let markerRange = NSRange(location: lineRange.location + existing.indent, length: existing.total - existing.indent)
                        textView.insertText("", replacementRange: markerRange)
                    } else {
                        // Different style → replace only the marker portion, preserve indent
                        let markerRange = NSRange(location: lineRange.location + existing.indent, length: existing.total - existing.indent)
                        textView.insertText(prefix, replacementRange: markerRange)
                    }
                    return
                }
            }

            // Check for existing bullet prefix on the line
            if let existing = LineOperations.bulletPrefixLength(in: lineText) {
                if newIsOrdered || newIsBullet {
                    let trimmed = String(lineText.drop(while: { $0 == " " || $0 == "\t" }))
                    if trimmed.hasPrefix(prefix) {
                        // Exact same marker → toggle off (remove marker, keep indent)
                        let markerRange = NSRange(location: lineRange.location + existing.indent, length: existing.total - existing.indent)
                        textView.insertText("", replacementRange: markerRange)
                    } else {
                        // Different style → replace only the marker portion, preserve indent
                        let markerRange = NSRange(location: lineRange.location + existing.indent, length: existing.total - existing.indent)
                        textView.insertText(prefix, replacementRange: markerRange)
                    }
                    return
                }
            }

            // For blockquote/other toggling: if line already has the prefix, remove it
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
            breakUndo()
            let selectedRange = textView.selectedRange()
            textView.insertText(block, replacementRange: selectedRange)
        }

        // MARK: - Indent / Dedent

        func indentSelectedLines() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = LineOperations.expandToFullLines(in: nsString, range: sel)
            let lineText = nsString.substring(with: lineRange)
            let indented = LineOperations.adjustOrderedMarkersForIndent(
                LineOperations.indentLines(lineText)
            )

            textView.insertText(indented, replacementRange: lineRange)

            if sel.length == 0 {
                let newPos = min(sel.location + 4, lineRange.location + (indented as NSString).length)
                textView.setSelectedRange(NSRange(location: newPos, length: 0))
            } else {
                let newLength = (indented as NSString).length
                textView.setSelectedRange(NSRange(location: lineRange.location, length: newLength))
            }
        }

        func shouldIndentCurrentLine() -> Bool {
            guard let textView, let storage = textView.textStorage else { return false }
            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: NSRange(location: min(sel.location, nsString.length), length: 0))
            let lineText = nsString.substring(with: lineRange).replacingOccurrences(of: "\n", with: "")

            // Always indent list lines
            if LineOperations.isListLine(lineText) { return true }

            // Indent if cursor is in leading whitespace (before content)
            let cursorOffset = sel.location - lineRange.location
            let clampedOffset = min(cursorOffset, (lineText as NSString).length)
            let prefix = (lineText as NSString).substring(to: clampedOffset)
            if prefix.allSatisfy({ $0 == " " || $0 == "\t" }) && !lineText.isEmpty {
                return true
            }
            return false
        }

        func dedentSelectedLines() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = LineOperations.expandToFullLines(in: nsString, range: sel)
            let lineText = nsString.substring(with: lineRange)
            let dedented = LineOperations.adjustOrderedMarkersForIndent(
                LineOperations.dedentLines(lineText)
            )

            let removedChars = (lineText as NSString).length - (dedented as NSString).length
            textView.insertText(dedented, replacementRange: lineRange)

            if sel.length == 0 {
                let newPos = max(sel.location - removedChars, lineRange.location)
                textView.setSelectedRange(NSRange(location: newPos, length: 0))
            } else {
                let newLength = (dedented as NSString).length
                textView.setSelectedRange(NSRange(location: lineRange.location, length: newLength))
            }
        }

        // MARK: - Line Operations

        func deleteCurrentLine() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            guard nsString.length > 0 else { return }

            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: sel)

            textView.insertText("", replacementRange: lineRange)
        }

        func moveLineUp() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: sel)

            // Can't move first line up
            guard lineRange.location > 0 else { return }

            let prevLineRange = nsString.lineRange(for: NSRange(location: lineRange.location - 1, length: 0))
            let currentText = nsString.substring(with: lineRange)
            let prevText = nsString.substring(with: prevLineRange)

            // Ensure both end with newline for clean swap
            let currentHasNewline = currentText.hasSuffix("\n")
            let prevHasNewline = prevText.hasSuffix("\n")

            var newCurrent = currentHasNewline ? currentText : currentText + "\n"
            var newPrev = prevHasNewline ? prevText : prevText + "\n"

            // If current was the last line (no trailing newline), strip from moved-up and add to moved-down
            if !currentHasNewline {
                newCurrent = String(newCurrent.dropLast())
                if !newPrev.hasSuffix("\n") {
                    newPrev += "\n"
                }
            }

            let combined = newCurrent + newPrev
            // If the last line in doc shouldn't end with \n, trim trailing
            let totalRange = NSRange(location: prevLineRange.location, length: lineRange.location + lineRange.length - prevLineRange.location)
            let originalText = nsString.substring(with: totalRange)
            let trimmedCombined = originalText.hasSuffix("\n") ? combined : combined.hasSuffix("\n") ? String(combined.dropLast()) : combined

            textView.insertText(trimmedCombined, replacementRange: totalRange)

            // Place cursor at corresponding position in moved line
            let offset = sel.location - lineRange.location
            let newCursorLoc = prevLineRange.location + offset
            let newSelLength = sel.length
            textView.setSelectedRange(NSRange(location: newCursorLoc, length: newSelLength))
        }

        func moveLineDown() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: sel)

            // Can't move last line down
            let lineEnd = lineRange.location + lineRange.length
            guard lineEnd < nsString.length else { return }

            let nextLineRange = nsString.lineRange(for: NSRange(location: lineEnd, length: 0))
            let currentText = nsString.substring(with: lineRange)
            let nextText = nsString.substring(with: nextLineRange)

            let currentHasNewline = currentText.hasSuffix("\n")
            let nextHasNewline = nextText.hasSuffix("\n")

            var newNext = nextHasNewline ? nextText : nextText + "\n"
            let newCurrent = currentHasNewline ? currentText : currentText + "\n"

            if !nextHasNewline {
                newNext = String(newNext.dropLast())
                // Moved-down current might need trailing \n stripped
            }

            let combined = newNext + newCurrent
            let totalRange = NSRange(location: lineRange.location, length: nextLineRange.location + nextLineRange.length - lineRange.location)
            let originalText = nsString.substring(with: totalRange)
            let trimmedCombined = originalText.hasSuffix("\n") ? combined : combined.hasSuffix("\n") ? String(combined.dropLast()) : combined

            textView.insertText(trimmedCombined, replacementRange: totalRange)

            let offset = sel.location - lineRange.location
            let newCursorLoc = lineRange.location + (newNext as NSString).length + offset
            textView.setSelectedRange(NSRange(location: newCursorLoc, length: sel.length))
        }

        func duplicateLineUp() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: sel)
            var lineText = nsString.substring(with: lineRange)

            // Ensure line ends with newline so duplicate goes above
            if !lineText.hasSuffix("\n") { lineText += "\n" }

            textView.insertText(lineText, replacementRange: NSRange(location: lineRange.location, length: 0))
            // Cursor stays on original line (which shifted down)
        }

        func duplicateLineDown() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: sel)
            var lineText = nsString.substring(with: lineRange)

            let lineEnd = lineRange.location + lineRange.length
            // Ensure we insert with a newline separator
            if !lineText.hasSuffix("\n") { lineText = "\n" + lineText } else {
                // Insert after the line
            }

            if lineText.hasSuffix("\n") {
                textView.insertText(lineText, replacementRange: NSRange(location: lineEnd, length: 0))
            } else {
                textView.insertText(lineText, replacementRange: NSRange(location: lineEnd, length: 0))
            }

            // Move cursor to the duplicated line
            let offset = sel.location - lineRange.location
            let newLoc = lineEnd + offset
            textView.setSelectedRange(NSRange(location: newLoc, length: sel.length))
        }

        func insertBlankLineBelow() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: sel)
            let lineEnd = lineRange.location + lineRange.length

            if lineEnd <= nsString.length && lineEnd > 0 {
                // Line ends with \n → insert at lineEnd
                textView.insertText("\n", replacementRange: NSRange(location: lineEnd, length: 0))
                textView.setSelectedRange(NSRange(location: lineEnd, length: 0))
            } else {
                // Last line with no trailing newline
                textView.insertText("\n", replacementRange: NSRange(location: nsString.length, length: 0))
                textView.setSelectedRange(NSRange(location: nsString.length + 1, length: 0))
            }
        }

        func insertBlankLineAbove() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: sel)

            textView.insertText("\n", replacementRange: NSRange(location: lineRange.location, length: 0))
            textView.setSelectedRange(NSRange(location: lineRange.location, length: 0))
        }

        // MARK: - Clear Line Prefix

        private static let clearLinePrefixRegex = try! NSRegularExpression(pattern: "^#{1,6}\\s+")

        func clearLinePrefix() {
            guard let textView, let storage = textView.textStorage else { return }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: sel)
            let lineText = nsString.substring(with: lineRange)

            if let m = Self.clearLinePrefixRegex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.count)) {
                let removeRange = NSRange(location: lineRange.location, length: m.range.length)
                textView.insertText("", replacementRange: removeRange)
            }
        }

        // MARK: - Smart Enter

        func handleSmartEnter() -> Bool {
            guard let textView, let storage = textView.textStorage else { return false }
            breakUndo()

            let nsString = rawText(from: storage) as NSString
            guard nsString.length > 0 else { return false }

            let sel = textView.selectedRange()
            let lineRange = nsString.lineRange(for: NSRange(location: min(sel.location, nsString.length), length: 0))
            let lineText = nsString.substring(with: lineRange).replacingOccurrences(of: "\n", with: "")

            // Only trigger when cursor is at end of line content
            let lineContentEnd = lineRange.location + (lineText as NSString).length
            let cursorAtEOL = sel.location >= lineContentEnd && sel.length == 0

            let action = LineOperations.detectContinuationPrefix(
                for: lineText,
                cursorAtEOL: cursorAtEOL,
                orderedListStyleHint: orderedListStyleHint
            )

            switch action {
            case .continueWith(let prefix):
                textView.insertText("\n" + prefix, replacementRange: sel)
                return true
            case .exitList(let clearLength):
                orderedListStyleHint = nil
                // Replace the empty prefix line content with just a newline
                let clearRange = NSRange(location: lineRange.location, length: clearLength)
                textView.insertText("\n", replacementRange: clearRange)
                return true
            case .none:
                return false
            }
        }

        // MARK: - Bullet Marker Helpers

        /// Restores `•` back to `-` in storage before restyling
        private func restoreBulletMarkers(in storage: NSTextStorage) {
            var ranges: [NSRange] = []
            storage.enumerateAttribute(.bulletMarker, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
                if value != nil { ranges.append(range) }
            }
            for range in ranges.reversed() {
                let attrs = storage.attributes(at: range.location, effectiveRange: nil)
                storage.replaceCharacters(in: range, with: NSAttributedString(string: "-", attributes: attrs))
            }
        }

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

            // Clear XML collapse state — offsets are invalidated by edits
            collapsedXMLTagOffsets.removeAll()

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

            // Redraw line numbers so the current line highlight follows the cursor
            if let editorTV = textView as? EditorTextView, editorTV.showLineNumbers {
                editorTV.needsDisplay = true
            }
        }

        // MARK: - Active Format Detection

        // Compiled regexes for format detection (static to avoid recompilation)
        private static let headingRegex = try! NSRegularExpression(pattern: "^(#{1,6})\\s+", options: .anchorsMatchLines)
        private static let blockquoteRegex = try! NSRegularExpression(pattern: "^>\\s?", options: .anchorsMatchLines)
        private static let bulletRegex = try! NSRegularExpression(pattern: "^\\s*[-*]\\s+", options: .anchorsMatchLines)
        private static let numberedRegex = try! NSRegularExpression(pattern: "^\\s*(?:\\d+|[a-zA-Z]+)\\.\\s+", options: .anchorsMatchLines)
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
