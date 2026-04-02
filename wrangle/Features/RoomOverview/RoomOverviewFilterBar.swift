import SwiftUI
import SwiftData

struct RoomOverviewFilterBar: View {
    let items: [RoomSessionItem]
    let bookmarks: [BookmarkedDirectory]
    let intents: [Intent]
    @Binding var activeFilter: RoomOverviewFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Type filters
                chipButton("All", filter: .all)

                if items.contains(where: { $0.sessionType.isAgent }) {
                    chipButton("Agents", filter: .agents)
                }
                if items.contains(where: { $0.sessionType == .terminal }) {
                    chipButton("Terminals", filter: .terminals)
                }
                if items.contains(where: { $0.sessionType == .browser }) {
                    chipButton("Browsers", filter: .browsers)
                }

                // Location filters (only if >1 location has sessions)
                let activeLocationIDs = Set(items.compactMap(\.locationID))
                if activeLocationIDs.count > 1 {
                    Divider()
                        .frame(height: 16)
                    ForEach(bookmarks.filter({ activeLocationIDs.contains($0.persistentModelID.hashValue.description) }), id: \.persistentModelID) { bookmark in
                        let bookmarkID = bookmark.persistentModelID.hashValue.description
                        chipButton(bookmark.displayName, filter: .location(bookmarkID))
                    }
                }

                // Intent filters
                let activeIntentIDs = Set(items.compactMap(\.intentID))
                let matchingIntents = intents.filter { activeIntentIDs.contains($0.id) }
                if !matchingIntents.isEmpty {
                    Divider()
                        .frame(height: 16)
                    ForEach(matchingIntents, id: \.id) { intent in
                        chipButton(intent.name, filter: .intent(intent.id))
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private func chipButton(_ label: String, filter: RoomOverviewFilter) -> some View {
        Button {
            activeFilter = filter
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(activeFilter == filter ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(activeFilter == filter
                              ? Color.accentColor.opacity(0.2)
                              : Color(nsColor: Theme.sidebarBackground).opacity(0.6))
                }
                .foregroundStyle(activeFilter == filter ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}
