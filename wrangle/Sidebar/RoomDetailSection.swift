import SwiftUI
import SwiftData

struct RoomDetailSection: View {
    let roomID: String
    let scrollProxy: ScrollViewProxy
    let filterText: String
    let activeFileTypeFilters: Set<FileTypeFilter>
    let isFinderDragActive: Bool
    let showActiveSessionsOnly: Bool
    var onAddLocation: (() -> Void)?

    @Environment(AppState.self) private var appState
    @Query private var rooms: [Room]

    private var room: Room? {
        rooms.first { $0.id == roomID }
    }

    var body: some View {
        Section {
            Button {
                appState.selectedRoomID = nil
                appState.activeIntentID = nil
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Rooms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
        }

        if let room {
            Section {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: room.colorHex) ?? .blue)
                        .frame(width: 10, height: 10)
                    Text(room.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                .listRowBackground(Color.clear)
            }
        }

        Section("Intents") {
            IntentListView(roomID: roomID)
        }

        Section("Locations") {
            RoomBookmarkListView(
                roomID: roomID,
                scrollProxy: scrollProxy,
                filterText: filterText,
                activeFileTypeFilters: activeFileTypeFilters,
                isFinderDragActive: isFinderDragActive,
                showActiveSessionsOnly: showActiveSessionsOnly,
                onAddLocation: onAddLocation
            )
        }
    }
}
