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

            if manager.isInTrial {
                Section("Trial") {
                    if !manager.trialEmail.isEmpty {
                        LabeledContent("Email", value: manager.trialEmail)
                    }
                    Link("Buy License — $24", destination: URL(string: "https://wrangleapp.dev/buy")!)
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                }
            }

            Section("License Key") {
                TextField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", text: $manager.licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.licenseStatus == .valid || manager.isValidating)

                HStack {
                    if manager.licenseStatus == .valid {
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
            case .invalid, .expired:
                Image(systemName: "xmark.seal.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
            case .trial:
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)
            case .unlicensed:
                Image(systemName: "key.fill")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
        }
    }

    private var statusTitle: String {
        switch coordinator.licenseManager.licenseStatus {
        case .valid: "Licensed"
        case .invalid: "Invalid License"
        case .expired: "License Expired"
        case .trial: "Trial Active"
        case .unlicensed: "No License"
        }
    }

    private var statusSubtitle: String {
        switch coordinator.licenseManager.licenseStatus {
        case .valid: return "Thank you for purchasing Wrangle!"
        case .invalid: return "The license key entered is not valid."
        case .expired: return "Your license has expired."
        case .trial:
            let days = coordinator.licenseManager.trialDaysRemaining
            return days == 1 ? "1 day remaining in your trial." : "\(days) days remaining in your trial."
        case .unlicensed: return "Enter a license key to activate Wrangle."
        }
    }
}
