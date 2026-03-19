//
//  WrangleApp.swift
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
    weak var coordinator: AppCoordinator?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let sessionID = userInfo["sessionID"] as? String {
            Task { @MainActor in
                coordinator?.claudeHookService?.handleNotificationTap(sessionID: sessionID)
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
struct WrangleApp: App {
    @State private var coordinator = AppCoordinator()
@FocusedValue(\.appState) private var focusedAppState
    @State private var resolvedSystemScheme: ColorScheme = {
        guard let app = NSApp else { return .dark }
        return app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
    }()
    private let notificationDelegate = NotificationDelegate()

    private var effectiveColorScheme: ColorScheme {
        switch coordinator.appearanceMode {
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
        WindowGroup(id: "main") {
            ContentView()
                .environment(coordinator)
                .preferredColorScheme(effectiveColorScheme)
                .onAppear {
                    guard !coordinator.isSetupComplete else { return }
                    coordinator.isSetupComplete = true
                    setupNotifications()
                    setupForegroundTracking()
                    updateSystemScheme()
                    coordinator.updateChecker.checkForUpdate()
                    coordinator.licenseManager.loadOnLaunch()

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
                .onChange(of: coordinator.appearanceMode) { _, mode in
                    switch mode {
                    case .system: NSApp.appearance = nil
                    case .light:  NSApp.appearance = NSAppearance(named: .aqua)
                    case .dark:   NSApp.appearance = NSAppearance(named: .darkAqua)
                    }
                }
                .onOpenURL { url in
                    // Handle files opened from Finder via file type associations
                    if let state = focusedAppState {
                        state.openFile(url: url, scopedURL: url)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Wrangle") {
                    let credits = NSMutableAttributedString()
                    credits.append(NSAttributedString(
                        string: "Made by Krush\n",
                        attributes: [.font: NSFont.systemFont(ofSize: 11)]
                    ))
                    credits.append(NSAttributedString(
                        string: "wrangleapp.dev",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .link: URL(string: "https://wrangleapp.dev")! as Any,
                            .foregroundColor: NSColor.linkColor
                        ]
                    ))
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [
                        .credits: credits,
                    ])
                }

                Divider()

                Button("Check for Updates...") {
                    coordinator.updateChecker.checkForUpdate(manual: true)
                }
            }

            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New File") {
                    focusedAppState?.newDocument()
                }
                .keyboardShortcut("n")
                .disabled(focusedAppState == nil)

                Button("New Scratch Pad") {
                    focusedAppState?.newScratchPad()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(focusedAppState == nil)

                Button("New Terminal") {
                    guard let state = focusedAppState else { return }
                    state.openTerminal(
                        projectName: state.activeProjectName ?? "Terminal",
                        directory: activeProjectDirectory(),
                        bookmarkID: state.selectedBookmarkID
                    )
                }
                .keyboardShortcut("`", modifiers: .command)
                .disabled(focusedAppState == nil)

                Button("New Window") {
                    openNewWindow()
                }
                .keyboardShortcut("n", modifiers: [.command, .option])

                Divider()

                Button("Open...") {
                    openFile()
                }
                .keyboardShortcut("o")
                .disabled(focusedAppState == nil)

                Menu("Open Recent") {
                    let context = sharedModelContainer.mainContext
                    let descriptor = FetchDescriptor<RecentFile>(
                        sortBy: [SortDescriptor(\.lastOpened, order: .reverse)]
                    )
                    if let recents = try? context.fetch(descriptor) {
                        ForEach(Array(recents.prefix(20)), id: \.urlString) { recentFile in
                            if let url = recentFile.url {
                                Button(url.lastPathComponent) {
                                    focusedAppState?.openFile(url: url)
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
                .disabled(focusedAppState == nil)

                Button("Save As...") {
                    saveFileAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(focusedAppState == nil)
            }

            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar") {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(
                        #selector(NSSplitViewController.toggleSidebar(_:)),
                        with: nil
                    )
                }
                .keyboardShortcut("\\", modifiers: [.command])
            }

            // Edit menu additions
            CommandGroup(after: .textEditing) {
                Divider()

                Button("Find in Files") {
                    focusedAppState?.showGlobalSearch.toggle()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(focusedAppState == nil)
            }

            // View menu — terminal commands
            CommandGroup(after: .toolbar) {
                Button("New Claude Code Session") {
                    guard let state = focusedAppState else { return }
                    state.openTerminal(
                        projectName: state.activeProjectName ?? "Claude Code",
                        directory: activeProjectDirectory(),
                        bookmarkID: state.selectedBookmarkID,
                        launchClaude: true
                    )
                }
                .keyboardShortcut("`", modifiers: [.command, .shift])
                .disabled(focusedAppState == nil)

                Button("New Gemini Code Session") {
                    guard let state = focusedAppState else { return }
                    state.openTerminal(
                        projectName: state.activeProjectName ?? "Gemini Code",
                        directory: activeProjectDirectory(),
                        bookmarkID: state.selectedBookmarkID,
                        launchGemini: true
                    )
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(focusedAppState == nil)

                Divider()

                Button("Quick Open") {
                    focusedAppState?.showFuzzyFinder.toggle()
                }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(focusedAppState == nil)
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

            // Help menu
            CommandGroup(replacing: .help) {
                Button("Report Bug...") {
                    FeedbackHelper.openFeedback(.bug)
                }
                Button("Request Feature...") {
                    FeedbackHelper.openFeedback(.feature)
                }
            }

            // Tab navigation
            CommandGroup(after: .windowArrangement) {
                Button("Next Tab") {
                    guard let state = focusedAppState else { return }
                    if state.activeTabIndex < state.tabs.count - 1 {
                        state.selectTab(at: state.activeTabIndex + 1)
                    }
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])
                .disabled(focusedAppState == nil)

                Button("Previous Tab") {
                    guard let state = focusedAppState else { return }
                    if state.activeTabIndex > 0 {
                        state.selectTab(at: state.activeTabIndex - 1)
                    }
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])
                .disabled(focusedAppState == nil)

                Button("Close Tab") {
                    focusedAppState?.requestCloseTab(at: focusedAppState?.activeTabIndex ?? 0)
                }
                .keyboardShortcut("w")
                .disabled(focusedAppState == nil)
            }
        }

        Settings {
            SettingsView()
                .environment(coordinator)
        }
    }

    @Environment(\.openWindow) private var openWindow

    private func openNewWindow() {
        openWindow(id: "main")
    }

    private func activeProjectDirectory() -> URL? {
        guard let state = focusedAppState else { return nil }
        if let url = state.activeDocument?.fileURL {
            return url.deletingLastPathComponent()
        }
        return nil
    }

    private func openFile() {
        guard let state = focusedAppState else { return }
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
                state.openFile(url: url, scopedURL: url)
            }
        }
    }

    private func saveFile() {
        guard let state = focusedAppState,
              let doc = state.activeDocument else { return }
        state.promotePreviewTab(for: doc.id)

        if doc.fileURL != nil {
            try? doc.save()
        } else {
            showSavePanel(for: doc)
        }
    }

    private func saveFileAs() {
        guard let state = focusedAppState,
              let doc = state.activeDocument else { return }
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
        if let url = focusedAppState?.activeDocument?.fileURL?.deletingLastPathComponent() {
            ExternalEditorLauncher.open(directory: url, withBundleID: bundleID)
        }
    }

    private func revealInFinder() {
        if let url = focusedAppState?.activeDocument?.fileURL {
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
        notificationDelegate.coordinator = coordinator
        center.delegate = notificationDelegate

        // Check current notification status (no eager authorization)
        Task { await coordinator.notificationManager.refreshStatus() }

        // Register notification category
        let category = UNNotificationCategory(
            identifier: "CLAUDE_HOOK_EVENT",
            actions: [],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])

        // Start the hook service
        coordinator.claudeHookService = ClaudeHookService(coordinator: coordinator)

        // Install hooks if needed (one-time, non-blocking)
        ClaudeHookService.setupHooksIfNeeded()
    }

    private func setupForegroundTracking() {
        let coord = coordinator
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in coord.isAppForeground = true }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in coord.isAppForeground = false }
        }
    }
}
