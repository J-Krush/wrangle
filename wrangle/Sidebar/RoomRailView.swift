import SwiftUI
import SwiftData

struct RoomRailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Room.displayOrder) private var rooms: [Room]
    @State private var showNewRoomAlert = false
    @State private var newRoomName = ""

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
        .background(Color(nsColor: Theme.chromeBackground))
        .alert("New Room", isPresented: $showNewRoomAlert) {
            TextField("Room name", text: $newRoomName)
            Button("Create") { commitNewRoom() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for the new room.")
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
            guard appState.selectedRoomID != room.id else { return }
            appState.switchToRoom(room.id)
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
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showNewRoomAlert = true
            newRoomName = ""
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
        Button("Rename...") {
            newRoomName = room.name
            // Reuse the alert for renaming (simple approach for now)
            showNewRoomAlert = true
        }
        Divider()
        Menu("Color") {
            ForEach(roomColors, id: \.hex) { color in
                Button(color.name) {
                    room.colorHex = color.hex
                    try? modelContext.save()
                }
            }
        }
        Divider()
        Button("Delete Room", role: .destructive) {
            deleteRoom(room)
        }
    }

    // MARK: - Actions

    private func commitNewRoom() {
        let name = newRoomName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let maxOrder = rooms.map(\.displayOrder).max() ?? -1
        let room = Room(name: name, displayOrder: maxOrder + 1)
        modelContext.insert(room)
        try? modelContext.save()
        appState.switchToRoom(room.id)
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

    // MARK: - Helpers

    private func roomInitials(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

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
