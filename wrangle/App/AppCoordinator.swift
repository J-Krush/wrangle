import Foundation
import SwiftUI

@MainActor
@Observable
class AppCoordinator {
    var isAppForeground: Bool = true
    var appearanceMode: AppearanceMode = .system
    var claudeHookService: ClaudeHookService?
    var isSetupComplete: Bool = false
    var updateChecker = UpdateChecker()
    var licenseManager = LicenseManager()
    var notificationManager = NotificationPermissionManager()
    var whatsNewManager = WhatsNewManager()
    var selectedSettingsTab: SettingsTab = .general
    // Registry of all window states
    private(set) var windowStates: [UUID: AppState] = [:]

    func register(_ state: AppState) {
        windowStates[state.windowID] = state
    }

    func unregister(_ state: AppState) {
        windowStates.removeValue(forKey: state.windowID)
    }

    /// Search across all windows for a terminal session by its UUID string.
    func findTerminalSession(bySessionID sessionID: String) -> (appState: AppState, session: TerminalSession, tabIndex: Int)? {
        for state in windowStates.values {
            if let index = state.tabs.firstIndex(where: {
                $0.terminalSession?.id.uuidString == sessionID
            }), let session = state.tabs[index].terminalSession {
                return (state, session, index)
            }
        }
        return nil
    }
}
