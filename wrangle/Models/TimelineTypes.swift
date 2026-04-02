//
//  TimelineTypes.swift
//  Wrangle
//
//  Types for workspace snapshots and timeline data,
//  matching the Rust engine's ndjson protocol.

import Foundation

// MARK: - Workspace Snapshot (sent to engine)

struct WorkspaceSnapshot: Codable {
    let timestampMs: Int64
    let roomID: String
    let intentID: String?
    let eventType: String
    let workspace: WorkspaceState
    let gitHead: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case timestampMs = "timestamp_ms"
        case roomID = "room_id"
        case intentID = "intent_id"
        case eventType = "event_type"
        case workspace
        case gitHead = "git_head"
        case notes
    }
}

struct WorkspaceState: Codable {
    let tabs: [TabSnapshot]
    let activeTabID: String?
    let sidebarState: SidebarSnapshot?

    enum CodingKeys: String, CodingKey {
        case tabs
        case activeTabID = "active_tab_id"
        case sidebarState = "sidebar_state"
    }
}

struct TabSnapshot: Codable {
    let id: String
    let kind: String           // "document" | "terminal" | "browser"
    let filePath: String?      // documents
    let url: String?           // browsers
    let title: String?
    let workingDir: String?    // terminals
    let process: ProcessSnapshot?
    let metadata: [String: String]
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, kind, title, url, process, metadata
        case filePath = "file_path"
        case workingDir = "working_dir"
        case isActive = "is_active"
    }
}

struct ProcessSnapshot: Codable {
    let pid: Int?
    let command: String?
    let running: Bool
}

struct SidebarSnapshot: Codable {
    let expandedBookmarks: [String]
    let selectedFile: String?

    enum CodingKeys: String, CodingKey {
        case expandedBookmarks = "expanded_bookmarks"
        case selectedFile = "selected_file"
    }
}

// MARK: - Timeline Query Results (received from engine)

struct TimelineSpan: Codable, Identifiable {
    var id: String { "\(roomID)-\(startMs)" }
    let roomID: String
    let colorHex: String
    let startMs: Int64
    let endMs: Int64

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case colorHex = "color_hex"
        case startMs = "start_ms"
        case endMs = "end_ms"
    }
}

struct TimelineEvent: Codable, Identifiable {
    var id: String { "\(roomID)-\(timestampMs)" }
    let timestampMs: Int64
    let eventType: String
    let roomID: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case timestampMs = "timestamp_ms"
        case eventType = "event_type"
        case roomID = "room_id"
        case notes
    }
}

struct TimelineResult: Codable {
    let requestID: String
    let spans: [TimelineSpan]
    let events: [TimelineEvent]

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case spans, events
    }
}

struct SnapshotQueryResult: Codable {
    let requestID: String
    let timestampMs: Int64
    let roomID: String
    let intentID: String?
    let eventType: String
    let workspace: WorkspaceState
    let gitHead: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case timestampMs = "timestamp_ms"
        case roomID = "room_id"
        case intentID = "intent_id"
        case eventType = "event_type"
        case workspace
        case gitHead = "git_head"
        case notes
    }
}

struct TimeReportEntry: Codable {
    let roomID: String
    let roomName: String
    let totalMs: Int64

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case roomName = "room_name"
        case totalMs = "total_ms"
    }
}

struct TimeReportResult: Codable {
    let requestID: String
    let entries: [TimeReportEntry]

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case entries
    }
}

// MARK: - Engine Messages

/// Wraps outbound messages from Swift to the Rust engine.
enum EngineOutbound: Codable {
    case recordSnapshot(WorkspaceSnapshot)
    case updateRoomIndex(roomID: String, name: String, colorHex: String)
    case queryTimeline(requestID: String, startMs: Int64, endMs: Int64, roomID: String?)
    case querySnapshot(requestID: String, timestampMs: Int64)
    case queryTimeReport(requestID: String, startMs: Int64, endMs: Int64)
    case shutdown

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .recordSnapshot(let snapshot):
            try container.encode("record_snapshot", forKey: .type)
            try container.encode(snapshot.timestampMs, forKey: .timestampMs)
            try container.encode(snapshot.roomID, forKey: .roomID)
            try container.encodeIfPresent(snapshot.intentID, forKey: .intentID)
            try container.encode(snapshot.eventType, forKey: .eventType)
            try container.encode(snapshot.workspace, forKey: .workspace)
            try container.encodeIfPresent(snapshot.gitHead, forKey: .gitHead)
            try container.encodeIfPresent(snapshot.notes, forKey: .notes)
        case .updateRoomIndex(let roomID, let name, let colorHex):
            try container.encode("update_room_index", forKey: .type)
            try container.encode(roomID, forKey: .roomID)
            try container.encode(name, forKey: .name)
            try container.encode(colorHex, forKey: .colorHex)
        case .queryTimeline(let requestID, let startMs, let endMs, let roomID):
            try container.encode("query_timeline", forKey: .type)
            try container.encode(requestID, forKey: .requestID)
            try container.encode(startMs, forKey: .startMs)
            try container.encode(endMs, forKey: .endMs)
            try container.encodeIfPresent(roomID, forKey: .roomID)
        case .querySnapshot(let requestID, let timestampMs):
            try container.encode("query_snapshot", forKey: .type)
            try container.encode(requestID, forKey: .requestID)
            try container.encode(timestampMs, forKey: .timestampMs)
        case .queryTimeReport(let requestID, let startMs, let endMs):
            try container.encode("query_time_report", forKey: .type)
            try container.encode(requestID, forKey: .requestID)
            try container.encode(startMs, forKey: .startMs)
            try container.encode(endMs, forKey: .endMs)
        case .shutdown:
            try container.encode("shutdown", forKey: .type)
        }
    }

    init(from decoder: Decoder) throws {
        // Decoding not needed — these are only sent, never received
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "EngineOutbound is encode-only"))
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case timestampMs = "timestamp_ms"
        case roomID = "room_id"
        case intentID = "intent_id"
        case eventType = "event_type"
        case workspace
        case gitHead = "git_head"
        case notes
        case name
        case colorHex = "color_hex"
        case requestID = "request_id"
        case startMs = "start_ms"
        case endMs = "end_ms"
    }
}

/// Inbound message envelope from the Rust engine.
struct EngineInbound: Codable {
    let type: String

    enum CodingKeys: String, CodingKey {
        case type
    }
}
