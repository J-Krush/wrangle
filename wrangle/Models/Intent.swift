import Foundation
import SwiftData

@Model
final class Intent {
    var id: String
    var name: String
    var roomID: String
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
        roomID: String,
        status: Status = .active,
        displayOrder: Int = 0
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.roomID = roomID
        self.statusRaw = status.rawValue
        self.displayOrder = displayOrder
        self.dateCreated = .now
    }
}
