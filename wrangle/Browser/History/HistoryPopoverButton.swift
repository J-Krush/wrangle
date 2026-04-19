//
//  HistoryPopoverButton.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

struct HistoryPopoverButton: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var showPopover: Bool = false

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Browsing History")
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            HistoryPopoverContent(onOpen: { url in
                showPopover = false
                navigate(to: url)
            })
            .frame(width: 420, height: 360)
        }
    }

    private func navigate(to url: URL) {
        if let session = appState.activeTab?.browserSession {
            session.activeTab?.pendingNavigation = .load(url)
        } else {
            appState.openBrowser(url: url)
        }
    }
}

private struct HistoryPopoverContent: View {
    let onOpen: (URL) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrowsingHistoryEntry.dateVisited, order: .reverse) private var entries: [BrowsingHistoryEntry]
    @State private var filter: String = ""

    private var filtered: [BrowsingHistoryEntry] {
        guard !filter.isEmpty else { return entries }
        let lower = filter.lowercased()
        return entries.filter {
            $0.urlString.lowercased().contains(lower) || $0.title.lowercased().contains(lower)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                Text("History")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                TextField("Filter", text: $filter)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .frame(maxWidth: 180)
                Menu {
                    Button("Clear Last Hour") { clear(.lastHour) }
                    Button("Clear Last Day") { clear(.lastDay) }
                    Button("Clear Last Week") { clear(.lastWeek) }
                    Divider()
                    Button("Clear All History", role: .destructive) { clear(.allTime) }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Clear...")
            }
            .padding(10)
            Divider()

            if filtered.isEmpty {
                Spacer()
                Text(filter.isEmpty ? "No history yet" : "No matches")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupings, id: \.label) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    HistoryPopoverRow(entry: entry, onOpen: onOpen)
                                    Divider().padding(.leading, 30)
                                }
                            } header: {
                                Text(group.label)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(nsColor: Theme.chromeBackground).opacity(0.6))
                            }
                        }
                    }
                }
            }
        }
    }

    private struct Group {
        let label: String
        let entries: [BrowsingHistoryEntry]
    }

    private var groupings: [Group] {
        let now = Date.now
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        let startOfYesterday = cal.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        let startOfWeek = cal.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday

        var today: [BrowsingHistoryEntry] = []
        var yesterday: [BrowsingHistoryEntry] = []
        var week: [BrowsingHistoryEntry] = []
        var older: [BrowsingHistoryEntry] = []

        for entry in filtered {
            if entry.dateVisited >= startOfToday { today.append(entry) }
            else if entry.dateVisited >= startOfYesterday { yesterday.append(entry) }
            else if entry.dateVisited >= startOfWeek { week.append(entry) }
            else { older.append(entry) }
        }

        var groups: [Group] = []
        if !today.isEmpty { groups.append(Group(label: "Today", entries: today)) }
        if !yesterday.isEmpty { groups.append(Group(label: "Yesterday", entries: yesterday)) }
        if !week.isEmpty { groups.append(Group(label: "Past Week", entries: week)) }
        if !older.isEmpty { groups.append(Group(label: "Older", entries: older)) }
        return groups
    }

    private func clear(_ range: HistoryStore.ClearRange) {
        let store = HistoryStore(context: modelContext)
        store.clear(range)
    }
}

private struct HistoryPopoverRow: View {
    let entry: BrowsingHistoryEntry
    let onOpen: (URL) -> Void
    @Environment(\.modelContext) private var modelContext

    private var favicon: NSImage? {
        guard let data = entry.faviconData else { return nil }
        return NSImage(data: data)
    }

    var body: some View {
        Button {
            if let url = entry.url { onOpen(url) }
        } label: {
            HStack(spacing: 8) {
                if let favicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.title)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Text(entry.urlString)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(formatted(entry.dateVisited))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.urlString, forType: .string)
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                try? modelContext.save()
            }
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
}
