import Foundation
import SwiftData

@Model
final class RecentFile {
    var urlString: String
    var lastOpened: Date
    var bookmarkData: Data?

    var url: URL? {
        URL(string: urlString)
    }

    init(urlString: String, lastOpened: Date = .now, bookmarkData: Data? = nil) {
        self.urlString = urlString
        self.lastOpened = lastOpened
        self.bookmarkData = bookmarkData
    }
}
