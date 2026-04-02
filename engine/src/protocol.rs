use serde::{Deserialize, Serialize};

// --- Inbound messages (Swift → Rust) ---

#[derive(Debug, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum InboundMessage {
    RecordSnapshot(RecordSnapshotMsg),
    UpdateRoomIndex(UpdateRoomIndexMsg),
    QueryTimeline(QueryTimelineMsg),
    QuerySnapshot(QuerySnapshotMsg),
    QueryTimeReport(QueryTimeReportMsg),
    Shutdown,
}

#[derive(Debug, Deserialize)]
pub struct RecordSnapshotMsg {
    pub timestamp_ms: i64,
    pub room_id: String,
    pub intent_id: Option<String>,
    pub event_type: String,
    pub workspace: serde_json::Value,
    pub git_head: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateRoomIndexMsg {
    pub room_id: String,
    pub name: String,
    pub color_hex: String,
}

#[derive(Debug, Deserialize)]
pub struct QueryTimelineMsg {
    pub request_id: String,
    pub start_ms: i64,
    pub end_ms: i64,
    pub room_id: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct QuerySnapshotMsg {
    pub request_id: String,
    pub timestamp_ms: i64,
}

#[derive(Debug, Deserialize)]
pub struct QueryTimeReportMsg {
    pub request_id: String,
    pub start_ms: i64,
    pub end_ms: i64,
}

// --- Outbound messages (Rust → Swift) ---

#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum OutboundMessage {
    SnapshotWritten(SnapshotWrittenMsg),
    TimelineResult(TimelineResultMsg),
    SnapshotResult(SnapshotResultMsg),
    TimeReportResult(TimeReportResultMsg),
    Error(ErrorMsg),
}

#[derive(Debug, Serialize)]
pub struct SnapshotWrittenMsg {
    pub id: i64,
    pub timestamp: i64,
}

#[derive(Debug, Serialize)]
pub struct TimelineResultMsg {
    pub request_id: String,
    pub spans: Vec<TimelineSpan>,
    pub events: Vec<TimelineEvent>,
}

#[derive(Debug, Serialize)]
pub struct SnapshotResultMsg {
    pub request_id: String,
    pub timestamp_ms: i64,
    pub room_id: String,
    pub intent_id: Option<String>,
    pub event_type: String,
    pub workspace: serde_json::Value,
    pub git_head: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct TimeReportResultMsg {
    pub request_id: String,
    pub entries: Vec<TimeReportEntry>,
}

#[derive(Debug, Serialize)]
pub struct ErrorMsg {
    pub request_id: Option<String>,
    pub message: String,
}

// --- Shared types ---

#[derive(Debug, Serialize, Clone)]
pub struct TimelineSpan {
    pub room_id: String,
    pub color_hex: String,
    pub start_ms: i64,
    pub end_ms: i64,
}

#[derive(Debug, Serialize, Clone)]
pub struct TimelineEvent {
    pub timestamp_ms: i64,
    pub event_type: String,
    pub room_id: String,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize, Clone)]
pub struct TimeReportEntry {
    pub room_id: String,
    pub room_name: String,
    pub total_ms: i64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deserialize_record_snapshot() {
        let json = r#"{
            "type": "record_snapshot",
            "timestamp_ms": 1711382400000,
            "room_id": "room-1",
            "intent_id": null,
            "event_type": "periodic",
            "workspace": {"tabs": [], "active_tab_id": null},
            "git_head": null,
            "notes": null
        }"#;
        let msg: InboundMessage = serde_json::from_str(json).unwrap();
        match msg {
            InboundMessage::RecordSnapshot(s) => {
                assert_eq!(s.room_id, "room-1");
                assert_eq!(s.event_type, "periodic");
            }
            _ => panic!("Expected RecordSnapshot"),
        }
    }

    #[test]
    fn deserialize_query_timeline() {
        let json = r#"{
            "type": "query_timeline",
            "request_id": "req-1",
            "start_ms": 1000,
            "end_ms": 2000,
            "room_id": null
        }"#;
        let msg: InboundMessage = serde_json::from_str(json).unwrap();
        match msg {
            InboundMessage::QueryTimeline(q) => {
                assert_eq!(q.start_ms, 1000);
                assert_eq!(q.end_ms, 2000);
            }
            _ => panic!("Expected QueryTimeline"),
        }
    }

    #[test]
    fn deserialize_shutdown() {
        let json = r#"{"type": "shutdown"}"#;
        let msg: InboundMessage = serde_json::from_str(json).unwrap();
        assert!(matches!(msg, InboundMessage::Shutdown));
    }

    #[test]
    fn serialize_outbound_roundtrip() {
        let msg = OutboundMessage::SnapshotWritten(SnapshotWrittenMsg {
            id: 42,
            timestamp: 1711382400000,
        });
        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("snapshot_written"));
        assert!(json.contains("42"));
    }

    #[test]
    fn serialize_timeline_result() {
        let msg = OutboundMessage::TimelineResult(TimelineResultMsg {
            request_id: "req-1".into(),
            spans: vec![TimelineSpan {
                room_id: "room-1".into(),
                color_hex: "#007AFF".into(),
                start_ms: 1000,
                end_ms: 2000,
            }],
            events: vec![],
        });
        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("timeline_result"));
        assert!(json.contains("#007AFF"));
    }
}
