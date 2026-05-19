import SwiftUI

struct NotificationPermissionView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        let manager = coordinator.notificationManager

        if manager.shouldShowModal && !coordinator.whatsNewManager.shouldShowModal {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)

                    Text("Stay in the Loop")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Wrangle can notify you when Claude Code needs attention — permission prompts, completed tasks, and idle sessions.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)

                    HStack(spacing: 12) {
                        Button("Not Now") {
                            manager.markPromptShown()
                        }
                        .buttonStyle(.bordered)

                        Button("Enable Notifications") {
                            Task {
                                await manager.requestAuthorization()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(40)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 20)
            }
        }
    }
}
