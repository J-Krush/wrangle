import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RoomRailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Room.displayOrder) private var rooms: [Room]
    @State private var showNewRoomSheet = false
    @State private var showEditRoomSheet = false
    @State private var editingRoom: Room?
    @State private var sheetName = ""
    @State private var sheetColorHex = "#007AFF"
    @State private var draggingRoomID: String?
    @State private var dropTargetRoomID: String?

    var body: some View {
        VStack(spacing: 0) {
            // Sidebar toggle
            sidebarToggleButton
                .padding(.top, 8)
                .padding(.bottom, 4)

            Divider()
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    projectOverviewButton
                    ForEach(rooms) { room in
                        roomButton(room)
                    }
                    addButton
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .frame(width: 52)
        .background(Color(nsColor: appState.isInPlayback ? Theme.playbackChromeBackground : Theme.chromeBackground))
        .sheet(isPresented: $showNewRoomSheet) {
            RoomEditSheet(name: $sheetName, colorHex: $sheetColorHex, isNew: true) {
                commitNewRoom()
            }
        }
        .sheet(isPresented: $showEditRoomSheet) {
            RoomEditSheet(name: $sheetName, colorHex: $sheetColorHex, isNew: false) {
                commitEditRoom()
            }
        }
    }

    // MARK: - Project Overview Button

    private var projectOverviewButton: some View {
        Button {
            appState.selectedRoomID = nil
            appState.activeIntentID = nil
        } label: {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(appState.selectedRoomID == nil ? .primary : .secondary)
                .frame(width: 32, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("All Projects")
    }

    // MARK: - Sidebar Toggle

    private var sidebarToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.isSidebarVisible.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(appState.isSidebarVisible ? .primary : .secondary)
                .frame(width: 32, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(appState.isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")
    }

    // MARK: - Room Button

    private func roomButton(_ room: Room) -> some View {
        let isSelected = appState.selectedRoomID == room.id
        let initials = roomInitials(room.name)
        let color = Color(hex: room.colorHex) ?? .blue
        let roomTabs = appState.tabs.filter { $0.roomID == room.id }
        let hasAttention = roomTabs.contains { $0.terminalSession?.needsAttention == true }
        let hasRunning = roomTabs.contains { $0.terminalSession?.isRunning == true }

        return Button {
            if appState.selectedRoomID == room.id {
                // Toggle between editor and room overview
                appState.viewMode = appState.viewMode == .roomOverview ? .editor : .roomOverview
            } else {
                appState.switchToRoom(room.id)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: isSelected ? 12 : 20)
                    .fill(isSelected ? color : color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(initials)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 40, height: 40)

                if hasAttention {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color(nsColor: Theme.chromeBackground), lineWidth: 2))
                        .offset(x: 2, y: -2)
                } else if hasRunning {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color(nsColor: Theme.chromeBackground), lineWidth: 2))
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .help(room.name)
        .contextMenu {
            roomContextMenu(room)
        }
        .overlay(alignment: .top) {
            if dropTargetRoomID == room.id && draggingRoomID != nil && draggingRoomID != room.id {
                Color.accentColor
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .offset(y: -5)
            }
        }
        .onDrag {
            draggingRoomID = room.id
            return NSItemProvider(object: room.id as NSString)
        }
        .onDrop(of: [UTType.text], isTargeted: dropBinding(for: room.id)) { providers in
            handleReorderDrop(providers: providers, targetID: room.id)
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            sheetName = ""
            sheetColorHex = "#007AFF"
            showNewRoomSheet = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 40, height: 40)

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .help("New Room")
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func roomContextMenu(_ room: Room) -> some View {
        Button("Edit...") {
            editingRoom = room
            sheetName = room.name
            sheetColorHex = room.colorHex
            showEditRoomSheet = true
        }
        Divider()
        Button("Delete Room", role: .destructive) {
            deleteRoom(room)
        }
    }

    // MARK: - Actions

    private func commitNewRoom() {
        let name = sheetName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let maxOrder = rooms.map(\.displayOrder).max() ?? -1
        let room = Room(name: name, displayOrder: maxOrder + 1)
        room.colorHex = sheetColorHex
        modelContext.insert(room)
        try? modelContext.save()
        appState.switchToRoom(room.id)
        appState.coordinator?.engineClient.updateRoomIndex(roomID: room.id, name: name, colorHex: sheetColorHex)
    }

    private func commitEditRoom() {
        let name = sheetName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let room = editingRoom else { return }
        room.name = name
        room.colorHex = sheetColorHex
        try? modelContext.save()
        editingRoom = nil
        appState.coordinator?.engineClient.updateRoomIndex(roomID: room.id, name: name, colorHex: sheetColorHex)
    }

    private func deleteRoom(_ room: Room) {
        if appState.selectedRoomID == room.id {
            appState.selectedRoomID = nil
            appState.activeIntentID = nil
        }
        let roomID = room.id
        do {
            let bookmarkDesc = FetchDescriptor<BookmarkedDirectory>(
                predicate: #Predicate { $0.roomID == roomID }
            )
            for bookmark in try modelContext.fetch(bookmarkDesc) {
                bookmark.roomID = nil
            }
            let intentDesc = FetchDescriptor<Intent>(
                predicate: #Predicate { $0.roomID == roomID }
            )
            for intent in try modelContext.fetch(intentDesc) {
                modelContext.delete(intent)
            }
        } catch {}
        modelContext.delete(room)
        try? modelContext.save()
    }

    // MARK: - Reordering

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

    // MARK: - Helpers

    private func roomInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

}
