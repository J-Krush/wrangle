import SwiftUI

struct NotificationBannerView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        let manager = coordinator.notificationManager

        if manager.shouldShowBanner {
            HStack(spacing: 8) {
                Image(systemName: "bell.slash.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text("Notifications are disabled — you may miss agent session alerts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Enable") {
                    manager.openSystemSettings()
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    manager.dismissBanner()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
        }
    }
}
