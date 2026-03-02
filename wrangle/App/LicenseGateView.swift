import SwiftUI

struct LicenseGateView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var dismissed = false
    @State private var licenseKey = ""

    var body: some View {
        if coordinator.licenseManager.shouldShowNag && !dismissed {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("Your Trial Has Expired")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Thanks for trying Wrangle! To continue using the app, please enter a license key or purchase one.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)

                    VStack(spacing: 12) {
                        TextField("License Key", text: $licenseKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 320)

                        HStack(spacing: 12) {
                            Button("Activate") {
                                coordinator.licenseManager.licenseKey = licenseKey
                                Task {
                                    await coordinator.licenseManager.activate()
                                    if coordinator.licenseManager.isLicensed {
                                        dismissed = true
                                    }
                                }
                            }
                            .disabled(licenseKey.trimmingCharacters(in: .whitespaces).isEmpty)
                            .buttonStyle(.borderedProminent)

                            Link("Buy License", destination: URL(string: "https://wrangle.dev/buy")!)
                                .buttonStyle(.bordered)
                        }

                        if !coordinator.licenseManager.statusMessage.isEmpty {
                            Text(coordinator.licenseManager.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    Button("Continue Without License") {
                        dismissed = true
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(40)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 20)
            }
        }
    }
}
