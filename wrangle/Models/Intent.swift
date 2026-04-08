import Foundation
import SwiftData

@Model
final class Intent {
    var id: String
    var name: String
    var projectID: String
    var statusRaw: String
    var displayOrder: Int
    var dateCreated: Date

    enum Status: String, CaseIterable {
        case active, paused, archived

        var label: String {
            switch self {
            case .active: "Active"
            case .paused: "Paused"
            case .archived: "Archived"
            }
        }
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    init(
        name: String,
        projectID: String,
        status: Status = .active,
        displayOrder: Int = 0
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.projectID = projectID
        self.statusRaw = status.rawValue
        self.displayOrder = displayOrder
        self.dateCreated = .now
    }
}
