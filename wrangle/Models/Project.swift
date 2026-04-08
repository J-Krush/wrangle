import Foundation
import SwiftData

@Model
final class Project {
    var id: String
    var name: String
    var colorHex: String
    var iconName: String
    var displayOrder: Int
    var dateCreated: Date

    init(
        name: String,
        colorHex: String = "#007AFF",
        iconName: String = "folder.fill",
        displayOrder: Int = 0
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.displayOrder = displayOrder
        self.dateCreated = .now
    }
}
