import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RoomListSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Room.displayOrder) private var rooms: [Room]
    @Query private var intents: [Intent]
    @State private var editingRoom: Room?
    @State private var showEditSheet = false
    @State private var sheetName = ""
    @State private var sheetColorHex = "#007AFF"
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

        // Edit sheet trigger
        Color.clear
            .frame(height: 0)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .sheet(isPresented: $showEditSheet) {
                RoomEditSheet(name: $sheetName, colorHex: $sheetColorHex, isNew: false) {
                    guard let room = editingRoom else { return }
                    let trimmed = sheetName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { room.name = trimmed }
                    room.colorHex = sheetColorHex
                    try? modelContext.save()
                    editingRoom = nil
                    appState.coordinator?.engineClient.updateRoomIndex(roomID: room.id, name: room.name, colorHex: room.colorHex)
                }
            }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func roomContextMenu(_ room: Room) -> some View {
        Button("Edit...") {
            editingRoom = room
            sheetName = room.name
            sheetColorHex = room.colorHex
            showEditSheet = true
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

}
