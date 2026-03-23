import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RoomListSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Room.displayOrder) private var rooms: [Room]
    @Query private var intents: [Intent]
    @State private var renamingRoom: Room?
    @State private var renameText = ""
    @State private var draggingRoomID: String?
    @State private var dropTargetRoomID: String?

    var body: some View {
        ForEach(rooms) { room in
            let count = intents.filter { $0.roomID == room.id }.count
            Button {
                appState.selectedRoomID = room.id
            } label: {
                RoomRow(
                    room: room,
                    intentCount: count,
                    isSelected: appState.selectedRoomID == room.id
                )
            }
            .buttonStyle(.plain)
            .listRowBackground(roomRowBackground(roomID: room.id))
            .contextMenu { roomContextMenu(room) }
            .onDrag {
                draggingRoomID = room.id
                return NSItemProvider(object: room.id as NSString)
            }
            .onDrop(of: [UTType.text], isTargeted: dropBinding(for: room.id)) { providers in
                handleReorderDrop(providers: providers, targetID: room.id)
            }
        }

        if rooms.isEmpty {
            Text("No rooms yet")
                .font(.caption)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
        }

        // Alert for renaming
        Color.clear
            .frame(height: 0)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .alert("Rename Room", isPresented: Binding(
                get: { renamingRoom != nil },
                set: { if !$0 { renamingRoom = nil } }
            )) {
                TextField("Room name", text: $renameText)
                Button("Rename") {
                    guard let room = renamingRoom else { return }
                    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { room.name = trimmed }
                    try? modelContext.save()
                    renamingRoom = nil
                }
                Button("Cancel", role: .cancel) { renamingRoom = nil }
            }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func roomContextMenu(_ room: Room) -> some View {
        Button("Rename...") {
            renameText = room.name
            renamingRoom = room
        }
        Divider()
        Menu("Color") {
            ForEach(roomColors, id: \.hex) { color in
                Button {
                    room.colorHex = color.hex
                    try? modelContext.save()
                } label: {
                    Label(color.name, systemImage: room.colorHex == color.hex ? "checkmark.circle.fill" : "circle.fill")
                }
                .tint(Color(hex: color.hex))
            }
        }
        Divider()
        Button("Delete Room", role: .destructive) {
            deleteRoom(room)
        }
    }

    // MARK: - Reordering

    @ViewBuilder
    private func roomRowBackground(roomID: String) -> some View {
        let isDropTarget = dropTargetRoomID == roomID
            && draggingRoomID != nil
            && draggingRoomID != roomID
        ZStack(alignment: .top) {
            Color.clear
            if isDropTarget {
                Color.accentColor.frame(height: 2)
            }
        }
    }

    private func dropBinding(for roomID: String) -> Binding<Bool> {
        Binding(
            get: { dropTargetRoomID == roomID },
            set: { targeted in
                if targeted { dropTargetRoomID = roomID }
                else if dropTargetRoomID == roomID { dropTargetRoomID = nil }
            }
        )
    }

    private func handleReorderDrop(providers: [NSItemProvider], targetID: String) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let sourceID = item as? String else { return }
            Task { @MainActor in
                reorderRoom(sourceID: sourceID, beforeTargetID: targetID)
                draggingRoomID = nil
                dropTargetRoomID = nil
            }
        }
        return true
    }

    private func reorderRoom(sourceID: String, beforeTargetID: String) {
        var ordered = Array(rooms)
        guard let sourceIndex = ordered.firstIndex(where: { $0.id == sourceID }) else { return }
        let source = ordered.remove(at: sourceIndex)
        if let targetIndex = ordered.firstIndex(where: { $0.id == beforeTargetID }) {
            ordered.insert(source, at: targetIndex)
        } else {
            ordered.append(source)
        }
        for (index, room) in ordered.enumerated() {
            room.displayOrder = index
        }
        try? modelContext.save()
    }

    // MARK: - Actions

    private func deleteRoom(_ room: Room) {
        if appState.selectedRoomID == room.id {
            appState.selectedRoomID = nil
            appState.activeIntentID = nil
        }
        // Unlink bookmarks from this room (don't delete the bookmarks themselves)
        let roomID = room.id
        do {
            let descriptor = FetchDescriptor<BookmarkedDirectory>(
                predicate: #Predicate { $0.roomID == roomID }
            )
            let bookmarks = try modelContext.fetch(descriptor)
            for bookmark in bookmarks {
                bookmark.roomID = nil
            }
            // Delete associated intents
            let intentDescriptor = FetchDescriptor<Intent>(
                predicate: #Predicate { $0.roomID == roomID }
            )
            let roomIntents = try modelContext.fetch(intentDescriptor)
            for intent in roomIntents {
                modelContext.delete(intent)
            }
        } catch {}
        modelContext.delete(room)
        try? modelContext.save()
    }

    // MARK: - Colors

    private let roomColors: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Green", "#34C759"),
        ("Orange", "#FF9500"),
        ("Red", "#FF3B30"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Teal", "#5AC8FA"),
        ("Yellow", "#FFCC00"),
        ("Indigo", "#5856D6"),
        ("Mint", "#00C7BE"),
    ]
}
