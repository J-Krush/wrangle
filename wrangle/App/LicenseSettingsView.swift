import SwiftUI

struct LicenseSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var manager = coordinator.licenseManager

        Form {
            Section {
                HStack {
                    statusBadge
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.headline)
                        Text(statusSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("License Key") {
                TextField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", text: $manager.licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isLicensed || manager.isValidating)

                HStack {
                    if manager.isLicensed {
                        Button("Deactivate") {
                            Task { await coordinator.licenseManager.deactivate() }
                        }
                        .disabled(manager.isValidating)
                    } else {
                        Button("Activate License") {
                            Task { await coordinator.licenseManager.activate() }
                        }
                        .disabled(manager.licenseKey.trimmingCharacters(in: .whitespaces).isEmpty || manager.isValidating)
                    }

                    if manager.isValidating {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if !manager.statusMessage.isEmpty {
                    Text(manager.statusMessage)
                        .font(.caption)
                        .foregroundStyle(manager.isLicensed ? .green : .orange)
                }
            }

            if manager.isLicensed, !manager.customerName.isEmpty {
                Section("Registered To") {
                    Text(manager.customerName)
                }
            }

            Section {
                Link("Purchase a License", destination: URL(string: "https://wrangle.dev/buy")!)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }

    private var statusBadge: some View {
        Group {
            switch coordinator.licenseManager.licenseStatus {
            case .valid:
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            case .trial:
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
            case .trialExpired:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
            case .invalid, .expired:
                Image(systemName: "xmark.seal.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
            case .unknown:
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
        }
    }

    private var statusTitle: String {
        switch coordinator.licenseManager.licenseStatus {
        case .valid: "Licensed"
        case .trial: "Trial"
        case .trialExpired: "Trial Expired"
        case .invalid: "Invalid License"
        case .expired: "License Expired"
        case .unknown: "Checking..."
        }
    }

    private var statusSubtitle: String {
        switch coordinator.licenseManager.licenseStatus {
        case .valid: "Thank you for purchasing Wrangle!"
        case .trial: "\(coordinator.licenseManager.trialDaysRemaining) days remaining"
        case .trialExpired: "Please purchase a license to continue using Wrangle."
        case .invalid: "The license key entered is not valid."
        case .expired: "Your license has expired."
        case .unknown: "Verifying license status..."
        }
    }
}
