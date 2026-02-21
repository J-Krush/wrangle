import AppKit

struct Theme {
    // MARK: - Colors

    var editorBackground: NSColor
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
        editorFont: NSFont.systemFont(ofSize: 15),
        codeFont: NSFont(name: "SF Mono", size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
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
        editorFont: NSFont.systemFont(ofSize: 15),
        codeFont: NSFont(name: "SF Mono", size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
        lineSpacing: 4,
        paragraphSpacing: 8
    )

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
}
