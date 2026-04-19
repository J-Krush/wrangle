//
//  BrowserBookmarkFolder.swift
//  Wrangle
//

import Foundation
import SwiftData

@Model
final class BrowserBookmarkFolder {
    @Attribute(.unique) var id: String
    var name: String
    /// `nil` = global folder (visible in every project).
    var projectID: String?
    /// Parent folder's id; `nil` = top level.
    var parentFolderID: String?
    var displayOrder: Int
    var dateCreated: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        projectID: String? = nil,
        parentFolderID: String? = nil,
        displayOrder: Int = 0,
        dateCreated: Date = .now
    ) {
        self.id = id
        self.name = name
        self.projectID = projectID
        self.parentFolderID = parentFolderID
        self.displayOrder = displayOrder
        self.dateCreated = dateCreated
    }
}
