//
//  wrangleApp.swift
//  wrangle
//
//  Created by John Kreisher on 2/21/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UserNotifications

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var appState: AppState?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let sessionID = userInfo["sessionID"] as? String {
            Task { @MainActor in
                appState?.claudeHookService?.handleNotificationTap(sessionID: sessionID)
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even when app is foreground (service already filtered)
        completionHandler([.banner, .sound])
    }
}

@main
struct wrangleApp: App {
    @State private var appState = AppState()
    @State private var resolvedSystemScheme: ColorScheme = {
        guard let app = NSApp else { return .dark }
        return app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
    }()
    private let notificationDelegate = NotificationDelegate()

    private var effectiveColorScheme: ColorScheme {
        switch appState.appearanceMode {
        case .system: resolvedSystemScheme
        case .light:  .light
        case .dark:   .dark
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BookmarkedDirectory.self,
            RecentFile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Store is corrupted or schema changed — delete and recreate
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-shm", "-wal"] {
                let fileURL = storeURL.deletingLastPathComponent().appending(path: "default.store\(suffix)")
                try? FileManager.default.removeItem(at: fileURL)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(effectiveColorScheme)
                .onAppear {
                    setupNotifications()
                    setupForegroundTracking()
                    updateSystemScheme()
                    // Listen for macOS appearance changes
                    DistributedNotificationCenter.default().addObserver(
                        forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
                        object: nil,
                        queue: .main
                    ) { _ in
                        // Small delay for AppKit to settle
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(100))
                            updateSystemScheme()
                        }
                    }
                }
                .onChange(of: appState.appearanceMode) { _, mode in
                    switch mode {
                    case .system: NSApp.appearance = nil
                    case .light:  NSApp.appearance = NSAppearance(named: .aqua)
                    case .dark:   NSApp.appearance = NSAppearance(named: .darkAqua)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New File") {
                    appState.newDocument()
                }
                .keyboardShortcut("n")

                Button("New Terminal") {
                    appState.openTerminal(
                        projectName: appState.activeProjectName ?? "Terminal",
                        directory: activeProjectDirectory(),
                        bookmarkID: appState.selectedBookmarkID
                    )
                }
                .keyboardShortcut("`", modifiers: .command)

                Divider()

                Button("Open...") {
                    openFile()
                }
                .keyboardShortcut("o")

                Menu("Open Recent") {
                    let context = sharedModelContainer.mainContext
                    let descriptor = FetchDescriptor<RecentFile>(
                        sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
                    )
                    if let recents = try? context.fetch(descriptor) {
                        ForEach(Array(recents.prefix(20)), id: \.urlString) { recentFile in
                            if let url = recentFile.url {
                                Button(url.lastPathComponent) {
                                    appState.openFile(url: url)
                                }
                            }
                        }
                        if !recents.isEmpty {
                            Divider()
                            Button("Clear Menu") {
                                for file in recents {
                                    context.delete(file)
                                }
                                try? context.save()
                            }
                        }
                    }
                }

                Divider()

                Button("Save") {
                    saveFile()
                }
                .keyboardShortcut("s")

                Button("Save As...") {
                    saveFileAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar") {
                    withAnimation {
                        appState.sidebarWidth = appState.sidebarWidth > 0 ? 0 : 240
                    }
                }
                .keyboardShortcut("\\", modifiers: [.command])
            }

            // Edit menu additions
            CommandGroup(after: .textEditing) {
                Divider()

                Button("Find in Files") {
                    appState.showGlobalSearch.toggle()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }

            // View menu — terminal commands
            CommandGroup(after: .toolbar) {
                Button("New Claude Code Session") {
                    appState.openTerminal(
                        projectName: appState.activeProjectName ?? "Claude Code",
                        directory: activeProjectDirectory(),
                        bookmarkID: appState.selectedBookmarkID,
                        launchClaude: true
                    )
                }
                .keyboardShortcut("`", modifiers: [.command, .shift])

                Button("New Gemini Code Session") {
                    appState.openTerminal(
                        projectName: appState.activeProjectName ?? "Gemini Code",
                        directory: activeProjectDirectory(),
                        bookmarkID: appState.selectedBookmarkID,
                        launchGemini: true
                    )
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Divider()

                Button("Quick Open") {
                    appState.showFuzzyFinder.toggle()
                }
                .keyboardShortcut("p", modifiers: .command)
            }

            // Open in external editor
            CommandGroup(after: .toolbar) {
                Divider()
                Menu("Open in External Editor") {
                    ForEach(ExternalEditorLauncher.availableEditors()) { editor in
                        Button("Open in \(editor.name)") {
                            openInExternalEditor(bundleID: editor.bundleID)
                        }
                    }
                    Divider()
                    Button("Reveal in Finder") {
                        revealInFinder()
                    }
                }
            }

            // Tab navigation
            CommandGroup(after: .windowArrangement) {
                Button("Next Tab") {
                    if appState.activeTabIndex < appState.tabs.count - 1 {
                        appState.selectTab(at: appState.activeTabIndex + 1)
                    }
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Previous Tab") {
                    if appState.activeTabIndex > 0 {
                        appState.selectTab(at: appState.activeTabIndex - 1)
                    }
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Button("Close Tab") {
                    appState.requestCloseTab(at: appState.activeTabIndex)
                }
                .keyboardShortcut("w")
            }
        }
    }

    private func activeProjectDirectory() -> URL? {
        // Try to derive directory from the active document or selected bookmark
        if let url = appState.activeDocument?.fileURL {
            return url.deletingLastPathComponent()
        }
        return nil
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .plainText, .yaml, .json,
            .xml, .html,
            .sourceCode, .swiftSource,
            .shellScript, .pythonScript, .perlScript, .rubyScript,
            .cSource, .cPlusPlusSource, .cHeader, .cPlusPlusHeader,
            .objectiveCSource, .objectiveCPlusPlusSource,
        ]
        panel.allowsOtherFileTypes = true
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Select files to open"

        if panel.runModal() == .OK {
            for url in panel.urls {
                appState.openFile(url: url, scopedURL: url)
            }
        }
    }

    private func saveFile() {
        guard let doc = appState.activeDocument else { return }
        appState.promotePreviewTab(for: doc.id)

        if doc.fileURL != nil {
            try? doc.save()
        } else {
            showSavePanel(for: doc)
        }
    }

    private func saveFileAs() {
        guard let doc = appState.activeDocument else { return }
        showSavePanel(for: doc)
    }

    private func showSavePanel(for doc: EditorDocument) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = doc.fileName
        panel.message = "Save file as"

        if panel.runModal() == .OK, let url = panel.url {
            try? doc.saveAs(to: url)
        }
    }

    private func openInExternalEditor(bundleID: String) {
        if let url = appState.activeDocument?.fileURL?.deletingLastPathComponent() {
            ExternalEditorLauncher.open(directory: url, withBundleID: bundleID)
        }
    }

    private func revealInFinder() {
        if let url = appState.activeDocument?.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    // MARK: - System Appearance Tracking

    private func updateSystemScheme() {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        resolvedSystemScheme = isDark ? .dark : .light
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        notificationDelegate.appState = appState
        center.delegate = notificationDelegate

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("[Wrangle] Notification auth error: \(error)")
            }
        }

        // Register notification category
        let category = UNNotificationCategory(
            identifier: "CLAUDE_HOOK_EVENT",
            actions: [],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])

        // Start the hook service
        appState.claudeHookService = ClaudeHookService(appState: appState)

        // Install hooks if needed (one-time, non-blocking)
        ClaudeHookService.setupHooksIfNeeded()
    }

    private func setupForegroundTracking() {
        let state = appState
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in state.isAppForeground = true }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in state.isAppForeground = false }
        }
    }
}
