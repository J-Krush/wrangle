import SwiftUI

enum SettingsTab: Hashable {
    case general
}

struct SettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        TabView(selection: $coordinator.selectedSettingsTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)
        }
        .frame(minWidth: 450, minHeight: 300)
    }
}
