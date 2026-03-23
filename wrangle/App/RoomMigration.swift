import Foundation
import SwiftData

enum RoomMigration {
    private static let migrationKey = "roomMigrationV1Complete"

    /// Migrates existing BookmarkedDirectories into individual Rooms.
    /// Each bookmark without a roomID gets its own Room. Idempotent via UserDefaults flag.
    @MainActor
    static func runIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        do {
            let descriptor = FetchDescriptor<BookmarkedDirectory>(
                predicate: #Predicate { $0.roomID == nil }
            )
            let unmigrated = try modelContext.fetch(descriptor)

            guard !unmigrated.isEmpty else {
                UserDefaults.standard.set(true, forKey: migrationKey)
                return
            }

            for bookmark in unmigrated {
                let room = Room(
                    name: bookmark.displayName,
                    colorHex: bookmark.iconColorHex,
                    displayOrder: bookmark.displayOrder
                )
                modelContext.insert(room)
                bookmark.roomID = room.id
            }

            try modelContext.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            // Migration will retry on next launch
        }
    }
}
