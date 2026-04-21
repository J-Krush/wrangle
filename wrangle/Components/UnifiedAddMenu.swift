//
//  UnifiedAddMenu.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

/// Shared creation menu presented by every `+` button in app chrome
/// (sidebar bottom bar, Project Overview header, tab strip). The menu content
/// and ordering are identical across all three presenters. See
/// .planning/phases/10-unified-creation-pattern/10-CONTEXT.md §D-02.
struct UnifiedAddMenu: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedDirectory.displayOrder) private var bookmarks: [BookmarkedDirectory]
    @Query(sort: \Project.displayOrder) private var projects: [Project]

    @State private var showTerminalPicker = false
    @State private var showAddBookmarkSheet = false
    @State private var pendingLaunchClaude = false
    @State private var pendingLaunchGemini = false
    @State private var pendingDangerousMode = false

    /// Pre-fill values captured at the moment the user selects "Bookmark…",
    /// taken from the currently-focused browser tab (D-04). Reset on dismiss.
    @State private var bookmarkPrefillURL: String = ""
    @State private var bookmarkPrefillTitle: String = ""

    var body: some View {
        Menu {
            // Group 1 — quick create
            Button {
                appState.newScratchPad()
            } label: {
                Label("Scratch Pad", systemImage: "note.text")
            }
            Button {
                appState.openBrowser()
            } label: {
                Label("Browser", systemImage: "globe")
            }
            Button {
                appState.openBrowser(isPrivate: true)
            } label: {
                Label("Private Browser", systemImage: "lock")
            }
            Button {
                captureBookmarkPrefill()
                showAddBookmarkSheet = true
            } label: {
                Label("Bookmark…", systemImage: "star")
            }

            Divider()

            // Group 2 — terminals (four distinct items per D-02)
            Button {
                presentTerminalPicker(claude: false, gemini: false, dangerous: false)
            } label: {
                Label("Terminal", systemImage: "terminal")
            }
            Button {
                presentTerminalPicker(claude: true, gemini: false, dangerous: false)
            } label: {
                Label("Claude Code", systemImage: "brain.head.profile")
            }
            Button {
                presentTerminalPicker(claude: false, gemini: true, dangerous: false)
            } label: {
                Label("Gemini Code", systemImage: "sparkles")
            }
            Button {
                presentTerminalPicker(claude: true, gemini: false, dangerous: true)
            } label: {
                Label("Claude (Skip Permissions)", systemImage: "exclamationmark.triangle.fill")
            }
            .help("Runs claude --dangerously-skip-permissions")

            Divider()

            // Group 3 — files + folders
            Button {
                appState.newDocument()
            } label: {
                Label("File…", systemImage: "doc.badge.plus")
            }
            Button {
                addLocation()
            } label: {
                Label("File Location…", systemImage: "folder.badge.plus")
            }
            // "Import Bookmarks…" removed from UnifiedAddMenu — now reached
            // exclusively via the Bookmarks popover (book icon) "…" menu.
        } label: {
            // Match sidebar `+` treatment from SidebarView.sidebarBottomBar (D-12).
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Add…")
        .accessibilityLabel("Add")
        .popover(isPresented: $showTerminalPicker, arrowEdge: .bottom) {
            TerminalDirectoryPicker(
                launchClaude: pendingLaunchClaude,
                launchGemini: pendingLaunchGemini,
                projectID: appState.selectedProjectID
            ) { name, url, bookmarkID in
                appState.openTerminal(
                    projectName: name,
                    directory: url,
                    bookmarkID: bookmarkID,
                    launchClaude: pendingLaunchClaude,
                    launchGemini: pendingLaunchGemini,
                    dangerousMode: pendingDangerousMode
                )
            }
        }
        .sheet(isPresented: $showAddBookmarkSheet) {
            NewBookmarkSheet(
                projectID: appState.selectedProjectID,
                prefillURL: bookmarkPrefillURL,
                prefillTitle: bookmarkPrefillTitle
            )
        }
    }

    // MARK: - Helpers

    private func presentTerminalPicker(claude: Bool, gemini: Bool, dangerous: Bool) {
        pendingLaunchClaude = claude
        pendingLaunchGemini = gemini
        pendingDangerousMode = dangerous
        showTerminalPicker = true
    }

    /// D-04: when a browser tab is focused, pre-fill URL+Title from its active tab.
    /// Otherwise leave blank and let the user type.
    private func captureBookmarkPrefill() {
        if let browserTab = appState.activeTab?.browserSession?.activeTab {
            bookmarkPrefillURL = browserTab.url?.absoluteString ?? ""
            bookmarkPrefillTitle = browserTab.title
        } else {
            bookmarkPrefillURL = ""
            bookmarkPrefillTitle = ""
        }
    }

    /// Copied VERBATIM from `Wrangle/Sidebar/SidebarView.swift` lines 368-418.
    /// Handles BOTH the project-selected case AND the no-project case (where it
    /// creates a new Project first and assigns the bookmark to it). Do NOT shortcut
    /// through the AppState pending-location-add path — that handler in
    /// `ContentView.swift:245-249` is gated on `selectedProjectID != nil` and silently
    /// no-ops when no project is selected, which is a regression versus the current
    /// sidebar `+` behavior.
    private func addLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select a file or directory to add as a File Location"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

        do {
            let data = try SecurityScopedBookmark.create(for: url)
            let maxOrder = bookmarks.map(\.displayOrder).max() ?? -1
            let bookmark = BookmarkedDirectory(
                name: url.lastPathComponent,
                bookmarkData: data,
                displayOrder: maxOrder + 1,
                isFile: !isDir
            )
            // If drilled into a project, assign the new bookmark to it.
            // Otherwise create a new project for this bookmark.
            if let projectID = appState.selectedProjectID {
                bookmark.projectID = projectID
            } else {
                let maxProjectOrder = projects.map(\.displayOrder).max() ?? -1
                let project = Project(
                    name: url.lastPathComponent,
                    displayOrder: maxProjectOrder + 1
                )
                modelContext.insert(project)
                bookmark.projectID = project.id
            }
            modelContext.insert(bookmark)
            try? modelContext.save()

            let id = bookmark.persistentModelID.hashValue.description
            if isDir {
                appState.selectedBookmarkID = id
                // Auto-drill into the project if we just created one at the top level
                if appState.selectedProjectID == nil, let projectID = bookmark.projectID {
                    appState.selectedProjectID = projectID
                }
            } else {
                appState.openFile(url: url, scopedURL: url)
            }
        } catch {
            // Bookmark creation failed
        }
    }
}
