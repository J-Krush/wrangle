//
//  BrowsingHistoryEntry.swift
//  Wrangle
//

import Foundation
import SwiftData

@Model
final class BrowsingHistoryEntry {
    @Attribute(.unique) var id: String
    var urlString: String
    var title: String
    var dateVisited: Date
    var faviconData: Data?
    var projectID: String?
    var visitCount: Int

    init(
        id: String = UUID().uuidString,
        urlString: String,
        title: String,
        dateVisited: Date = .now,
        faviconData: Data? = nil,
        projectID: String? = nil,
        visitCount: Int = 1
    ) {
        self.id = id
        self.urlString = urlString
        self.title = title
        self.dateVisited = dateVisited
        self.faviconData = faviconData
        self.projectID = projectID
        self.visitCount = visitCount
    }

    var url: URL? { URL(string: urlString) }
}
