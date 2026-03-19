import SwiftUI

struct TrialBannerView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        if coordinator.licenseManager.isInTrial {
            HStack {
                Label {
                    Text(daysText)
                        .font(.caption)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "clock")
                        .font(.caption)
                }

                Spacer()

                Button("Buy — $24") {
                    coordinator.selectedSettingsTab = .license
                    openSettings()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .buttonStyle(.plain)
                .foregroundStyle(.teal)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.teal.opacity(0.15))
            .foregroundStyle(.primary)
        }
    }

    private var daysText: String {
        let days = coordinator.licenseManager.trialDaysRemaining
        if days == 1 {
            return "Trial: 1 day remaining"
        } else {
            return "Trial: \(days) days remaining"
        }
    }
}
