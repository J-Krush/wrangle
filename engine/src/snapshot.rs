use crate::db::Database;
use crate::protocol::{OutboundMessage, RecordSnapshotMsg, SnapshotWrittenMsg};

/// Handle an incoming snapshot recording request.
/// Inserts into the database and returns the confirmation message.
pub fn handle_record_snapshot(
    db: &Database,
    msg: RecordSnapshotMsg,
) -> Result<OutboundMessage, String> {
    let workspace_json =
        serde_json::to_string(&msg.workspace).map_err(|e| format!("JSON error: {e}"))?;

    let id = db
        .insert_snapshot(
            msg.timestamp_ms,
            &msg.room_id,
            msg.intent_id.as_deref(),
            &msg.event_type,
            &workspace_json,
            msg.git_head.as_deref(),
            msg.notes.as_deref(),
        )
        .map_err(|e| format!("DB error: {e}"))?;

    Ok(OutboundMessage::SnapshotWritten(SnapshotWrittenMsg {
        id,
        timestamp: msg.timestamp_ms,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::Database;
    use serde_json::json;

    #[test]
    fn handle_snapshot_inserts_and_responds() {
        let db = Database::open_in_memory().unwrap();
        let msg = RecordSnapshotMsg {
            timestamp_ms: 1711382400000,
            room_id: "room-1".into(),
            intent_id: Some("intent-1".into()),
            event_type: "room_switch".into(),
            workspace: json!({
                "tabs": [
                    {
                        "id": "tab-1",
                        "kind": "document",
                        "file_path": "/src/index.ts",
                        "is_active": true
                    },
                    {
                        "id": "tab-2",
                        "kind": "terminal",
                        "title": "npm dev",
                        "working_dir": "/project",
                        "process": {"pid": 123, "command": "npm run dev", "running": true},
                        "metadata": {}
                    },
                    {
                        "id": "tab-3",
                        "kind": "browser",
                        "url": "http://localhost:3000",
                        "title": "Dev Server"
                    }
                ],
                "active_tab_id": "tab-1",
                "sidebar_state": {
                    "expanded_bookmarks": ["src/"],
                    "selected_file": "/src/index.ts"
                }
            }),
            git_head: Some("abc123".into()),
            notes: Some("Switched to API room".into()),
        };

        let response = handle_record_snapshot(&db, msg).unwrap();
        match response {
            OutboundMessage::SnapshotWritten(written) => {
                assert_eq!(written.id, 1);
                assert_eq!(written.timestamp, 1711382400000);
            }
            _ => panic!("Expected SnapshotWritten"),
        }

        // Verify it's in the database with full workspace data
        let snapshots = db.query_snapshots(0, i64::MAX, None).unwrap();
        assert_eq!(snapshots.len(), 1);
        assert_eq!(snapshots[0].room_id, "room-1");

        // Verify workspace JSON contains tabs
        let workspace: serde_json::Value =
            serde_json::from_str(&snapshots[0].workspace).unwrap();
        let tabs = workspace["tabs"].as_array().unwrap();
        assert_eq!(tabs.len(), 3);
        assert_eq!(tabs[0]["kind"], "document");
        assert_eq!(tabs[1]["kind"], "terminal");
        assert_eq!(tabs[2]["kind"], "browser");

        // Verify metadata is preserved
        assert_eq!(tabs[1]["process"]["pid"], 123);
    }
}
