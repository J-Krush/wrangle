//
//  CookieManagerView.swift
//  Wrangle
//

import SwiftUI

struct CookieManagerView: View {
    let session: BrowserSession
    @State private var cookies: [HTTPCookie] = []
    @State private var filterText: String = ""
    @State private var sortKey: SortKey = .name
    @State private var sortAscending: Bool = true
    @State private var showAddSheet: Bool = false

    enum SortKey: String {
        case name, domain, path, expires
    }

    private var filteredCookies: [HTTPCookie] {
        var result = cookies
        if !filterText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(filterText) ||
                $0.domain.localizedCaseInsensitiveContains(filterText) ||
                $0.value.localizedCaseInsensitiveContains(filterText)
            }
        }
        result.sort { a, b in
            let cmp: Bool
            switch sortKey {
            case .name: cmp = a.name.localizedCompare(b.name) == .orderedAscending
            case .domain: cmp = a.domain.localizedCompare(b.domain) == .orderedAscending
            case .path: cmp = a.path.localizedCompare(b.path) == .orderedAscending
            case .expires:
                let aDate = a.expiresDate ?? Date.distantFuture
                let bDate = b.expiresDate ?? Date.distantFuture
                cmp = aDate < bDate
            }
            return sortAscending ? cmp : !cmp
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                TextField("Filter by name or domain", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))

                Button {
                    refreshCookies()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh")

                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Add Cookie")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Header
            HStack(spacing: 0) {
                sortableHeader("Name", key: .name, width: 120)
                sortableHeader("Value", key: .name, width: 150)
                sortableHeader("Domain", key: .domain, width: 120)
                sortableHeader("Path", key: .path, width: 60)
                sortableHeader("Expires", key: .expires, width: 100)
                Text("Secure")
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 50)
                Text("HttpOnly")
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 60)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(nsColor: Theme.chromeBackground))

            Divider()

            // Cookie rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredCookies.enumerated()), id: \.element.name) { _, cookie in
                        CookieRow(cookie: cookie) {
                            deleteCookie(cookie)
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: Theme.sidebarBackground))
        .onAppear { refreshCookies() }
        .sheet(isPresented: $showAddSheet) {
            AddCookieSheet(session: session) {
                refreshCookies()
            }
        }
    }

    private func sortableHeader(_ title: String, key: SortKey, width: CGFloat) -> some View {
        Button {
            if sortKey == key {
                sortAscending.toggle()
            } else {
                sortKey = key
                sortAscending = true
            }
        } label: {
            HStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                if sortKey == key {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                }
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func refreshCookies() {
        Task {
            if let controller = session.controller {
                cookies = await controller.getCookies()
            }
        }
    }

    private func deleteCookie(_ cookie: HTTPCookie) {
        Task {
            await session.controller?.deleteCookie(cookie)
            refreshCookies()
        }
    }
}

// MARK: - Cookie Row

private struct CookieRow: View {
    let cookie: HTTPCookie
    let onDelete: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            Text(cookie.name)
                .frame(width: 120, alignment: .leading)
            Text(cookie.value)
                .frame(width: 150, alignment: .leading)
                .lineLimit(1)
            Text(cookie.domain)
                .frame(width: 120, alignment: .leading)
            Text(cookie.path)
                .frame(width: 60, alignment: .leading)
            Text(cookie.expiresDate.map { Self.dateFormatter.string(from: $0) } ?? "Session")
                .frame(width: 100, alignment: .leading)
            Text(cookie.isSecure ? "Yes" : "")
                .frame(width: 50)
            Text(cookie.isHTTPOnly ? "Yes" : "")
                .frame(width: 60)

            Spacer()

            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(isHovering ? Color.white.opacity(0.03) : Color.clear)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Add Cookie Sheet

private struct AddCookieSheet: View {
    let session: BrowserSession
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var value = ""
    @State private var domain = ""
    @State private var path = "/"
    @State private var isSecure = false
    @State private var isHTTPOnly = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Add Cookie")
                .font(.headline)

            Form {
                TextField("Name:", text: $name)
                TextField("Value:", text: $value)
                TextField("Domain:", text: $domain)
                TextField("Path:", text: $path)
                Toggle("Secure", isOn: $isSecure)
                Toggle("HttpOnly", isOn: $isHTTPOnly)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    addCookie()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || domain.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
        .onAppear {
            // Pre-fill domain from current URL
            if let host = session.activeTab?.url?.host() {
                domain = host
            }
        }
    }

    private func addCookie() {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
        ]
        if isSecure { properties[.secure] = "TRUE" }

        guard let cookie = HTTPCookie(properties: properties) else { return }
        Task {
            await session.controller?.setCookie(cookie)
            onDone()
            dismiss()
        }
    }
}
