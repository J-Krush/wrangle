import Foundation

struct ChangelogCTA {
    let label: String
    let url: URL
}

struct ChangelogEntry {
    let version: String
    let date: String
    let sections: [ChangelogSection]
    let cta: ChangelogCTA?
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
    /// Top entry version MUST equal `Bundle.main.CFBundleShortVersionString`
    /// (i.e. `MARKETING_VERSION` in `Wrangle.xcodeproj/project.pbxproj`).
    /// When this drifts, dismiss() writes the wrong sentinel and v1.N → v1.N+1
    /// upgraders silently never see the new modal. The DEBUG assertion below
    /// fail-fasts on first access so release prep can't ship out of sync.
    /// See docs/release-checklist.md.
    static let entries: [ChangelogEntry] = {
        let list: [ChangelogEntry] = changelog
        #if DEBUG
        assertTopEntryMatchesBundle(list)
        #endif
        return list
    }()

    private static let changelog: [ChangelogEntry] = [
        ChangelogEntry(
            version: "1.3.0",
            date: "May 19, 2026",
            sections: [
                ChangelogSection(category: .new, items: [
                    "Wrangle is now free and open source.",
                ]),
            ],
            cta: ChangelogCTA(
                label: "Star on GitHub",
                url: URL(string: "https://github.com/J-Krush/wrangle")!
            )
        ),
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
            ],
            cta: nil
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
            ],
            cta: nil
        ),
    ]

    #if DEBUG
    private static func assertTopEntryMatchesBundle(_ list: [ChangelogEntry]) {
        let topEntry = list.first?.version ?? "<empty>"
        guard let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return
        }
        assert(
            topEntry == bundleVersion,
            "WhatsNewChangelog top entry version '\(topEntry)' must match bundle MARKETING_VERSION '\(bundleVersion)'. " +
            "When adding a ChangelogEntry, bump MARKETING_VERSION (and CURRENT_PROJECT_VERSION) in Wrangle.xcodeproj/project.pbxproj for BOTH Debug and Release configs. " +
            "Or when bumping the bundle version, add a matching top entry here. See docs/release-checklist.md."
        )
    }
    #endif
}
