//
//  HistoryView.swift
//  Wrangle
//

import SwiftUI
import SwiftData
import AppKit

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \BrowsingHistoryEntry.dateVisited, order: .reverse) private var entries: [BrowsingHistoryEntry]
    @State private var filter: String = ""
    @State private var showClearMenu: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            list
        }
        .frame(minWidth: 560, minHeight: 400)
    }

    private var filtered: [BrowsingHistoryEntry] {
        guard !filter.isEmpty else { return entries }
        let lower = filter.lowercased()
        return entries.filter {
            $0.urlString.lowercased().contains(lower) || $0.title.lowercased().contains(lower)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
            Text("History")
                .font(.title3.bold())
            Spacer()
            TextField("Search history", text: $filter)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)

            Menu {
                Button("Clear Last Hour") { clear(.lastHour) }
                Button("Clear Last Day") { clear(.lastDay) }
                Button("Clear Last Week") { clear(.lastWeek) }
                Divider()
                Button("Clear All History", role: .destructive) { clear(.allTime) }
            } label: {
                Label("Clear...", systemImage: "trash")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(12)
    }

    @ViewBuilder
    private var list: some View {
        if filtered.isEmpty {
            VStack {
                Spacer()
                Text(filter.isEmpty ? "No history yet" : "No matches")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupings, id: \.label) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                HistoryRow(entry: entry)
                                Divider().padding(.leading, 28)
                            }
                        } header: {
                            Text(group.label)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: Theme.chromeBackground))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Grouping

    private struct Group {
        let label: String
        let entries: [BrowsingHistoryEntry]
    }

    private var groupings: [Group] {
        let now = Date.now
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday

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

// MARK: - Row

private struct HistoryRow: View {
    let entry: BrowsingHistoryEntry
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var favicon: NSImage? {
        guard let data = entry.faviconData else { return nil }
        return NSImage(data: data)
    }

    var body: some View {
        Button {
            openInNew()
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
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Text(entry.urlString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(formatted(entry.dateVisited))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open in New Tab") { openInNew() }
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.urlString, forType: .string)
            }
            Divider()
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                try? modelContext.save()
            }
        }
    }

    private func openInNew() {
        guard let url = entry.url else { return }
        if let session = appState.activeTab?.browserSession {
            session.addTab(url: url)
        } else {
            appState.openBrowser(url: url)
        }
        dismiss()
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        if !Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .short
        }
        return formatter.string(from: date)
    }
}
