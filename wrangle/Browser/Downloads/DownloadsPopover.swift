//
//  DownloadsPopover.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

struct DownloadsPopoverButton: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrowserDownloadRecord.dateStarted, order: .reverse)
    private var records: [BrowserDownloadRecord]
    @State private var showPopover: Bool = false

    private var activeCount: Int {
        records.filter { $0.state == .inProgress }.count
    }

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(activeCount > 0 ? Color.accentColor : .secondary)
                if activeCount > 0 {
                    Text("\(activeCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Color.accentColor, in: Capsule())
                        .offset(x: 6, y: -6)
                }
            }
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Downloads")
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            DownloadsPopoverContent(records: records)
                .frame(minWidth: 360, idealWidth: 420, minHeight: 200, idealHeight: 340)
        }
    }
}

private struct DownloadsPopoverContent: View {
    let records: [BrowserDownloadRecord]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Downloads")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)
            Divider()

            if records.isEmpty {
                Spacer()
                Text("No downloads yet")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(records, id: \.id) { record in
                            DownloadRow(record: record)
                            Divider().padding(.leading, 14)
                        }
                    }
                }
            }
        }
    }
}

private struct DownloadRow: View {
    let record: BrowserDownloadRecord
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.filename)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                if record.state == .inProgress {
                    ProgressView(value: record.progress)
                        .progressViewStyle(.linear)
                }
            }

            Spacer()

            actionButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var iconName: String {
        switch record.state {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "arrow.down.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .incomplete: return "questionmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch record.state {
        case .completed: return .green
        case .inProgress: return .blue
        case .cancelled: return .secondary
        case .failed: return .red
        case .incomplete: return .orange
        }
    }

    private var subtitle: String {
        switch record.state {
        case .inProgress:
            let received = ByteCountFormatter.string(fromByteCount: record.bytesReceived, countStyle: .file)
            if record.bytesExpected > 0 {
                let total = ByteCountFormatter.string(fromByteCount: record.bytesExpected, countStyle: .file)
                return "\(received) of \(total)"
            }
            return received
        case .completed:
            let total = ByteCountFormatter.string(fromByteCount: record.bytesReceived, countStyle: .file)
            return "\(total) — \(record.dateCompleted.map(formatted) ?? "")"
        case .cancelled:
            return "Cancelled"
        case .failed:
            return record.errorDescription ?? "Failed"
        case .incomplete:
            return "Incomplete after relaunch"
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        if !Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .short
        }
        return formatter.string(from: date)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch record.state {
        case .inProgress:
            Button("Cancel") {
                DownloadManager.shared.cancel(record)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .font(.system(size: 11))
        case .completed:
            Menu {
                Button("Show in Finder") { showInFinder() }
                Button("Open") { openFile() }
                Divider()
                Button("Remove from List", role: .destructive) { remove() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        default:
            Button {
                remove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func showInFinder() {
        guard let url = record.destinationURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func openFile() {
        guard let url = record.destinationURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func remove() {
        DownloadManager.shared.remove(record)
    }
}
