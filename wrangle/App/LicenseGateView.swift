import SwiftUI

struct LicenseGateView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var licenseKey = ""

    var body: some View {
        if coordinator.licenseManager.needsLicense {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("Welcome to Wrangle")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Enter your license key to get started. Don't have one yet? Purchase a license to unlock the app.")
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
                                }
                            }
                            .disabled(licenseKey.trimmingCharacters(in: .whitespaces).isEmpty)
                            .buttonStyle(.borderedProminent)

                            Link("Buy License", destination: URL(string: "https://wrangleapp.dev/buy")!)
                                .buttonStyle(.bordered)
                        }

                        if !coordinator.licenseManager.statusMessage.isEmpty {
                            Text(coordinator.licenseManager.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
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
