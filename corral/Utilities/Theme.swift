import AppKit
import SwiftUI

struct Theme {
    // MARK: - Colors

    var editorBackground: NSColor

    /// SwiftUI-compatible version of the editor background color.
    var editorBackgroundColor: Color { Color(nsColor: editorBackground) }
    var editorForeground: NSColor
    var sidebarBackground: NSColor
    var headingColor: NSColor
    var codeBackground: NSColor
    var codeForeground: NSColor
    var linkColor: NSColor
    var blockquoteBorder: NSColor
    var blockquoteText: NSColor
    var selectionColor: NSColor
    var xmlTagColors: [String: NSColor]

    // MARK: - Terminal Colors

    var terminalBackground: NSColor
    var terminalForeground: NSColor
    var terminalCursor: NSColor
    var terminalSelection: NSColor
    var terminalFont: NSFont

    /// 16 ANSI colors: [black, red, green, yellow, blue, magenta, cyan, white,
    ///                   brightBlack, brightRed, brightGreen, brightYellow,
    ///                   brightBlue, brightMagenta, brightCyan, brightWhite]
    var terminalAnsiColors: [NSColor]

    // MARK: - Fonts

    var editorFont: NSFont
    var codeFont: NSFont

    // MARK: - Spacing

    var lineSpacing: CGFloat
    var paragraphSpacing: CGFloat

    // MARK: - Heading Fonts

    /// Returns an appropriately sized bold font for the given heading level (1-6).
    func headingFont(level: Int) -> NSFont {
        let size: CGFloat
        switch level {
        case 1: size = 28
        case 2: size = 24
        case 3: size = 20
        case 4: size = 18
        case 5: size = 16
        case 6: size = 14
        default: size = 14
        }
        return NSFont.boldSystemFont(ofSize: size)
    }

    // MARK: - Preconfigured Themes

    private static let monoFont: NSFont = NSFont(name: "SF Mono", size: 13)
        ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    static let light = Theme(
        editorBackground: NSColor(white: 1.0, alpha: 1.0),
        editorForeground: NSColor(white: 0.1, alpha: 1.0),
        sidebarBackground: NSColor(white: 0.96, alpha: 1.0),
        headingColor: NSColor(white: 0.0, alpha: 1.0),
        codeBackground: NSColor(white: 0.94, alpha: 1.0),
        codeForeground: NSColor(red: 0.84, green: 0.19, blue: 0.21, alpha: 1.0),
        linkColor: NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),
        blockquoteBorder: NSColor(white: 0.78, alpha: 1.0),
        blockquoteText: NSColor(white: 0.4, alpha: 1.0),
        selectionColor: NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.2),
        xmlTagColors: defaultXMLTagColors(dark: false),
        // Terminal — warm off-white with high-contrast text
        terminalBackground: NSColor(red: 0.98, green: 0.98, blue: 0.96, alpha: 1.0),  // #fafaf5
        terminalForeground: NSColor(red: 0.22, green: 0.38, blue: 0.75, alpha: 1.0),  // #3760bf
        terminalCursor: NSColor(red: 0.22, green: 0.38, blue: 0.75, alpha: 1.0),
        terminalSelection: NSColor(red: 0.71, green: 0.75, blue: 0.89, alpha: 0.5),   // #b6bfe2
        terminalFont: monoFont,
        terminalAnsiColors: lightAnsiColors(),
        editorFont: NSFont.systemFont(ofSize: 15),
        codeFont: monoFont,
        lineSpacing: 4,
        paragraphSpacing: 8
    )

    static let dark = Theme(
        editorBackground: NSColor(white: 0.12, alpha: 1.0),
        editorForeground: NSColor(white: 0.9, alpha: 1.0),
        sidebarBackground: NSColor(white: 0.1, alpha: 1.0),
        headingColor: NSColor(white: 1.0, alpha: 1.0),
        codeBackground: NSColor(white: 0.18, alpha: 1.0),
        codeForeground: NSColor(red: 0.99, green: 0.42, blue: 0.42, alpha: 1.0),
        linkColor: NSColor(red: 0.35, green: 0.68, blue: 1.0, alpha: 1.0),
        blockquoteBorder: NSColor(white: 0.35, alpha: 1.0),
        blockquoteText: NSColor(white: 0.6, alpha: 1.0),
        selectionColor: NSColor(red: 0.35, green: 0.68, blue: 1.0, alpha: 0.3),
        xmlTagColors: defaultXMLTagColors(dark: true),
        // Terminal — Tokyo Night-inspired muted professional palette
        terminalBackground: NSColor(red: 0.10, green: 0.11, blue: 0.15, alpha: 1.0),  // #1a1b26
        terminalForeground: NSColor(red: 0.66, green: 0.69, blue: 0.84, alpha: 1.0),  // #a9b1d6
        terminalCursor: NSColor(red: 0.75, green: 0.79, blue: 0.96, alpha: 1.0),       // #c0caf5
        terminalSelection: NSColor(red: 0.20, green: 0.27, blue: 0.49, alpha: 0.6),    // #33467c
        terminalFont: monoFont,
        terminalAnsiColors: darkAnsiColors(),
        editorFont: NSFont.systemFont(ofSize: 15),
        codeFont: monoFont,
        lineSpacing: 4,
        paragraphSpacing: 8
    )

    /// Shared sidebar selection background used by all sidebar rows.
    static func sidebarSelectionBackground(isSelected: Bool) -> some View {
        Rectangle()
            .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .overlay(
                Rectangle()
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
            )
    }

    /// Returns the appropriate theme based on the current system appearance.
    static var current: Theme {
        let appearance = NSApp.effectiveAppearance
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? .dark : .light
    }

    // MARK: - XML Tag Color Defaults

    private static func defaultXMLTagColors(dark: Bool) -> [String: NSColor] {
        if dark {
            return [
                "instructions": NSColor(red: 0.45, green: 0.65, blue: 1.0, alpha: 1.0),
                "system": NSColor(red: 0.45, green: 0.65, blue: 1.0, alpha: 1.0),
                "tools": NSColor(red: 0.3, green: 0.8, blue: 0.75, alpha: 1.0),
                "tool": NSColor(red: 0.3, green: 0.8, blue: 0.75, alpha: 1.0),
                "examples": NSColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1.0),
                "example": NSColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1.0),
                "artifacts": NSColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1.0),
                "artifact": NSColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1.0),
            ]
        } else {
            return [
                "instructions": NSColor(red: 0.0, green: 0.35, blue: 0.85, alpha: 1.0),
                "system": NSColor(red: 0.0, green: 0.35, blue: 0.85, alpha: 1.0),
                "tools": NSColor(red: 0.0, green: 0.55, blue: 0.55, alpha: 1.0),
                "tool": NSColor(red: 0.0, green: 0.55, blue: 0.55, alpha: 1.0),
                "examples": NSColor(red: 0.45, green: 0.2, blue: 0.8, alpha: 1.0),
                "example": NSColor(red: 0.45, green: 0.2, blue: 0.8, alpha: 1.0),
                "artifacts": NSColor(red: 0.85, green: 0.45, blue: 0.1, alpha: 1.0),
                "artifact": NSColor(red: 0.85, green: 0.45, blue: 0.1, alpha: 1.0),
            ]
        }
    }

    // MARK: - ANSI Color Palettes

    /// Dark theme ANSI colors — Tokyo Night-inspired
    private static func darkAnsiColors() -> [NSColor] {
        [
            // Normal colors
            NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0),  // black   #15161e
            NSColor(red: 0.97, green: 0.47, blue: 0.56, alpha: 1.0),  // red     #f7768e
            NSColor(red: 0.62, green: 0.81, blue: 0.42, alpha: 1.0),  // green   #9ece6a
            NSColor(red: 0.88, green: 0.69, blue: 0.41, alpha: 1.0),  // yellow  #e0af68
            NSColor(red: 0.48, green: 0.64, blue: 0.97, alpha: 1.0),  // blue    #7aa2f7
            NSColor(red: 0.73, green: 0.60, blue: 0.97, alpha: 1.0),  // magenta #bb9af7
            NSColor(red: 0.49, green: 0.81, blue: 1.00, alpha: 1.0),  // cyan    #7dcfff
            NSColor(red: 0.66, green: 0.69, blue: 0.84, alpha: 1.0),  // white   #a9b1d6
            // Bright colors
            NSColor(red: 0.25, green: 0.28, blue: 0.41, alpha: 1.0),  // bright black   #414868
            NSColor(red: 0.97, green: 0.47, blue: 0.56, alpha: 1.0),  // bright red     #f7768e
            NSColor(red: 0.62, green: 0.81, blue: 0.42, alpha: 1.0),  // bright green   #9ece6a
            NSColor(red: 0.88, green: 0.69, blue: 0.41, alpha: 1.0),  // bright yellow  #e0af68
            NSColor(red: 0.48, green: 0.64, blue: 0.97, alpha: 1.0),  // bright blue    #7aa2f7
            NSColor(red: 0.73, green: 0.60, blue: 0.97, alpha: 1.0),  // bright magenta #bb9af7
            NSColor(red: 0.49, green: 0.81, blue: 1.00, alpha: 1.0),  // bright cyan    #7dcfff
            NSColor(red: 0.75, green: 0.79, blue: 0.96, alpha: 1.0),  // bright white   #c0caf5
        ]
    }

    /// Light theme ANSI colors — warm high-contrast
    private static func lightAnsiColors() -> [NSColor] {
        [
            // Normal colors
            NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0),  // black   #0f0f14
            NSColor(red: 0.96, green: 0.16, blue: 0.40, alpha: 1.0),  // red     #f52a65
            NSColor(red: 0.35, green: 0.46, blue: 0.22, alpha: 1.0),  // green   #587539
            NSColor(red: 0.55, green: 0.42, blue: 0.24, alpha: 1.0),  // yellow  #8c6c3e
            NSColor(red: 0.18, green: 0.49, blue: 0.91, alpha: 1.0),  // blue    #2e7de9
            NSColor(red: 0.60, green: 0.33, blue: 0.95, alpha: 1.0),  // magenta #9854f1
            NSColor(red: 0.00, green: 0.44, blue: 0.59, alpha: 1.0),  // cyan    #007197
            NSColor(red: 0.38, green: 0.45, blue: 0.69, alpha: 1.0),  // white   #6172b0
            // Bright colors
            NSColor(red: 0.38, green: 0.45, blue: 0.69, alpha: 1.0),  // bright black   #6172b0
            NSColor(red: 0.96, green: 0.16, blue: 0.40, alpha: 1.0),  // bright red     #f52a65
            NSColor(red: 0.35, green: 0.46, blue: 0.22, alpha: 1.0),  // bright green   #587539
            NSColor(red: 0.55, green: 0.42, blue: 0.24, alpha: 1.0),  // bright yellow  #8c6c3e
            NSColor(red: 0.18, green: 0.49, blue: 0.91, alpha: 1.0),  // bright blue    #2e7de9
            NSColor(red: 0.60, green: 0.33, blue: 0.95, alpha: 1.0),  // bright magenta #9854f1
            NSColor(red: 0.00, green: 0.44, blue: 0.59, alpha: 1.0),  // bright cyan    #007197
            NSColor(red: 0.22, green: 0.38, blue: 0.75, alpha: 1.0),  // bright white   #3760bf
        ]
    }
}
