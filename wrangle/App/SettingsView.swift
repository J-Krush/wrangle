import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            LicenseSettingsView()
                .tabItem {
                    Label("License", systemImage: "key")
                }
        }
        .frame(minWidth: 450, minHeight: 300)
    }
}
