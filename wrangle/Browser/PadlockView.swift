//
//  PadlockView.swift
//  Wrangle
//

import SwiftUI
import Security

struct PadlockView: View {
    let session: BrowserSession
    @State private var showDetails: Bool = false

    private var state: SecurityState {
        session.activeTab?.securityState ?? .unknown
    }

    var body: some View {
        Button {
            showDetails.toggle()
        } label: {
            Image(systemName: state.systemImage)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(state.shortDescription)
        .popover(isPresented: $showDetails, arrowEdge: .bottom) {
            CertificateDetailsView(tab: session.activeTab)
                .frame(minWidth: 320)
        }
    }

    private var color: Color {
        switch state {
        case .secure: return Color.green
        case .insecure: return Color.orange
        case .invalid: return Color.red
        case .fileLocal, .unknown: return Color.secondary
        }
    }
}

// MARK: - Certificate Details Popover

private struct CertificateDetailsView: View {
    let tab: BrowserTab?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: tab?.securityState.systemImage ?? "globe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab?.securityState.shortDescription ?? "Unknown")
                        .font(.system(size: 13, weight: .semibold))
                    if let host = tab?.url?.host() {
                        Text(host)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            if let trust = tab?.serverTrust, let info = CertInfo.extract(from: trust) {
                detailRow("Subject", info.subject)
                detailRow("Issuer", info.issuer)
                if let validFrom = info.validFrom {
                    detailRow("Valid From", formatted(validFrom))
                }
                if let validTo = info.validTo {
                    detailRow("Valid Until", formatted(validTo))
                }
            } else if tab?.securityState == .insecure {
                Text("This connection is not encrypted.\nInformation you send can be read by others.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No certificate information available.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private var iconColor: Color {
        switch tab?.securityState {
        case .secure: return .green
        case .insecure: return .orange
        case .invalid: return .red
        default: return .secondary
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Certificate Info Extraction

struct CertInfo {
    let subject: String
    let issuer: String
    let validFrom: Date?
    let validTo: Date?

    static func extract(from trust: SecTrust) -> CertInfo? {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = chain.first else { return nil }

        // Subject (common name)
        let subject: String = {
            var cn: CFString?
            SecCertificateCopyCommonName(leaf, &cn)
            if let cn = cn as String? { return cn }
            return SecCertificateCopySubjectSummary(leaf) as String? ?? "Unknown"
        }()

        // Issuer + validity dates via CopyValues
        let keys: [CFString] = [
            kSecOIDX509V1IssuerName,
            kSecOIDX509V1ValidityNotBefore,
            kSecOIDX509V1ValidityNotAfter,
        ]
        let values = SecCertificateCopyValues(leaf, keys as CFArray, nil) as? [CFString: Any]

        let issuer = issuerString(from: values) ?? "Unknown"
        let validFrom = absoluteTimeValue(values, key: kSecOIDX509V1ValidityNotBefore)
        let validTo = absoluteTimeValue(values, key: kSecOIDX509V1ValidityNotAfter)

        return CertInfo(subject: subject, issuer: issuer, validFrom: validFrom, validTo: validTo)
    }

    private static func issuerString(from values: [CFString: Any]?) -> String? {
        guard let dict = values?[kSecOIDX509V1IssuerName] as? [CFString: Any],
              let rows = dict[kSecPropertyKeyValue] as? [[CFString: Any]] else { return nil }
        // Prefer Common Name (2.5.4.3) in the issuer RDN sequence.
        for row in rows {
            if let label = row[kSecPropertyKeyLabel] as? String,
               label == "2.5.4.3",
               let value = row[kSecPropertyKeyValue] as? String {
                return value
            }
        }
        // Fallback: Organization (2.5.4.10)
        for row in rows {
            if let label = row[kSecPropertyKeyLabel] as? String,
               label == "2.5.4.10",
               let value = row[kSecPropertyKeyValue] as? String {
                return value
            }
        }
        return nil
    }

    private static func absoluteTimeValue(_ values: [CFString: Any]?, key: CFString) -> Date? {
        guard let dict = values?[key] as? [CFString: Any],
              let value = dict[kSecPropertyKeyValue] else { return nil }
        // Value is stored as CFNumber representing CFAbsoluteTime (seconds since 2001-01-01).
        if let number = value as? Double {
            return Date(timeIntervalSinceReferenceDate: number)
        }
        if let number = value as? NSNumber {
            return Date(timeIntervalSinceReferenceDate: number.doubleValue)
        }
        return nil
    }
}
