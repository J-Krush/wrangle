import Foundation
import Testing
@testable import Wrangle

/// Tests for ``QuitConfirmation`` — the pure, UI-free logic deciding whether a
/// quit request should be interrupted and what the confirmation should say.
///
/// The AppKit `NSAlert` presentation in `AppDelegate` is intentionally a thin
/// shell over this type, so the interesting behaviour is all covered here
/// without needing a running app.
@MainActor
@Suite("QuitConfirmation")
struct QuitConfirmationTests {

    // MARK: - decision()

    @Test("Disabled preference quits immediately, even with risk present")
    func disabledQuitsImmediately() {
        let risk = QuitConfirmation.Risk(runningSessions: 3, unsavedDocuments: 2)
        #expect(QuitConfirmation.decision(enabled: false, risk: risk) == .quitImmediately)
    }

    @Test("Enabled with no risk quits immediately")
    func noRiskQuitsImmediately() {
        let risk = QuitConfirmation.Risk(runningSessions: 0, unsavedDocuments: 0)
        #expect(QuitConfirmation.decision(enabled: true, risk: risk) == .quitImmediately)
    }

    @Test("Enabled with a running session asks for confirmation")
    func runningSessionConfirms() {
        let risk = QuitConfirmation.Risk(runningSessions: 1, unsavedDocuments: 0)
        #expect(
            QuitConfirmation.decision(enabled: true, risk: risk)
                == .confirm(message: QuitConfirmation.message(for: risk))
        )
    }

    @Test("Enabled with an unsaved document asks for confirmation")
    func unsavedDocumentConfirms() {
        let risk = QuitConfirmation.Risk(runningSessions: 0, unsavedDocuments: 1)
        guard case .confirm = QuitConfirmation.decision(enabled: true, risk: risk) else {
            Issue.record("Expected .confirm for an unsaved document")
            return
        }
    }

    // MARK: - Risk.hasRisk

    @Test("hasRisk is true when either dimension is non-zero")
    func hasRisk() {
        #expect(!QuitConfirmation.Risk(runningSessions: 0, unsavedDocuments: 0).hasRisk)
        #expect(QuitConfirmation.Risk(runningSessions: 1, unsavedDocuments: 0).hasRisk)
        #expect(QuitConfirmation.Risk(runningSessions: 0, unsavedDocuments: 1).hasRisk)
        #expect(QuitConfirmation.Risk(runningSessions: 2, unsavedDocuments: 3).hasRisk)
    }

    // MARK: - message()

    @Test("Sessions-only message mentions sessions and not documents")
    func sessionsOnlyMessage() {
        let msg = QuitConfirmation.message(for: .init(runningSessions: 2, unsavedDocuments: 0))
        #expect(msg.contains("2 terminal sessions"))
        #expect(!msg.contains("unsaved"))
    }

    @Test("Documents-only message mentions documents and not sessions")
    func documentsOnlyMessage() {
        let msg = QuitConfirmation.message(for: .init(runningSessions: 0, unsavedDocuments: 1))
        #expect(msg.contains("1 document"))
        #expect(!msg.contains("terminal session"))
    }

    @Test("Combined message mentions both sessions and documents")
    func combinedMessage() {
        let msg = QuitConfirmation.message(for: .init(runningSessions: 1, unsavedDocuments: 3))
        #expect(msg.contains("1 terminal session"))
        #expect(msg.contains("3 documents"))
        #expect(msg.contains("unsaved changes"))
    }

    @Test("Nouns are singular for a count of one")
    func singularNoun() {
        let msg = QuitConfirmation.message(for: .init(runningSessions: 1, unsavedDocuments: 0))
        // "1 terminal session " — singular, with the trailing space before "still"
        #expect(msg.contains("1 terminal session "))
    }

    @Test("Nouns are plural for a count greater than one")
    func pluralNoun() {
        let msg = QuitConfirmation.message(for: .init(runningSessions: 3, unsavedDocuments: 0))
        #expect(msg.contains("3 terminal sessions"))
    }

    // MARK: - isEnabled() / setEnabled()

    @Test("isEnabled defaults to true when the key is unset (default-on)")
    func enabledDefaultsTrue() {
        let suite = "QuitConfirmationTests.enabledDefault"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(QuitConfirmation.isEnabled(in: defaults) == true)
    }

    @Test("setEnabled(false) persists and is read back by isEnabled")
    func enabledRespectsExplicitFalse() {
        let suite = "QuitConfirmationTests.enabledFalse"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        QuitConfirmation.setEnabled(false, in: defaults)
        #expect(QuitConfirmation.isEnabled(in: defaults) == false)

        QuitConfirmation.setEnabled(true, in: defaults)
        #expect(QuitConfirmation.isEnabled(in: defaults) == true)
    }
}
