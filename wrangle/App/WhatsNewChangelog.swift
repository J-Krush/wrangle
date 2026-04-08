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
            version: "1.1.0",
            date: "April 8, 2026",
            sections: [
                ChangelogSection(category: .new, items: [
                    "Projects — organize locations, terminals, and browsers (soon!) under named projects",
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
