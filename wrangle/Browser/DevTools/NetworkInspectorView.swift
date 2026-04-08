//
//  NetworkInspectorView.swift
//  Wrangle
//

import SwiftUI

// MARK: - Network Request Model

@MainActor
@Observable
class NetworkRequest: Identifiable {
    let id: String
    let method: String
    let url: String
    var status: Int?
    var statusText: String?
    var duration: Double?
    var error: String?
    var isComplete: Bool = false
    let timestamp: Date = Date()

    init(id: String, method: String, url: String) {
        self.id = id
        self.method = method
        self.url = url
    }

    var displayURL: String {
        guard let urlObj = URL(string: url) else { return url }
        return urlObj.path(percentEncoded: false)
    }

    var statusColor: Color {
        guard let status else { return .secondary }
        switch status {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500...: return .red
        default: return .secondary
        }
    }
}

// MARK: - Network Inspector View

struct NetworkInspectorView: View {
    let session: BrowserSession
    @State private var requests: [NetworkRequest] = []
    @State private var filterText: String = ""
    @State private var selectedRequestID: String?

    private var filteredRequests: [NetworkRequest] {
        if filterText.isEmpty { return requests }
        return requests.filter {
            $0.url.localizedCaseInsensitiveContains(filterText) ||
            $0.method.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                TextField("Filter URLs", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))

                Text("\(requests.count) requests")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Button {
                    requests.removeAll()
                    selectedRequestID = nil
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Header
            HStack(spacing: 0) {
                Text("Method")
                    .frame(width: 50, alignment: .leading)
                Text("URL")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Status")
                    .frame(width: 50, alignment: .trailing)
                Text("Time")
                    .frame(width: 70, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(nsColor: Theme.chromeBackground))

            Divider()

            // Request rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredRequests) { request in
                        NetworkRequestRow(
                            request: request,
                            isSelected: selectedRequestID == request.id
                        )
                        .onTapGesture {
                            selectedRequestID = selectedRequestID == request.id ? nil : request.id
                        }
                    }
                }
            }

            // Detail panel for selected request
            if let selected = requests.first(where: { $0.id == selectedRequestID }) {
                Divider()
                NetworkRequestDetail(request: selected)
                    .frame(height: 80)
            }
        }
        .background(Color(nsColor: Theme.sidebarBackground))
        .onReceive(NotificationCenter.default.publisher(for: .browserNetworkEvent)) { notification in
            handleNetworkEvent(notification.userInfo as? [String: Any] ?? [:])
        }
    }

    private func handleNetworkEvent(_ body: [String: Any]) {
        guard let type = body["type"] as? String,
              let id = body["id"] as? String else { return }

        switch type {
        case "start":
            let method = body["method"] as? String ?? "GET"
            let url = body["url"] as? String ?? ""
            let request = NetworkRequest(id: id, method: method, url: url)
            requests.append(request)

        case "end":
            if let request = requests.first(where: { $0.id == id }) {
                request.status = body["status"] as? Int
                request.statusText = body["statusText"] as? String
                request.duration = body["duration"] as? Double
                request.isComplete = true
            }

        case "error":
            if let request = requests.first(where: { $0.id == id }) {
                request.error = body["error"] as? String
                request.isComplete = true
            }

        default:
            break
        }
    }
}

// MARK: - Request Row

private struct NetworkRequestRow: View {
    let request: NetworkRequest
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(request.method)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Text(request.displayURL)
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let error = request.error {
                Text("ERR")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.red)
                    .frame(width: 50, alignment: .trailing)
                    .help(error)
            } else if let status = request.status {
                Text("\(status)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(request.statusColor)
                    .frame(width: 50, alignment: .trailing)
            } else {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.5)
                    .frame(width: 50, alignment: .trailing)
            }

            if let duration = request.duration {
                Text(formatDuration(duration))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 70, alignment: .trailing)
            } else {
                Text("...")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }

    private func formatDuration(_ ms: Double) -> String {
        if ms < 1000 {
            return "\(Int(ms))ms"
        }
        return String(format: "%.1fs", ms / 1000)
    }
}

// MARK: - Request Detail

private struct NetworkRequestDetail: View {
    let request: NetworkRequest

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                detailRow("URL", request.url)
                detailRow("Method", request.method)
                if let status = request.status {
                    detailRow("Status", "\(status) \(request.statusText ?? "")")
                }
                if let duration = request.duration {
                    detailRow("Duration", "\(Int(duration))ms")
                }
                if let error = request.error {
                    detailRow("Error", error)
                }
            }
            .padding(8)
        }
        .background(Color(nsColor: Theme.chromeBackground).opacity(0.5))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
