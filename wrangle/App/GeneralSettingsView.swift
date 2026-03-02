import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @AppStorage("editorFontSize") private var editorFontSize: Double = 14
    @AppStorage("showLineNumbers") private var showLineNumbers: Bool = true
    @AppStorage("autoSaveEnabled") private var autoSaveEnabled: Bool = false

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

            Section("Updates") {
                Toggle("Check for Updates Automatically", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
