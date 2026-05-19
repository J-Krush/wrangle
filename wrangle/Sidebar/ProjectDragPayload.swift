import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Transferable payload for project drag-reorder. Uses the modern Transferable
/// API instead of NSItemProvider — the older path is unreliable on macOS 15
/// (Sequoia) for short string payloads embedded in HStack/List items.
struct ProjectDragPayload: Codable, Transferable {
    let id: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
