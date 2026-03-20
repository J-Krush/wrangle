import Foundation
import IOKit
import Security

@MainActor
@Observable
class LicenseManager {
    var licenseKey: String = ""
    var licenseStatus: LicenseStatus = .unlicensed
    var statusMessage: String = ""
    var isValidating: Bool = false
    var customerName: String = ""
    var trialExpiresAt: Date?
    var trialEmail: String = ""
    var trialExpired: Bool = false

    var isInTrial: Bool {
        licenseStatus == .trial && !isTrialExpired
    }

    var trialDaysRemaining: Int {
        guard let expiresAt = trialExpiresAt else { return 0 }
        let remaining = expiresAt.timeIntervalSinceNow
        if remaining <= 0 { return 0 }
        return Int(ceil(remaining / 86400))
    }

    private var isTrialExpired: Bool {
        guard let expiresAt = trialExpiresAt else { return true }
        return expiresAt <= Date()
    }

    enum LicenseStatus: String {
        case unlicensed
        case valid
        case invalid
        case expired
        case trial
    }

    private static let instanceIDKey = "LicenseManager.instanceID"
    private static let keychainService = "dev.wrangle.license"
    private static let keychainAccount = "license-key"
    private static let devBypassKey = "WRANGLE-DEV-PREVIEW"
    private static let trialKeychainService = "dev.wrangle.trial"
    private static let trialKeychainAccount = "trial-data"
    private static let trialActivateURL = "https://wrangleapp.dev/api/trial/activate"
    private static let trialValidateURL = "https://wrangleapp.dev/api/trial/validate"

    // Replace with your actual LemonSqueezy store/product IDs
    private static let activateURL = "https://api.lemonsqueezy.com/v1/licenses/activate"
    private static let validateURL = "https://api.lemonsqueezy.com/v1/licenses/validate"
    private static let deactivateURL = "https://api.lemonsqueezy.com/v1/licenses/deactivate"

    var hardwareUUID: String {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        guard let uuid = IORegistryEntryCreateCFProperty(service, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String else {
            return UUID().uuidString
        }
        return uuid
    }

    var instanceID: String {
        if let existing = UserDefaults.standard.string(forKey: Self.instanceIDKey) {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: Self.instanceIDKey)
        return id
    }

    var isLicensed: Bool {
        return licenseStatus == .valid || licenseStatus == .trial
    }

    var needsLicense: Bool {
        !isLicensed
    }

    // MARK: - Lifecycle

    func loadOnLaunch() {
        if let storedKey = loadKeyFromKeychain() {
            licenseKey = storedKey
            licenseStatus = .valid
            Task { await validate() }
        } else if let trialData = loadTrialFromKeychain() {
            trialEmail = trialData.email
            trialExpiresAt = trialData.expiresAt
            if !isTrialExpired {
                licenseStatus = .trial
            }
            Task { await validateTrial() }
        } else {
            licenseStatus = .unlicensed
        }
    }

    // MARK: - License Actions

    func activate() async {
        let trimmedKey = licenseKey.trimmingCharacters(in: .whitespaces)
        guard !trimmedKey.isEmpty else {
            statusMessage = "Please enter a license key."
            return
        }

        // Dev bypass — no API call needed
        if trimmedKey == Self.devBypassKey {
            licenseStatus = .valid
            customerName = "Developer Preview"
            statusMessage = "Developer access granted."
            saveKeyToKeychain(trimmedKey)
            return
        }

        isValidating = true
        statusMessage = ""

        do {
            var request = URLRequest(url: URL(string: Self.activateURL)!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let instanceName = ProcessInfo.processInfo.hostName
            let encodedKey = trimmedKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedKey
            let encodedName = instanceName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? instanceName
            let body = "license_key=\(encodedKey)&instance_name=\(encodedName)"
            request.httpBody = body.data(using: .utf8)

            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            let httpResponse = urlResponse as? HTTPURLResponse

            #if DEBUG
            print("[License] Activate HTTP \(httpResponse?.statusCode ?? -1): \(String(data: data, encoding: .utf8) ?? "no body")")
            #endif

            guard let statusCode = httpResponse?.statusCode, (200...299).contains(statusCode) else {
                // Non-2xx — try to decode error from response body
                if let errorResponse = try? JSONDecoder().decode(LemonSqueezyResponse.self, from: data),
                   let errorMessage = errorResponse.error {
                    statusMessage = errorMessage
                } else {
                    statusMessage = "License server returned an error (HTTP \(httpResponse?.statusCode ?? 0))."
                }
                licenseStatus = .invalid
                isValidating = false
                return
            }

            let response = try JSONDecoder().decode(LemonSqueezyResponse.self, from: data)

            if response.activated || response.valid {
                licenseStatus = .valid
                customerName = response.meta?.customerName ?? ""
                statusMessage = "License activated successfully."
                saveKeyToKeychain(trimmedKey)
            } else {
                licenseStatus = .invalid
                statusMessage = response.error ?? "Activation failed. Please check your license key."
            }
        } catch is URLError {
            statusMessage = "Could not reach license server. Please check your connection."
        } catch is DecodingError {
            statusMessage = "Unexpected response from license server."
        } catch {
            statusMessage = "Activation failed: \(error.localizedDescription)"
        }

        isValidating = false
    }

    func validate() async {
        guard !licenseKey.isEmpty else { return }

        if licenseKey == Self.devBypassKey {
            licenseStatus = .valid
            customerName = "Developer Preview"
            return
        }

        isValidating = true

        do {
            var request = URLRequest(url: URL(string: Self.validateURL)!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let encodedKey = licenseKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? licenseKey
            let encodedID = instanceID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? instanceID
            let body = "license_key=\(encodedKey)&instance_id=\(encodedID)"
            request.httpBody = body.data(using: .utf8)

            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            let httpResponse = urlResponse as? HTTPURLResponse

            #if DEBUG
            print("[License] Validate HTTP \(httpResponse?.statusCode ?? -1): \(String(data: data, encoding: .utf8) ?? "no body")")
            #endif

            guard let statusCode = httpResponse?.statusCode, (200...299).contains(statusCode) else {
                if licenseStatus != .valid {
                    statusMessage = "License server returned an error (HTTP \(httpResponse?.statusCode ?? 0))."
                }
                isValidating = false
                return
            }

            let response = try JSONDecoder().decode(LemonSqueezyResponse.self, from: data)

            if response.valid {
                licenseStatus = .valid
                customerName = response.meta?.customerName ?? ""
            } else {
                licenseStatus = .invalid
                statusMessage = response.error ?? "License is no longer valid."
            }
        } catch is URLError {
            if licenseStatus != .valid {
                statusMessage = "Could not verify license. Please check your connection."
            }
        } catch is DecodingError {
            if licenseStatus != .valid {
                statusMessage = "Unexpected response from license server."
            }
        } catch {
            if licenseStatus != .valid {
                statusMessage = "Could not verify license: \(error.localizedDescription)"
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

            let encodedKey = licenseKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? licenseKey
            let encodedID = instanceID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? instanceID
            let body = "license_key=\(encodedKey)&instance_id=\(encodedID)"
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
        licenseStatus = .unlicensed
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

    // MARK: - Trial

    func activateTrial(email: String) async {
        isValidating = true
        statusMessage = ""

        do {
            var request = URLRequest(url: URL(string: Self.trialActivateURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["email": email, "hardware_id": hardwareUUID]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as! HTTPURLResponse

            if httpResponse.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                let expiresAtString = json["expires_at"] as! String
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let expiresAt = formatter.date(from: expiresAtString) {
                    trialExpiresAt = expiresAt
                    trialEmail = email
                    trialExpired = false
                    licenseStatus = .trial
                    saveTrialToKeychain(email: email, expiresAt: expiresAt)
                    statusMessage = ""
                }
            } else if httpResponse.statusCode == 409 {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                statusMessage = json?["error"] as? String ?? "A trial has already been activated with this email or machine."
            } else {
                #if DEBUG
                let bodyString = String(data: data, encoding: .utf8) ?? "no body"
                print("[Trial] Activation failed — HTTP \(httpResponse.statusCode): \(bodyString)")
                #endif
                statusMessage = "Could not start trial. Please try again."
            }
        } catch let urlError as URLError {
            #if DEBUG
            print("[Trial] Activation network error: \(urlError)")
            #endif
            statusMessage = "Could not reach server. Please check your connection."
        } catch {
            #if DEBUG
            print("[Trial] Activation error: \(error)")
            #endif
            statusMessage = "Trial activation failed: \(error.localizedDescription)"
        }

        isValidating = false
    }

    func validateTrial() async {
        isValidating = true

        do {
            var request = URLRequest(url: URL(string: Self.trialValidateURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["hardware_id": hardwareUUID]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as! HTTPURLResponse

            if httpResponse.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                if let active = json["active"] as? Bool, active {
                    if let expiresAtString = json["expires_at"] as? String {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        if let expiresAt = formatter.date(from: expiresAtString) {
                            trialExpiresAt = expiresAt
                        }
                    }
                    licenseStatus = .trial
                    trialExpired = false
                } else {
                    licenseStatus = .unlicensed
                    trialExpired = true
                }
            } else {
                // Server unreachable or 404 — fall back to local expiry
                if isTrialExpired {
                    licenseStatus = .unlicensed
                    trialExpired = true
                } else {
                    licenseStatus = .trial
                    trialExpired = false
                }
            }
        } catch {
            // Network error — fall back to local expiry
            if isTrialExpired {
                licenseStatus = .unlicensed
                trialExpired = true
            } else {
                licenseStatus = .trial
                trialExpired = false
            }
        }

        isValidating = false
    }

    // MARK: - Trial Keychain

    private struct TrialData: Codable {
        let email: String
        let expiresAt: Date
        let hardwareID: String

        enum CodingKeys: String, CodingKey {
            case email
            case expiresAt = "expires_at"
            case hardwareID = "hardware_id"
        }
    }

    private func saveTrialToKeychain(email: String, expiresAt: Date) {
        removeTrialFromKeychain()

        let trialData = TrialData(email: email, expiresAt: expiresAt, hardwareID: hardwareUUID)
        guard let data = try? JSONEncoder().encode(trialData) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.trialKeychainService,
            kSecAttrAccount as String: Self.trialKeychainAccount,
            kSecValueData as String: data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadTrialFromKeychain() -> (email: String, expiresAt: Date)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.trialKeychainService,
            kSecAttrAccount as String: Self.trialKeychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data,
              let trialData = try? JSONDecoder().decode(TrialData.self, from: data) else {
            return nil
        }
        return (email: trialData.email, expiresAt: trialData.expiresAt)
    }

    private func removeTrialFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.trialKeychainService,
            kSecAttrAccount as String: Self.trialKeychainAccount,
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
