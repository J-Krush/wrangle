//
//  ClaudeHookService.swift
//  wrangle
//

import Foundation
import AppKit
import UserNotifications

// MARK: - Event Model

struct ClaudeHookEvent: Codable {
    let sessionID: String
    let hookEventName: String
    let notificationType: String?
    let message: String?
    let title: String?
    let cwd: String?
    let stopHookActive: Bool?
}

// MARK: - Service

@MainActor
@Observable
class ClaudeHookService {
    private var fileWatcher: FileWatcher?
    private var processTask: Task<Void, Never>?
    private weak var appState: AppState?

    nonisolated static let eventsDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".wrangle/events")
    }()

    nonisolated static let hooksDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".wrangle/hooks")
    }()

    private nonisolated static let notificationCategory = "CLAUDE_HOOK_EVENT"
    private nonisolated static let staleThreshold: TimeInterval = 300 // 5 minutes

    init(appState: AppState) {
        self.appState = appState
        ensureDirectories()
        purgeStaleEvents()
        startWatching()
    }

    func tearDown() {
        fileWatcher?.stop()
        processTask?.cancel()
    }

    // MARK: - Directory Setup

    private func ensureDirectories() {
        let fm = FileManager.default
        for dir in [Self.eventsDirectory, Self.hooksDirectory] {
            if !fm.fileExists(atPath: dir.path) {
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - File Watching

    private func startWatching() {
        fileWatcher = FileWatcher(url: Self.eventsDirectory, debounceInterval: 0.2) { [weak self] in
            self?.processEventFiles()
        }
        fileWatcher?.start()
    }

    private func processEventFiles() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: Self.eventsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let jsonFiles = files.filter { $0.pathExtension == "json" }
        for file in jsonFiles {
            defer { try? fm.removeItem(at: file) }

            // Discard stale events (older than 5 minutes)
            if let attrs = try? fm.attributesOfItem(atPath: file.path),
               let created = attrs[.creationDate] as? Date,
               Date().timeIntervalSince(created) > Self.staleThreshold {
                continue
            }

            guard let data = try? Data(contentsOf: file),
                  let event = try? JSONDecoder().decode(ClaudeHookEvent.self, from: data) else {
                continue
            }

            handleEvent(event)
        }
    }

    // MARK: - Purge Stale on Launch

    private func purgeStaleEvents() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: Self.eventsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        for file in files where file.pathExtension == "json" {
            if let attrs = try? fm.attributesOfItem(atPath: file.path),
               let created = attrs[.creationDate] as? Date,
               Date().timeIntervalSince(created) > Self.staleThreshold {
                try? fm.removeItem(at: file)
            }
        }
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: ClaudeHookEvent) {
        // Skip if stop_hook_active (prevents hook loops)
        if event.stopHookActive == true { return }

        guard shouldNotify(for: event) else { return }
        markSessionNeedsAttention(for: event.sessionID)
        sendNotification(for: event)
    }

    private func markSessionNeedsAttention(for sessionID: String) {
        guard let appState else { return }
        let session = appState.tabs
            .compactMap(\.terminalSession)
            .first { $0.id.uuidString == sessionID }
        session?.needsAttention = true
    }

    private func shouldNotify(for event: ClaudeHookEvent) -> Bool {
        guard let appState else { return true }

        // If app is in foreground and the session's tab is active, suppress
        if appState.isAppForeground,
           let activeSession = appState.activeTab?.terminalSession,
           activeSession.id.uuidString == event.sessionID {
            return false
        }
        return true
    }

    // MARK: - Notification Dispatch

    private func sendNotification(for event: ClaudeHookEvent) {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: event)
        content.body = notificationBody(for: event)
        content.sound = .default
        content.categoryIdentifier = Self.notificationCategory
        content.userInfo = ["sessionID": event.sessionID]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func notificationTitle(for event: ClaudeHookEvent) -> String {
        if let sessionTitle = sessionDisplayTitle(for: event.sessionID) {
            return "Wrangle — \(sessionTitle)"
        }
        return "Wrangle"
    }

    private func notificationBody(for event: ClaudeHookEvent) -> String {
        if event.hookEventName == "Stop" {
            return "Ready for input"
        }
        if event.notificationType == "permission_prompt" {
            let msg = event.message ?? ""
            return msg.isEmpty ? "Permission needed" : "Permission needed: \(msg.prefix(180))"
        }
        if let message = event.message, !message.isEmpty {
            return message.count > 200 ? String(message.prefix(197)) + "..." : message
        }
        if event.notificationType == "idle_prompt" {
            return "Waiting for input"
        }
        return "Needs attention"
    }

    private func sessionDisplayTitle(for sessionID: String) -> String? {
        guard let appState else { return nil }
        let session = appState.tabs
            .compactMap(\.terminalSession)
            .first { $0.id.uuidString == sessionID }
        return session?.displayTitle
    }

    // MARK: - Notification Click Routing

    func handleNotificationTap(sessionID: String) {
        guard let appState else { return }

        guard let tabIndex = appState.tabs.firstIndex(where: {
            $0.terminalSession?.id.uuidString == sessionID
        }) else { return }

        appState.selectTab(at: tabIndex)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Hook Installation (Static Helpers)

    nonisolated static func installedHookScriptPath() -> URL {
        hooksDirectory.appendingPathComponent("wrangle-claude-hook.sh")
    }

    /// Embedded hook script content — written to disk at install time.
    /// Uses Python for all JSON handling to avoid shell escaping issues.
    private nonisolated static let hookScriptContent = """
        #!/bin/bash
        # wrangle-claude-hook.sh — Claude Code hook for Wrangle notifications
        set -euo pipefail
        [ -z "${WRANGLE_SESSION_ID:-}" ] && exit 0
        /usr/bin/python3 -c '
        import sys, json, os, time
        d = json.load(sys.stdin)
        if str(d.get("stop_hook_active", "")).lower() == "true":
            sys.exit(0)
        events_dir = os.path.expanduser("~/.wrangle/events")
        os.makedirs(events_dir, exist_ok=True)
        sid = os.environ.get("WRANGLE_SESSION_ID", "")
        event = {
            "sessionID": sid,
            "hookEventName": d.get("hook_event_name", ""),
            "notificationType": d.get("notification_type", ""),
            "message": d.get("message", ""),
            "title": d.get("title", ""),
            "cwd": d.get("cwd", ""),
            "stopHookActive": False
        }
        ts = str(int(time.time() * 1000))
        path = os.path.join(events_dir, sid + "_" + ts + ".json")
        with open(path, "w") as f:
            json.dump(event, f)
        ' 2>/dev/null
        exit 0
        """

    nonisolated static func installHookScript() throws {
        let fm = FileManager.default
        let destDir = hooksDirectory
        if !fm.fileExists(atPath: destDir.path) {
            try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        }

        let dest = installedHookScriptPath()
        // Dedent the embedded script (remove leading 8-space indentation)
        let lines = hookScriptContent.split(separator: "\n", omittingEmptySubsequences: false)
        let dedented = lines.map { line in
            if line.hasPrefix("        ") {
                return String(line.dropFirst(8))
            }
            return String(line)
        }.joined(separator: "\n")

        try dedented.write(to: dest, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
    }

    nonisolated static func isHookConfigured() -> Bool {
        let settingsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        guard let data = try? Data(contentsOf: settingsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let _ = json["hooks"] as? [String: Any] else {
            return false
        }
        // Check if either Stop or Notification hooks reference our script
        let scriptName = "wrangle-claude-hook.sh"
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        return jsonString.contains(scriptName)
    }

    nonisolated static func configureClaudeHooks() throws {
        let settingsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        let fm = FileManager.default

        // Ensure .claude directory exists
        let claudeDir = settingsURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: claudeDir.path) {
            try fm.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        }

        // Read existing settings or start fresh
        var settings: [String: Any] = [:]
        if let data = try? Data(contentsOf: settingsURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = existing
        }

        // Build hook entry
        let hookCommand = installedHookScriptPath().path
        let hookEntry: [String: Any] = [
            "type": "command",
            "command": hookCommand
        ]
        let matcherEntry: [String: Any] = [
            "hooks": [hookEntry]
        ]

        // Merge into existing hooks (don't overwrite user's other hooks)
        var hooks = settings["hooks"] as? [String: Any] ?? [:]

        for eventName in ["Stop", "Notification"] {
            var matchers = hooks[eventName] as? [[String: Any]] ?? []

            // Check if our hook is already there
            let alreadyPresent = matchers.contains { matcher in
                guard let hookList = matcher["hooks"] as? [[String: Any]] else { return false }
                return hookList.contains { ($0["command"] as? String)?.contains("wrangle-claude-hook") == true }
            }

            if !alreadyPresent {
                matchers.append(matcherEntry)
            }
            hooks[eventName] = matchers
        }

        settings["hooks"] = hooks

        let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: settingsURL)
    }

    nonisolated static func setupHooksIfNeeded() {
        Task.detached {
            do {
                try installHookScript()
                if !isHookConfigured() {
                    try configureClaudeHooks()
                }
            } catch {
                print("[ClaudeHookService] Hook setup failed: \(error)")
            }
        }
    }

}
