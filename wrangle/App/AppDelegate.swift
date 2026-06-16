import AppKit

/// Minimal AppKit delegate, attached to the SwiftUI lifecycle via
/// `@NSApplicationDelegateAdaptor` in `WrangleApp`.
///
/// Its sole job is to give the app a chance to confirm a quit (⌘Q, the Quit menu
/// item, or log-out) while terminal sessions are running or documents have
/// unsaved changes — see ``QuitConfirmation``.
///
/// `applicationShouldTerminate(_:)` is the documented hook for cancelling a
/// termination (return `.terminateCancel`), and it fires reliably under
/// `@NSApplicationDelegateAdaptor`. (The delegate callback that is *not* reliable
/// under the adaptor is `applicationShouldHandleReopen(_:hasVisibleWindows:)`,
/// per FB9754295 — which this feature does not use.)
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Wired by `WrangleApp` once the SwiftUI scene appears, so the delegate can
    /// inspect every open window's tabs. `WrangleApp` owns the coordinator via
    /// `@State` for the app's lifetime, and the coordinator holds no reference
    /// back, so a plain strong reference is correct (no retain cycle). It stays
    /// `nil` only in the narrow window before the first scene appears, in which
    /// case we let the quit proceed without a prompt.
    var coordinator: AppCoordinator?

    func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
        let decision = QuitConfirmation.decision(
            enabled: QuitConfirmation.isEnabled(),
            risk: currentRisk()
        )
        switch decision {
        case .quitImmediately:
            return .terminateNow
        case .confirm(let message):
            return presentConfirmation(message: message)
        }
    }

    /// Tallies running terminal sessions and unsaved documents across every open
    /// window registered with the coordinator. Falls back to "no risk" (quit
    /// freely) if the coordinator hasn't been wired yet.
    private func currentRisk() -> QuitConfirmation.Risk {
        guard let coordinator else {
            return QuitConfirmation.Risk(runningSessions: 0, unsavedDocuments: 0)
        }
        let tabs = coordinator.windowStates.values.flatMap(\.tabs)
        return QuitConfirmation.Risk(
            runningSessions: tabs.filter(\.isRunningTerminal).count,
            unsavedDocuments: tabs.filter(\.isDirty).count
        )
    }

    /// Shows the modal confirmation and maps the result to a terminate reply.
    /// Ticking "Don't ask again" disables the preference (the same key the
    /// Settings toggle reads), matching the browser model.
    private func presentConfirmation(message: String) -> NSApplication.TerminateReply {
        let alert = NSAlert()
        alert.messageText = "Quit Wrangle?"
        alert.informativeText = message
        alert.alertStyle = .warning

        // The first-added button is the default (responds to Return) and sits on
        // the trailing edge. Per Apple's HIG, the default for a destructive
        // prompt should be the *safe* choice, so an accidental Return cancels
        // rather than quits. Esc also maps to Cancel automatically.
        alert.addButton(withTitle: "Cancel")
        let quitButton = alert.addButton(withTitle: "Quit")
        quitButton.hasDestructiveAction = true

        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Don't ask again"

        let response = alert.runModal()
        // .alertFirstButtonReturn == Cancel, .alertSecondButtonReturn == Quit
        let isQuitting = response == .alertSecondButtonReturn

        // Only honour "Don't ask again" when the user actually goes through with
        // the quit. Persisting it on Cancel would silently disable the guard the
        // user just invoked — a footgun for a safety feature.
        if isQuitting, alert.suppressionButton?.state == .on {
            QuitConfirmation.setEnabled(false)
        }

        return isQuitting ? .terminateNow : .terminateCancel
    }
}
