import Foundation
import AppKit
import UserNotifications

@MainActor
@Observable
class NotificationPermissionManager {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var hasShownPrompt: Bool = UserDefaults.standard.bool(forKey: "hasShownNotificationPrompt")
    var bannerDismissedThisSession: Bool = false

    /// True only when we've confirmed status is genuinely not-determined (after refresh)
    private var hasCheckedStatus: Bool = false

    var shouldShowModal: Bool {
        hasCheckedStatus && !hasShownPrompt && authorizationStatus == .notDetermined
    }

    var shouldShowBanner: Bool {
        hasCheckedStatus && !bannerDismissedThisSession && !isEnabled && !shouldShowModal
    }

    var isEnabled: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        hasCheckedStatus = true
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            await refreshStatus()
            markPromptShown()
            return granted
        } catch {
            print("[Wrangle] Notification auth error: \(error)")
            markPromptShown()
            return false
        }
    }

    func markPromptShown() {
        hasShownPrompt = true
        UserDefaults.standard.set(true, forKey: "hasShownNotificationPrompt")
    }

    func dismissBanner() {
        bannerDismissedThisSession = true
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}
