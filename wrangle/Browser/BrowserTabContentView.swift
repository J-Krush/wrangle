//
//  BrowserTabContentView.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

struct BrowserTabContentView: View {
    let session: BrowserSession
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var keyMonitor: Any?
    @State private var isFindBarVisible: Bool = false
    @State private var findQuery: String = ""

    private var isActive: Bool {
        appState.activeTab?.browserSession?.id == session.id
    }

    private var showsNewTabPage: Bool {
        guard let tab = session.activeTab else { return false }
        return tab.url == nil && !tab.isLoading
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with address bar
            BrowserToolbar(session: session)
            Divider()

            // Find bar (Cmd+F)
            if isFindBarVisible {
                BrowserFindBar(session: session, isVisible: $isFindBarVisible, query: $findQuery)
            }

            // Progress bar
            if let tab = session.activeTab, tab.isLoading {
                ProgressView(value: tab.estimatedProgress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .frame(height: 2)
            }

            // WebView with optional New Tab overlay
            ZStack {
                BrowserWebView(session: session, isActive: isActive, modelContext: modelContext, appState: appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showsNewTabPage {
                    NewTabPage(session: session)
                        .transition(.opacity)
                }
            }

            // DevTools panel
            if session.isDevToolsVisible {
                Divider()
                DevToolsPanel(session: session)
                    .frame(height: session.devToolsHeight)
            }

            // Status bar
            Divider()
            BrowserStatusBar(session: session)
        }
        .background(Color(nsColor: Theme.chromeBackground))
        .onAppear { installKeyMonitor() }
        .onDisappear { removeKeyMonitor() }
    }

    // MARK: - Keyboard shortcuts

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        let session = session
        let handler = KeyHandler(session: session, appState: appState)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [handler] event in
            MainActor.assumeIsolated {
                handler.handle(event, toggleFind: toggleFindBar)
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func toggleFindBar() {
        isFindBarVisible.toggle()
        if !isFindBarVisible {
            findQuery = ""
        }
    }
}

// MARK: - Key Handler

/// Owns the event-monitor logic separately from the View struct so we don't
/// have to capture `self` across actor boundaries.
@MainActor
private final class KeyHandler {
    weak var session: BrowserSession?
    weak var appState: AppState?

    init(session: BrowserSession, appState: AppState) {
        self.session = session
        self.appState = appState
    }

    func handle(_ event: NSEvent, toggleFind: @MainActor () -> Void) -> NSEvent? {
        guard let session, let appState else { return event }
        guard appState.activeTab?.browserSession?.id == session.id else { return event }

        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let cmd: NSEvent.ModifierFlags = .command
        let cmdOpt: NSEvent.ModifierFlags = [.command, .option]
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""

        if mods == cmdOpt {
            switch key {
            case "i":
                session.isDevToolsVisible.toggle()
                return nil
            case "j":
                session.isDevToolsVisible = true
                session.activeDevTool = .console
                return nil
            case "c":
                session.isDevToolsVisible = true
                session.activeDevTool = .elements
                NotificationCenter.default.post(
                    name: .browserRequestElementPick,
                    object: nil,
                    userInfo: ["sessionID": session.id.uuidString]
                )
                return nil
            default:
                return event
            }
        }

        guard mods == cmd else { return event }

        switch key {
        case "f":
            toggleFind()
            return nil
        case "t":
            appState.openBrowser(isPrivate: session.isPrivate)
            return nil
        case "w":
            // Close the workspace tab. Falls through to global Cmd+W.
            return event
        case "[":
            if session.activeTab?.canGoBack == true {
                session.activeTab?.pendingNavigation = .goBack
                return nil
            }
            return event
        case "]":
            if session.activeTab?.canGoForward == true {
                session.activeTab?.pendingNavigation = .goForward
                return nil
            }
            return event
        default:
            return event
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let browserRequestElementPick = Notification.Name("browserRequestElementPick")
}
