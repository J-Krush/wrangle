import Foundation

struct ChangelogEntry {
    let version: String
    let date: String
    let sections: [ChangelogSection]
}

struct ChangelogSection {
    let category: ChangeCategory
    let items: [String]
}

enum ChangeCategory: String {
    case new = "New"
    case improved = "Improved"
    case fixed = "Fixed"
}

enum WhatsNewChangelog {
    static let entries: [ChangelogEntry] = [
        ChangelogEntry(
            version: "1.2.0",
            date: "April 21, 2026",
            sections: [
                ChangelogSection(category: .new, items: [
                    "Embedded browsers - full browser tabs alongside your editor and terminal, with find-in-page, HTTPS padlock, and dev tools (console, network, elements, and cookies panels)",
                    "Bookmarks - star button, nested folders with drag-and-drop, and one-click import from Safari, Brave, Chrome, and Firefox",
                    "Browsing history - auto-recorded with grouped view, URL suggestions, and clear all button",
                    "Downloads and Private mode — progress popover with cancel/persistence, plus an incognito data store",
                ]),
                ChangelogSection(category: .improved, items: [
                    "Unified Add menu - one shared creation flow across the sidebar, tab strip, and project overview",
                    "Sidebar organization and cleanup",
                    "Project overview section organization"
                ]),
                ChangelogSection(category: .fixed, items: [
                    "Keyboard shortcut consistency",
                    "Make hyperlinks clickable in Claude sessions",
                    "Trash failures no longer silently hard-delete items",
                    "Resize handlers no longer flicker"
                ]),
            ]
        ),
        ChangelogEntry(
            version: "1.1.1",
            date: "April 8, 2026",
            sections: [
                ChangelogSection(category: .new, items: [
                    "Projects — organize File Locations, terminals, and browsers (soon!) under named projects",
                    "Project dashboard with overview stats and quick actions",
                    "Small todo list at the project level for keeping track of small tasks",
                    "Canvas view for visual workspace layout",
                    "Back/forward navigation between views",
                ]),
                ChangelogSection(category: .improved, items: [
                    "System metrics display in the title bar (turn on in settings)",
                    "Sidebar redesigned with project rail for fast switching",
                    "File tree UI tightening",
                ]),
                ChangelogSection(category: .fixed, items: [
                    "Keyboard shortcuts are now consistent across all views",
                    "Embedded terminal: text overlapping and highlighting issues fixed",
                ]),
            ]
        ),
    ]
}
