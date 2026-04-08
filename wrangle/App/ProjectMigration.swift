import Foundation
import SwiftData

enum ProjectMigration {
    private static let migrationKey = "roomMigrationV1Complete"

    /// Migrates existing BookmarkedDirectories into individual Projects.
    /// Each bookmark without a projectID gets its own Project. Idempotent via UserDefaults flag.
    @MainActor
    static func runIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        do {
            let descriptor = FetchDescriptor<BookmarkedDirectory>(
                predicate: #Predicate { $0.projectID == nil }
            )
            let unmigrated = try modelContext.fetch(descriptor)

            guard !unmigrated.isEmpty else {
                UserDefaults.standard.set(true, forKey: migrationKey)
                return
            }

            for bookmark in unmigrated {
                let project = Project(
                    name: bookmark.displayName,
                    colorHex: bookmark.iconColorHex,
                    displayOrder: bookmark.displayOrder
                )
                modelContext.insert(project)
                bookmark.projectID = project.id
            }

            try modelContext.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            // Migration will retry on next launch
        }
    }
}
