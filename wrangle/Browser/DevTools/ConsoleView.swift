//
//  ConsoleView.swift
//  Wrangle
//

import SwiftUI

struct ConsoleView: View {
    let session: BrowserSession
    @State private var filterText: String = ""
    @State private var jsInput: String = ""
    @State private var showTimestamps: Bool = false

    private var messages: [ConsoleMessage] {
        guard let tab = session.activeTab else { return [] }
        if filterText.isEmpty { return tab.consoleMessages }
        return tab.consoleMessages.filter { $0.text.localizedCaseInsensitiveContains(filterText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                TextField("Filter", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))

                Button {
                    showTimestamps.toggle()
                } label: {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(showTimestamps ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle Timestamps")

                Button {
                    session.activeTab?.clearConsole()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear Console")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(messages) { message in
                            ConsoleMessageRow(message: message, showTimestamp: showTimestamps)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .onChange(of: session.activeTab?.consoleMessages.count) { _, _ in
                    if let lastID = messages.last?.id {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            Divider()

            // JS input
            HStack(spacing: 4) {
                Text(">")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.blue)

                TextField("Evaluate JavaScript...", text: $jsInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .onSubmit {
                        evaluateJS()
                    }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(nsColor: Theme.sidebarBackground))
    }

    private func evaluateJS() {
        let script = jsInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !script.isEmpty, let tab = session.activeTab else { return }
        jsInput = ""

        // Show the input as a log message
        tab.consoleMessages.append(ConsoleMessage(level: .info, text: "> \(script)", timestamp: Date()))

        Task {
            do {
                let result = try await session.controller?.evaluateJavaScript(script, in: tab)
                let resultStr = result.map { String(describing: $0) } ?? "undefined"
                tab.consoleMessages.append(ConsoleMessage(level: .log, text: resultStr, timestamp: Date()))
            } catch {
                tab.consoleMessages.append(ConsoleMessage(level: .error, text: error.localizedDescription, timestamp: Date()))
            }
        }
    }
}

// MARK: - Console Message Row

private struct ConsoleMessageRow: View {
    let message: ConsoleMessage
    let showTimestamp: Bool

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if showTimestamp {
                Text(Self.timeFormatter.string(from: message.timestamp))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 80, alignment: .leading)
            }

            Image(systemName: iconName)
                .font(.system(size: 9))
                .foregroundStyle(iconColor)
                .frame(width: 12)

            Text(message.text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(textColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(backgroundColor)
    }

    private var iconName: String {
        switch message.level {
        case .log: "circle.fill"
        case .warn: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch message.level {
        case .log: .secondary
        case .warn: .yellow
        case .error: .red
        case .info: .blue
        }
    }

    private var textColor: Color {
        switch message.level {
        case .log: .primary
        case .warn: .yellow
        case .error: .red
        case .info: .blue
        }
    }

    private var backgroundColor: Color {
        switch message.level {
        case .warn: .yellow.opacity(0.05)
        case .error: .red.opacity(0.05)
        default: .clear
        }
    }
}
