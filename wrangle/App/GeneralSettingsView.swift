import SwiftUI
import UserNotifications

struct GeneralSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @AppStorage("editorFontSize") private var editorFontSize: Double = 14
    @AppStorage("showLineNumbers") private var showLineNumbers: Bool = true
    @AppStorage("autoSaveEnabled") private var autoSaveEnabled: Bool = false
    @AppStorage("showTimeline") private var showTimeline: Bool = true
    @AppStorage("showSystemMetrics") private var showSystemMetrics: Bool = true

    var body: some View {
        @Bindable var coordinator = coordinator

        Form {
            Picker("Appearance", selection: $coordinator.appearanceMode) {
                Text("System").tag(AppearanceMode.system)
                Text("Light").tag(AppearanceMode.light)
                Text("Dark").tag(AppearanceMode.dark)
            }

            Section("Editor") {
                HStack {
                    Text("Font Size")
                    Slider(value: $editorFontSize, in: 10...24, step: 1) {
                        Text("Font Size")
                    }
                    Text("\(Int(editorFontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }

                Toggle("Show Line Numbers", isOn: $showLineNumbers)
                Toggle("Auto-save on Focus Loss", isOn: $autoSaveEnabled)
            }

            Section("Title Bar") {
                Toggle("Show System Metrics", isOn: $showSystemMetrics)
            }

            Section("Timeline") {
                Toggle("Show Timeline Scrubber", isOn: $showTimeline)
            }

            Section("Updates") {
                Toggle("Check for Updates Automatically", isOn: .constant(true))
            }

            Section("Notifications") {
                let manager = coordinator.notificationManager

                HStack(spacing: 6) {
                    Image(systemName: manager.isEnabled ? "bell.fill" : "bell.slash.fill")
                        .foregroundStyle(manager.isEnabled ? .green : .orange)
                    Text(manager.isEnabled ? "Enabled" : "Disabled")
                }

                if manager.authorizationStatus == .denied {
                    Button("Open Notification Settings...") {
                        manager.openSystemSettings()
                    }
                    Text("Notifications were denied. Enable them in System Settings to receive agent session alerts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if manager.authorizationStatus == .notDetermined {
                    Button("Enable Notifications") {
                        Task { await manager.requestAuthorization() }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
