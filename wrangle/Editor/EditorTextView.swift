import AppKit

extension NSAttributedString.Key {
    /// Custom attribute marking code block ranges for card-style background drawing.
    static let codeBlockBackground = NSAttributedString.Key("codeBlockBackground")
}

/// Delegate protocol for forwarding keyboard-driven formatting to the coordinator.
protocol EditorTextViewFormattingDelegate: AnyObject {
    func insertFormatting(prefix: String, suffix: String)
    func insertLinePrefix(_ prefix: String)
    func insertBlock(_ block: String)
    func indentSelectedLines()
    func dedentSelectedLines()
    func deleteCurrentLine()
    func moveLineUp()
    func moveLineDown()
    func duplicateLineUp()
    func duplicateLineDown()
    func insertBlankLineBelow()
    func insertBlankLineAbove()
    func clearLinePrefix()
    func handleSmartEnter() -> Bool
    func shouldIndentCurrentLine() -> Bool
}

/// Custom NSTextView subclass that draws rounded-rect card backgrounds behind
/// fenced code blocks and manages "copy" button overlays.
class EditorTextView: NSTextView {

    weak var formattingDelegate: EditorTextViewFormattingDelegate?
    private var copyButtons: [NSButton] = []

    /// Whether line numbers should be drawn in the left gutter (dev mode).
    var showLineNumbers: Bool = false

    /// Current editing mode — affects code block card padding.
    var editingMode: EditingMode = .writing

    // MARK: - Line Number Drawing

    private static let lineNumberFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    private static let lineNumberBoldFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)

    // MARK: - XML Fold State

    /// Tag offsets currently collapsed (mirrors Coordinator's state for drawing).
    var xmlCollapsedOffsets: Set<Int> = []

    /// Called when the user clicks a disclosure triangle to toggle collapse.
    var onXMLCollapseToggle: ((Int) -> Void)?

    // MARK: - Word-Boundary Undo Breaks

    /// Tracks whether the last inserted character was whitespace, for word-boundary detection.
    private var lastCharWasWhitespace: Bool = true

    override func insertText(_ string: Any, replacementRange: NSRange) {
        guard let text = string as? String else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }

        // Multi-character inserts (paste) always break before
        if text.count > 1 {
            breakUndoCoalescing()
            super.insertText(string, replacementRange: replacementRange)
            lastCharWasWhitespace = text.last?.isWhitespace ?? false
            return
        }

        let isWhitespace = text.first?.isWhitespace ?? false

        // Break at word boundaries: whitespace→non-whitespace or non-whitespace→whitespace
        if isWhitespace != lastCharWasWhitespace {
            breakUndoCoalescing()
        }

        lastCharWasWhitespace = isWhitespace
        super.insertText(string, replacementRange: replacementRange)
    }

    // MARK: - Tab / Enter Overrides

    override func insertTab(_ sender: Any?) {
        let sel = selectedRange()
        // Multi-line selection → indent all lines
        if sel.length > 0,
           let storage = textStorage,
           (storage.string as NSString).substring(with: sel).contains("\n") {
            formattingDelegate?.indentSelectedLines()
            return
        }
        // Single line: indent if on a list line or cursor is in leading whitespace
        if formattingDelegate?.shouldIndentCurrentLine() == true {
            formattingDelegate?.indentSelectedLines()
            return
        }
        // Default: insert 4 spaces
        insertText("    ", replacementRange: selectedRange())
    }

    override func insertBacktab(_ sender: Any?) {
        formattingDelegate?.dedentSelectedLines()
    }

    override func insertNewline(_ sender: Any?) {
        if formattingDelegate?.handleSmartEnter() == true { return }
        super.insertNewline(sender)
        let theme = Theme.current
        typingAttributes[.font] = theme.editorFont
        typingAttributes[.foregroundColor] = theme.editorForeground
        let baseParagraph = NSMutableParagraphStyle()
        baseParagraph.lineSpacing = theme.lineSpacing
        typingAttributes[.paragraphStyle] = baseParagraph
    }

    // MARK: - Option+Arrow Line Operations

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasOption = flags.contains(.option)
        let hasShift = flags.contains(.shift)

        if hasOption && !flags.contains(.command) {
            switch event.keyCode {
            case 126: // ↑
                if hasShift {
                    formattingDelegate?.duplicateLineUp()
                } else {
                    formattingDelegate?.moveLineUp()
                }
                return
            case 125: // ↓
                if hasShift {
                    formattingDelegate?.duplicateLineDown()
                } else {
                    formattingDelegate?.moveLineDown()
                }
                return
            default:
                break
            }
        }

        super.keyDown(with: event)
    }

    // MARK: - Keyboard Shortcuts

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }

        let shift = event.modifierFlags.contains(.shift)
        let option = event.modifierFlags.contains(.option)
        let chars = event.charactersIgnoringModifiers ?? ""

        // Cmd+Option shortcuts (block formatting)
        if option && !shift {
            switch chars {
            case "c":
                formattingDelegate?.insertFormatting(prefix: "```\n", suffix: "\n```")
                return true
            case "q":
                formattingDelegate?.insertLinePrefix("> ")
                return true
            case "u":
                formattingDelegate?.insertLinePrefix("- ")
                return true
            case "o":
                formattingDelegate?.insertLinePrefix("1. ")
                return true
            case "t":
                formattingDelegate?.insertBlock("| Column 1 | Column 2 | Column 3 |\n| --- | --- | --- |\n| Cell | Cell | Cell |\n")
                return true
            default:
                break
            }
        }

        switch (chars, shift) {
        // Cmd+Shift+K → delete line
        case ("k", true):
            formattingDelegate?.deleteCurrentLine()
            return true
        // Cmd+Enter → blank line below
        case ("\r", false):
            formattingDelegate?.insertBlankLineBelow()
            return true
        // Cmd+Shift+Enter → blank line above
        case ("\r", true):
            formattingDelegate?.insertBlankLineAbove()
            return true
        // Cmd+] → indent
        case ("]", false) where !option:
            formattingDelegate?.indentSelectedLines()
            return true
        // Cmd+[ → dedent
        case ("[", false) where !option:
            formattingDelegate?.dedentSelectedLines()
            return true
        // Inline formatting
        case ("b", false):
            formattingDelegate?.insertFormatting(prefix: "**", suffix: "**")
            return true
        case ("i", false):
            formattingDelegate?.insertFormatting(prefix: "*", suffix: "*")
            return true
        case ("e", false):
            formattingDelegate?.insertFormatting(prefix: "`", suffix: "`")
            return true
        case ("k", false):
            formattingDelegate?.insertFormatting(prefix: "[", suffix: "](url)")
            return true
        case ("x", true):
            formattingDelegate?.insertFormatting(prefix: "~~", suffix: "~~")
            return true
        // Headings Cmd+1 through Cmd+6
        case ("1", false):
            formattingDelegate?.insertLinePrefix("# ")
            return true
        case ("2", false):
            formattingDelegate?.insertLinePrefix("## ")
            return true
        case ("3", false):
            formattingDelegate?.insertLinePrefix("### ")
            return true
        case ("4", false):
            formattingDelegate?.insertLinePrefix("#### ")
            return true
        case ("5", false):
            formattingDelegate?.insertLinePrefix("##### ")
            return true
        case ("6", false):
            formattingDelegate?.insertLinePrefix("###### ")
            return true
        // Cmd+0 → clear heading prefix
        case ("0", false):
            formattingDelegate?.clearLinePrefix()
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }

    // MARK: - Mouse Handling

    override func mouseDown(with event: NSEvent) {
        if handleXMLFoldClick(event) { return }
        super.mouseDown(with: event)
    }

    private func handleXMLFoldClick(_ event: NSEvent) -> Bool {
        guard let textStorage, let layoutManager, let textContainer else { return false }
        guard textStorage.length > 0 else { return false }

        let point = convert(event.locationInWindow, from: nil)

        // Only handle clicks in the left margin area (where triangles are drawn)
        guard point.x < textContainerInset.width + 5 else { return false }

        // Convert to text container coordinates
        let textPoint = NSPoint(x: 0, y: point.y - textContainerInset.height)
        let glyphIndex = layoutManager.glyphIndex(for: textPoint, in: textContainer, fractionOfDistanceThroughGlyph: nil)
        let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)

        // Check if the line at this position has an xmlTagFoldable attribute
        let nsString = textStorage.string as NSString
        guard charIndex < nsString.length else { return false }
        let lineRange = nsString.lineRange(for: NSRange(location: charIndex, length: 0))

        var found = false
        textStorage.enumerateAttribute(.xmlTagFoldable, in: lineRange) { value, _, stop in
            if let foldInfo = value as? [String: Any],
               let tagOffset = foldInfo["offset"] as? Int {
                onXMLCollapseToggle?(tagOffset)
                found = true
                stop.pointee = true
            }
        }
        return found
    }

    // MARK: - Background Drawing

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        drawCodeBlockCards()
        drawXMLFoldTriangles()
        if showLineNumbers { drawLineNumbers(in: rect) }
    }

    private func drawCodeBlockCards() {
        guard let layoutManager, let textContainer, let textStorage else { return }
        guard textStorage.length > 0 else { return }

        let theme = Theme.current

        textStorage.enumerateAttribute(
            .codeBlockBackground,
            in: NSRange(location: 0, length: textStorage.length)
        ) { value, range, _ in
            guard value != nil else { return }

            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: range,
                actualCharacterRange: nil
            )
            guard glyphRange.length > 0 else { return }

            var blockRect = layoutManager.boundingRect(
                forGlyphRange: glyphRange,
                in: textContainer
            )

            // Make the card full-width with inset, offset by text container origin
            let cardPadTop: CGFloat = editingMode == .writing ? 12 : 4
            let cardPadBottom: CGFloat = editingMode == .writing ? 4 : 4
            blockRect.origin.x = textContainerInset.width + 4
            blockRect.origin.y += textContainerInset.height - cardPadTop
            blockRect.size.width = bounds.width - (textContainerInset.width + 4) * 2
            blockRect.size.height += cardPadTop + cardPadBottom

            let path = NSBezierPath(roundedRect: blockRect, xRadius: 8, yRadius: 8)
            theme.codeBackground.setFill()
            path.fill()
        }
    }

    // MARK: - XML Fold Triangles

    private func drawXMLFoldTriangles() {
        guard let layoutManager, let textContainer, let textStorage else { return }
        guard textStorage.length > 0 else { return }

        textStorage.enumerateAttribute(
            .xmlTagFoldable,
            in: NSRange(location: 0, length: textStorage.length)
        ) { value, range, _ in
            guard let foldInfo = value as? [String: Any],
                  let tagOffset = foldInfo["offset"] as? Int else { return }
            let triangleColor = (foldInfo["color"] as? NSColor) ?? .secondaryLabelColor

            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: range,
                actualCharacterRange: nil
            )
            guard glyphRange.length > 0 else { return }

            // Use lineFragmentUsedRect for tighter vertical centering (excludes paragraph spacing)
            var lineRect = layoutManager.lineFragmentUsedRect(
                forGlyphAt: glyphRange.location,
                effectiveRange: nil
            )
            lineRect.origin.y += self.textContainerInset.height

            let isCollapsed = self.xmlCollapsedOffsets.contains(tagOffset)

            // Draw accordion chevron in the left margin
            let chevronSize: CGFloat = 6
            let chevronX: CGFloat = self.textContainerInset.width - 16
            let chevronCenterY = lineRect.origin.y + lineRect.height / 2

            let path = NSBezierPath()
            if isCollapsed {
                // › right-pointing chevron
                path.move(to: NSPoint(x: chevronX, y: chevronCenterY - chevronSize / 2))
                path.line(to: NSPoint(x: chevronX + chevronSize / 2, y: chevronCenterY))
                path.line(to: NSPoint(x: chevronX, y: chevronCenterY + chevronSize / 2))
            } else {
                // ˬ down-pointing chevron
                path.move(to: NSPoint(x: chevronX - chevronSize / 4, y: chevronCenterY - chevronSize / 4))
                path.line(to: NSPoint(x: chevronX + chevronSize / 4, y: chevronCenterY + chevronSize / 4))
                path.line(to: NSPoint(x: chevronX + chevronSize * 3 / 4, y: chevronCenterY - chevronSize / 4))
            }

            path.lineWidth = 1.5
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            triangleColor.setStroke()
            path.stroke()
        }
    }

    // MARK: - Line Numbers

    private func drawLineNumbers(in rect: NSRect) {
        guard let layoutManager, let textContainer, let textStorage else { return }

        let theme = Theme.current
        let text = textStorage.string as NSString
        let insetY = textContainerInset.height
        let cursorLine = currentLineNumber(text: text)

        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: Self.lineNumberFont,
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]
        let currentAttrs: [NSAttributedString.Key: Any] = [
            .font: Self.lineNumberBoldFont,
            .foregroundColor: theme.editorForeground,
        ]

        // Empty document — just draw "1"
        guard text.length > 0 else {
            let fallbackHeight = layoutManager.defaultLineHeight(for: font ?? NSFont.systemFont(ofSize: 15))
            drawNumber(1, at: insetY, lineHeight: fallbackHeight, attrs: currentAttrs)
            return
        }

        // Force layout for the visible range to prevent stale rects from non-contiguous layout
        let visibleGlyphRange = layoutManager.glyphRange(
            forBoundingRect: NSRect(x: 0, y: rect.origin.y - insetY,
                                    width: textContainer.containerSize.width,
                                    height: rect.height),
            in: textContainer
        )
        if visibleGlyphRange.length > 0 {
            layoutManager.ensureLayout(forCharacterRange:
                layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil))
        }

        var charIndex = 0
        var lineNum = 1

        while charIndex < text.length {
            let lineRange = text.lineRange(for: NSRange(location: charIndex, length: 0))

            let glyphIndex = layoutManager.glyphIndexForCharacter(at: lineRange.location)
            let usedRect = layoutManager.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            let lineY = usedRect.origin.y + insetY

            // Past visible area — stop
            if lineY > rect.maxY + 20 { break }

            // Within visible area — draw
            if lineY + usedRect.height >= rect.origin.y {
                let attrs = lineNum == cursorLine ? currentAttrs : normalAttrs
                let lineFont = textStorage.attribute(.font, at: lineRange.location, effectiveRange: nil) as? NSFont ?? theme.editorFont
                let textHeight = layoutManager.defaultLineHeight(for: lineFont)
                drawNumber(lineNum, at: lineY, lineHeight: textHeight, attrs: attrs)
            }

            lineNum += 1
            let next = NSMaxRange(lineRange)
            if next <= charIndex { break }
            charIndex = next
        }

        // Trailing newline means one extra empty line
        if text.length > 0, text.character(at: text.length - 1) == 0x0A {
            let extraUsedRect = layoutManager.extraLineFragmentUsedRect
            if extraUsedRect.height > 0 {
                let y = extraUsedRect.origin.y + insetY
                if y >= rect.origin.y && y <= rect.maxY + 20 {
                    let attrs = lineNum == cursorLine ? currentAttrs : normalAttrs
                    let textHeight = layoutManager.defaultLineHeight(for: theme.editorFont)
                    drawNumber(lineNum, at: y, lineHeight: textHeight, attrs: attrs)
                }
            }
        }

        // Vertical separator line between gutter and content
        let separatorX = textContainerInset.width - 4
        let separatorPath = NSBezierPath()
        separatorPath.move(to: NSPoint(x: separatorX, y: rect.minY))
        separatorPath.line(to: NSPoint(x: separatorX, y: rect.maxY))
        separatorPath.lineWidth = 0.5
        NSColor.separatorColor.withAlphaComponent(0.15).setStroke()
        separatorPath.stroke()
    }

    private func drawNumber(_ number: Int, at y: CGFloat, lineHeight: CGFloat,
                            attrs: [NSAttributedString.Key: Any]) {
        let str = NSAttributedString(string: "\(number)", attributes: attrs)
        let size = str.size()
        // Right-align numbers against the left edge of the text container
        str.draw(at: NSPoint(
            x: textContainerInset.width - size.width - 8,
            y: y + (lineHeight - size.height) / 2
        ))
    }

    private func currentLineNumber(text: NSString) -> Int {
        let pos = min(selectedRange().location, text.length)
        guard pos > 0, text.length > 0 else { return 1 }
        var count = 1
        for i in 0..<pos {
            if text.character(at: i) == 0x0A { count += 1 }
        }
        return count
    }

    // MARK: - Copy Buttons

    func updateCopyButtons() {
        // Defer to next run loop iteration so text appears first, then buttons are positioned
        DispatchQueue.main.async { [weak self] in
            self?.rebuildCopyButtons()
        }
    }

    private func rebuildCopyButtons() {
        copyButtons.forEach { $0.removeFromSuperview() }
        copyButtons.removeAll()

        guard let layoutManager, let textContainer, let textStorage else { return }
        guard textStorage.length > 0 else { return }

        var blockIndex = 0
        textStorage.enumerateAttribute(
            .codeBlockBackground,
            in: NSRange(location: 0, length: textStorage.length)
        ) { value, range, _ in
            guard value != nil else { return }

            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: range,
                actualCharacterRange: nil
            )
            guard glyphRange.length > 0 else { return }

            let blockRect = layoutManager.boundingRect(
                forGlyphRange: glyphRange,
                in: textContainer
            )

            let button = NSButton()
            button.image = NSImage(
                systemSymbolName: "doc.on.doc",
                accessibilityDescription: "Copy code"
            )
            button.bezelStyle = .inline
            button.isBordered = false
            button.contentTintColor = .tertiaryLabelColor
            button.imageScaling = .scaleProportionallyDown
            button.tag = blockIndex
            button.target = self
            button.action = #selector(copyCodeBlock(_:))

            let buttonSize: CGFloat = 22
            let cardPadTop: CGFloat = self.editingMode == .writing ? 12 : 4
            button.frame = NSRect(
                x: self.bounds.width - self.textContainerInset.width - buttonSize - 12,
                y: blockRect.origin.y + self.textContainerInset.height - cardPadTop + 4,
                width: buttonSize,
                height: buttonSize
            )

            self.addSubview(button)
            self.copyButtons.append(button)
            blockIndex += 1
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        repositionCopyButtons()
    }

    private func repositionCopyButtons() {
        guard let layoutManager, let textContainer, let textStorage else { return }
        guard textStorage.length > 0 else { return }

        var index = 0
        textStorage.enumerateAttribute(
            .codeBlockBackground,
            in: NSRange(location: 0, length: textStorage.length)
        ) { value, range, _ in
            guard value != nil, index < self.copyButtons.count else { return }

            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: range,
                actualCharacterRange: nil
            )
            guard glyphRange.length > 0 else { return }

            let blockRect = layoutManager.boundingRect(
                forGlyphRange: glyphRange,
                in: textContainer
            )

            let buttonSize: CGFloat = 22
            let cardPadTop: CGFloat = self.editingMode == .writing ? 12 : 4
            self.copyButtons[index].frame = NSRect(
                x: self.bounds.width - self.textContainerInset.width - buttonSize - 12,
                y: blockRect.origin.y + self.textContainerInset.height - cardPadTop + 4,
                width: buttonSize,
                height: buttonSize
            )
            index += 1
        }
    }

    @objc private func copyCodeBlock(_ sender: NSButton) {
        guard let textStorage else { return }

        var blockIndex = 0
        textStorage.enumerateAttribute(
            .codeBlockBackground,
            in: NSRange(location: 0, length: textStorage.length)
        ) { value, range, stop in
            guard value != nil else { return }

            if blockIndex == sender.tag {
                let fullText = (textStorage.string as NSString).substring(with: range)
                // Strip fence lines — first and last lines if they start with ```
                var lines = fullText.components(separatedBy: "\n")
                if let first = lines.first, first.hasPrefix("```") { lines.removeFirst() }
                if let last = lines.last, last.hasPrefix("```") { lines.removeLast() }
                if lines.last?.isEmpty == true { lines.removeLast() }
                let code = lines.joined(separator: "\n")

                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)

                // Brief visual feedback — tint the button
                sender.contentTintColor = .systemGreen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    sender.contentTintColor = .tertiaryLabelColor
                }

                stop.pointee = true
            }
            blockIndex += 1
        }
    }
}
