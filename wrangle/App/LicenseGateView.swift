import SwiftUI

struct LicenseGateView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var licenseKey = ""
    @State private var trialEmail = ""
    @State private var showLicenseKeyInput = false
    @State private var isActivatingTrial = false

    var body: some View {
        if coordinator.licenseManager.needsLicense {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if coordinator.licenseManager.trialExpired {
                        trialExpiredContent
                    } else {
                        trialActivationContent
                    }
                }
                .padding(40)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 20)
            }
        }
    }

    private var trialActivationContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.gift.fill")
                .font(.system(size: 40))
                .foregroundStyle(.teal)

            Text("Welcome to Wrangle")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 4) {
                Text("Try Wrangle free for 3 days.")
                    .font(.body)
                Text("No credit card required.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                TextField("Email address", text: $trialEmail)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 320)
                    .disabled(isActivatingTrial)

                Button {
                    startTrial()
                } label: {
                    if isActivatingTrial {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 320)
                    } else {
                        Text("Start Free Trial")
                            .frame(width: 320)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(!isValidEmail || isActivatingTrial)
            }

            dividerWithText("or")

            VStack(spacing: 12) {
                Button(showLicenseKeyInput ? "Hide license key" : "Already have a license key?") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showLicenseKeyInput.toggle()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

                if showLicenseKeyInput {
                    VStack(spacing: 12) {
                        TextField("License Key", text: $licenseKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 320)

                        Button("Activate") {
                            coordinator.licenseManager.licenseKey = licenseKey
                            Task {
                                await coordinator.licenseManager.activate()
                            }
                        }
                        .disabled(licenseKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(.bordered)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            if !coordinator.licenseManager.statusMessage.isEmpty {
                Text(coordinator.licenseManager.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var trialExpiredContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Your Trial Has Ended")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Buy a license to continue using Wrangle.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Link("Buy License — $24", destination: URL(string: "https://wrangleapp.dev/buy")!)
                .buttonStyle(.borderedProminent)
                .tint(.teal)

            dividerWithText("or")

            VStack(spacing: 12) {
                Button(showLicenseKeyInput ? "Hide license key" : "Enter license key") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showLicenseKeyInput.toggle()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

                if showLicenseKeyInput {
                    VStack(spacing: 12) {
                        TextField("License Key", text: $licenseKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 320)

                        Button("Activate") {
                            coordinator.licenseManager.licenseKey = licenseKey
                            Task {
                                await coordinator.licenseManager.activate()
                            }
                        }
                        .disabled(licenseKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(.bordered)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            if !coordinator.licenseManager.statusMessage.isEmpty {
                Text(coordinator.licenseManager.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func dividerWithText(_ text: String) -> some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.quaternary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.quaternary)
        }
        .frame(width: 200)
    }

    private var isValidEmail: Bool {
        let trimmed = trialEmail.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 5
    }

    private func startTrial() {
        guard isValidEmail else { return }
        isActivatingTrial = true
        Task {
            await coordinator.licenseManager.activateTrial(email: trialEmail.trimmingCharacters(in: .whitespaces))
            isActivatingTrial = false
        }
    }
}
