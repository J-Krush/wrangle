import AppKit

extension NSAttributedString.Key {
    /// Custom attribute marking code block ranges for card-style background drawing.
    static let codeBlockBackground = NSAttributedString.Key("codeBlockBackground")
}

/// Delegate protocol for forwarding keyboard-driven formatting to the coordinator.
protocol EditorTextViewFormattingDelegate: AnyObject {
    func insertFormatting(prefix: String, suffix: String)
    func insertLinePrefix(_ prefix: String)
}

/// Custom NSTextView subclass that draws rounded-rect card backgrounds behind
/// fenced code blocks and manages "copy" button overlays.
class EditorTextView: NSTextView {

    weak var formattingDelegate: EditorTextViewFormattingDelegate?
    private var copyButtons: [NSButton] = []

    // MARK: - Keyboard Shortcuts

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }

        let shift = event.modifierFlags.contains(.shift)
        let chars = event.charactersIgnoringModifiers ?? ""

        switch (chars, shift) {
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
        case ("1", false):
            formattingDelegate?.insertLinePrefix("# ")
            return true
        case ("2", false):
            formattingDelegate?.insertLinePrefix("## ")
            return true
        case ("3", false):
            formattingDelegate?.insertLinePrefix("### ")
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }

    // MARK: - Background Drawing

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        drawCodeBlockCards()
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
            blockRect.origin.x = textContainerInset.width + 4
            blockRect.origin.y += textContainerInset.height - 12
            blockRect.size.width = bounds.width - (textContainerInset.width + 4) * 2
            blockRect.size.height += 24

            let path = NSBezierPath(roundedRect: blockRect, xRadius: 8, yRadius: 8)
            theme.codeBackground.setFill()
            path.fill()
        }
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
            button.frame = NSRect(
                x: self.bounds.width - self.textContainerInset.width - buttonSize - 12,
                y: blockRect.origin.y + self.textContainerInset.height + 2,
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
            self.copyButtons[index].frame = NSRect(
                x: self.bounds.width - self.textContainerInset.width - buttonSize - 12,
                y: blockRect.origin.y + self.textContainerInset.height + 2,
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
