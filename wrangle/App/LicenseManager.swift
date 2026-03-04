import Foundation
import Security

@MainActor
@Observable
class LicenseManager {
    var licenseKey: String = ""
    var licenseStatus: LicenseStatus = .unknown
    var statusMessage: String = ""
    var isValidating: Bool = false
    var customerName: String = ""

    enum LicenseStatus: String {
        case unknown
        case valid
        case invalid
        case expired
        case trial
        case trialExpired
    }

    // MARK: - Trial

    private static let firstLaunchKey = "LicenseManager.firstLaunchDate"
    private static let trialDays = 14
    private static let instanceIDKey = "LicenseManager.instanceID"
    private static let keychainService = "dev.wrangle.license"
    private static let keychainAccount = "license-key"

    // Replace with your actual LemonSqueezy store/product IDs
    private static let activateURL = "https://api.lemonsqueezy.com/v1/licenses/activate"
    private static let validateURL = "https://api.lemonsqueezy.com/v1/licenses/validate"
    private static let deactivateURL = "https://api.lemonsqueezy.com/v1/licenses/deactivate"

    var instanceID: String {
        if let existing = UserDefaults.standard.string(forKey: Self.instanceIDKey) {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: Self.instanceIDKey)
        return id
    }

    var trialDaysRemaining: Int {
        guard let firstLaunch = UserDefaults.standard.object(forKey: Self.firstLaunchKey) as? Date else {
            // First launch — record now
            UserDefaults.standard.set(Date(), forKey: Self.firstLaunchKey)
            return Self.trialDays
        }
        let elapsed = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        return max(0, Self.trialDays - elapsed)
    }

    var isTrialExpired: Bool {
        trialDaysRemaining <= 0
    }

    var isLicensed: Bool {
        licenseStatus == .valid
    }

    var shouldShowNag: Bool {
        !isLicensed && isTrialExpired
    }

    // MARK: - Lifecycle

    func loadOnLaunch() {
        // Ensure first-launch date is set
        if UserDefaults.standard.object(forKey: Self.firstLaunchKey) == nil {
            UserDefaults.standard.set(Date(), forKey: Self.firstLaunchKey)
        }

        // Try loading stored license key from Keychain
        if let storedKey = loadKeyFromKeychain() {
            licenseKey = storedKey
            Task { await validate() }
        } else {
            licenseStatus = isTrialExpired ? .trialExpired : .trial
        }
    }

    // MARK: - License Actions

    func activate() async {
        guard !licenseKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            statusMessage = "Please enter a license key."
            return
        }

        isValidating = true
        statusMessage = ""

        do {
            var request = URLRequest(url: URL(string: Self.activateURL)!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let instanceName = ProcessInfo.processInfo.hostName
            let body = "license_key=\(licenseKey.trimmingCharacters(in: .whitespaces))&instance_name=\(instanceName)"
            request.httpBody = body.data(using: .utf8)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(LemonSqueezyResponse.self, from: data)

            if response.activated || response.valid {
                licenseStatus = .valid
                customerName = response.meta?.customerName ?? ""
                statusMessage = "License activated successfully."
                saveKeyToKeychain(licenseKey.trimmingCharacters(in: .whitespaces))
            } else {
                licenseStatus = .invalid
                statusMessage = response.error ?? "Activation failed. Please check your license key."
            }
        } catch {
            statusMessage = "Could not reach license server. Please check your connection."
        }

        isValidating = false
    }

    func validate() async {
        guard !licenseKey.isEmpty else { return }

        isValidating = true

        do {
            var request = URLRequest(url: URL(string: Self.validateURL)!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let body = "license_key=\(licenseKey)&instance_id=\(instanceID)"
            request.httpBody = body.data(using: .utf8)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(LemonSqueezyResponse.self, from: data)

            if response.valid {
                licenseStatus = .valid
                customerName = response.meta?.customerName ?? ""
            } else {
                licenseStatus = .invalid
                statusMessage = response.error ?? "License is no longer valid."
            }
        } catch {
            // Network error during validation — keep current status if previously valid
            if licenseStatus != .valid {
                statusMessage = "Could not verify license. Will retry later."
            }
        }

        isValidating = false
    }

    func deactivate() async {
        isValidating = true
        statusMessage = ""

        do {
            var request = URLRequest(url: URL(string: Self.deactivateURL)!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let body = "license_key=\(licenseKey)&instance_id=\(instanceID)"
            request.httpBody = body.data(using: .utf8)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(LemonSqueezyResponse.self, from: data)

            if response.deactivated {
                statusMessage = "License deactivated."
            }
        } catch {
            // Deactivation failed — remove locally anyway
        }

        removeKeyFromKeychain()
        licenseKey = ""
        customerName = ""
        licenseStatus = isTrialExpired ? .trialExpired : .trial
        isValidating = false
    }

    // MARK: - Keychain

    private func saveKeyToKeychain(_ key: String) {
        removeKeyFromKeychain()

        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func removeKeyFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - LemonSqueezy API Response

private struct LemonSqueezyResponse: Codable {
    let valid: Bool
    let activated: Bool
    let deactivated: Bool
    let error: String?
    let meta: LemonSqueezyMeta?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        valid = (try? container.decode(Bool.self, forKey: .valid)) ?? false
        activated = (try? container.decode(Bool.self, forKey: .activated)) ?? false
        deactivated = (try? container.decode(Bool.self, forKey: .deactivated)) ?? false
        error = try? container.decode(String.self, forKey: .error)
        meta = try? container.decode(LemonSqueezyMeta.self, forKey: .meta)
    }
}

private struct LemonSqueezyMeta: Codable {
    let customerName: String?

    enum CodingKeys: String, CodingKey {
        case customerName = "customer_name"
    }
}
