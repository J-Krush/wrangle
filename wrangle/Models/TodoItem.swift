import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: String
    var title: String
    var isCompleted: Bool
    var projectID: String
    var displayOrder: Int
    var dateCreated: Date
    var dateCompleted: Date?

    init(
        title: String,
        projectID: String,
        displayOrder: Int = 0
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.isCompleted = false
        self.projectID = projectID
        self.displayOrder = displayOrder
        self.dateCreated = .now
    }
}
