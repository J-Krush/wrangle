import Foundation

/// Pure, UI-free logic backing the "confirm before quitting" feature.
///
/// The decision of *whether* to interrupt a quit — and what to tell the user —
/// is deliberately separated from the AppKit `NSAlert` presentation so it can be
/// unit tested without a running app. `AppDelegate.applicationShouldTerminate(_:)`
/// gathers the live ``Risk`` from the open windows, asks ``decision(enabled:risk:)``,
/// and only then touches any UI.
enum QuitConfirmation {
    /// `UserDefaults` key shared by `GeneralSettingsView`'s toggle and the
    /// alert's "Don't ask again" checkbox, so the two surfaces never drift apart.
    nonisolated static let confirmBeforeQuitDefaultsKey = "confirmBeforeQuit"

    /// Behaviour when the user has never expressed a preference: warn (on).
    nonisolated static let confirmBeforeQuitDefault = true

    /// Whether the warning is currently enabled, honouring the default-on
    /// behaviour.
    ///
    /// Uses `object(forKey:)` rather than `bool(forKey:)` on purpose: the latter
    /// returns `false` for an unset key, which would silently disable the
    /// default-on protection on a fresh install.
    static func isEnabled(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: confirmBeforeQuitDefaultsKey) as? Bool ?? confirmBeforeQuitDefault
    }

    /// Persists the user's choice. Called by the alert's suppression checkbox so
    /// "Don't ask again" and the Settings toggle stay in sync.
    static func setEnabled(_ enabled: Bool, in defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: confirmBeforeQuitDefaultsKey)
    }

    /// A snapshot of what the user stands to lose by quitting right now, summed
    /// across every open window.
    struct Risk: Equatable {
        var runningSessions: Int
        var unsavedDocuments: Int

        var hasRisk: Bool { runningSessions > 0 || unsavedDocuments > 0 }
    }

    /// The outcome of evaluating a quit request.
    enum Decision: Equatable {
        /// Terminate with no interruption.
        case quitImmediately
        /// Show a confirmation carrying this informative message.
        case confirm(message: String)
    }

    /// Decides how to handle a quit request. Pure — no side effects.
    ///
    /// We only interrupt the quit when the feature is enabled *and* there is
    /// something to lose. With nothing running and nothing unsaved, quitting is
    /// instant — no friction.
    static func decision(enabled: Bool, risk: Risk) -> Decision {
        guard enabled, risk.hasRisk else { return .quitImmediately }
        return .confirm(message: message(for: risk))
    }

    /// Human-readable description of what quitting will discard, pluralised and
    /// tailored to whichever combination of risks is present.
    static func message(for risk: Risk) -> String {
        let sessions = risk.runningSessions
        let docs = risk.unsavedDocuments

        if sessions > 0 && docs > 0 {
            return "\(count(sessions, "terminal session")) still running and "
                + "\(count(docs, "document")) with unsaved changes. Quitting will stop "
                + "the \(sessions == 1 ? "session" : "sessions") and discard unsaved changes."
        } else if sessions > 0 {
            return "\(count(sessions, "terminal session")) still running. "
                + "Quitting will stop \(sessions == 1 ? "it" : "them")."
        } else if docs > 0 {
            return "\(count(docs, "document")) with unsaved changes. "
                + "Quitting will discard \(docs == 1 ? "it" : "them")."
        } else {
            // Not reachable via `decision(enabled:risk:)` (guarded by `hasRisk`),
            // but kept total so the function is safe to call directly.
            return "You have unsaved work."
        }
    }

    /// "1 terminal session" / "3 terminal sessions"
    private static func count(_ n: Int, _ noun: String) -> String {
        "\(n) \(noun)\(n == 1 ? "" : "s")"
    }
}
