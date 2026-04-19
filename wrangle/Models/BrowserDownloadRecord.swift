//
//  BrowserDownloadRecord.swift
//  Wrangle
//

import Foundation
import SwiftData

enum BrowserDownloadState: String, Codable {
    case inProgress
    case completed
    case cancelled
    case failed
    case incomplete     // found at next launch, marked incomplete
}

@Model
final class BrowserDownloadRecord {
    @Attribute(.unique) var id: String
    var sourceURLString: String
    var destinationPath: String
    var filename: String
    var bytesReceived: Int64
    var bytesExpected: Int64       // 0 if unknown
    var stateRaw: String
    var dateStarted: Date
    var dateCompleted: Date?
    var errorDescription: String?

    init(
        id: String = UUID().uuidString,
        sourceURLString: String,
        destinationPath: String,
        filename: String,
        bytesReceived: Int64 = 0,
        bytesExpected: Int64 = 0,
        state: BrowserDownloadState = .inProgress,
        dateStarted: Date = .now,
        dateCompleted: Date? = nil,
        errorDescription: String? = nil
    ) {
        self.id = id
        self.sourceURLString = sourceURLString
        self.destinationPath = destinationPath
        self.filename = filename
        self.bytesReceived = bytesReceived
        self.bytesExpected = bytesExpected
        self.stateRaw = state.rawValue
        self.dateStarted = dateStarted
        self.dateCompleted = dateCompleted
        self.errorDescription = errorDescription
    }

    var state: BrowserDownloadState {
        get { BrowserDownloadState(rawValue: stateRaw) ?? .inProgress }
        set { stateRaw = newValue.rawValue }
    }

    var destinationURL: URL? {
        URL(fileURLWithPath: destinationPath)
    }

    var progress: Double {
        guard bytesExpected > 0 else { return 0 }
        return Double(bytesReceived) / Double(bytesExpected)
    }
}
