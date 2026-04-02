use crate::db::{Database, SnapshotRow};
use crate::protocol::{TimeReportEntry, TimelineEvent, TimelineSpan};

/// Gap threshold: if no snapshot for 5 minutes, consider the user idle.
const IDLE_GAP_MS: i64 = 5 * 60 * 1000;

/// Compute timeline spans from a list of snapshots ordered by timestamp.
/// Consecutive snapshots in the same room are merged into a single span.
/// Gaps >5 minutes break the span (user was away).
pub fn compute_spans(
    snapshots: &[SnapshotRow],
    room_colors: &[(String, String, String)], // (room_id, name, color_hex)
) -> Vec<TimelineSpan> {
    if snapshots.is_empty() {
        return vec![];
    }

    let color_map: std::collections::HashMap<&str, &str> = room_colors
        .iter()
        .map(|(id, _, color)| (id.as_str(), color.as_str()))
        .collect();

    let mut spans: Vec<TimelineSpan> = Vec::new();
    let mut current_room = &snapshots[0].room_id;
    let mut span_start = snapshots[0].timestamp;
    let mut prev_timestamp = snapshots[0].timestamp;

    for snapshot in &snapshots[1..] {
        let gap = snapshot.timestamp - prev_timestamp;
        let room_changed = snapshot.room_id != *current_room;

        if room_changed || gap > IDLE_GAP_MS {
            // Close current span
            let color = color_map
                .get(current_room.as_str())
                .copied()
                .unwrap_or("#888888");
            spans.push(TimelineSpan {
                room_id: current_room.clone(),
                color_hex: color.to_string(),
                start_ms: span_start,
                end_ms: prev_timestamp,
            });

            // Start new span
            current_room = &snapshot.room_id;
            span_start = snapshot.timestamp;
        }

        prev_timestamp = snapshot.timestamp;
    }

    // Close final span
    let color = color_map
        .get(current_room.as_str())
        .copied()
        .unwrap_or("#888888");
    spans.push(TimelineSpan {
        room_id: current_room.clone(),
        color_hex: color.to_string(),
        start_ms: span_start,
        end_ms: prev_timestamp,
    });

    spans
}

/// Extract non-periodic events as timeline event markers.
pub fn extract_events(snapshots: &[SnapshotRow]) -> Vec<TimelineEvent> {
    snapshots
        .iter()
        .filter(|s| s.event_type != "periodic")
        .map(|s| TimelineEvent {
            timestamp_ms: s.timestamp,
            event_type: s.event_type.clone(),
            room_id: s.room_id.clone(),
            notes: s.notes.clone(),
        })
        .collect()
}

/// Compute time spent per room from spans.
pub fn compute_time_report(
    spans: &[TimelineSpan],
    room_colors: &[(String, String, String)],
) -> Vec<TimeReportEntry> {
    let name_map: std::collections::HashMap<&str, &str> = room_colors
        .iter()
        .map(|(id, name, _)| (id.as_str(), name.as_str()))
        .collect();

    let mut totals: std::collections::HashMap<String, i64> = std::collections::HashMap::new();
    for span in spans {
        let duration = span.end_ms - span.start_ms;
        *totals.entry(span.room_id.clone()).or_insert(0) += duration;
    }

    let mut entries: Vec<TimeReportEntry> = totals
        .into_iter()
        .map(|(room_id, total_ms)| {
            let room_name = name_map
                .get(room_id.as_str())
                .copied()
                .unwrap_or("Unknown")
                .to_string();
            TimeReportEntry {
                room_id,
                room_name,
                total_ms,
            }
        })
        .collect();

    entries.sort_by(|a, b| b.total_ms.cmp(&a.total_ms));
    entries
}

/// High-level query: get timeline data for a time range.
pub fn query_timeline(
    db: &Database,
    start_ms: i64,
    end_ms: i64,
    room_id: Option<&str>,
) -> Result<(Vec<TimelineSpan>, Vec<TimelineEvent>), rusqlite::Error> {
    let snapshots = db.query_snapshots(start_ms, end_ms, room_id)?;
    let room_colors = db.get_all_room_colors()?;
    let spans = compute_spans(&snapshots, &room_colors);
    let events = extract_events(&snapshots);
    Ok((spans, events))
}

/// High-level query: get time report for a time range.
pub fn query_time_report(
    db: &Database,
    start_ms: i64,
    end_ms: i64,
) -> Result<Vec<TimeReportEntry>, rusqlite::Error> {
    let snapshots = db.query_snapshots(start_ms, end_ms, None)?;
    let room_colors = db.get_all_room_colors()?;
    let spans = compute_spans(&snapshots, &room_colors);
    Ok(compute_time_report(&spans, &room_colors))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::SnapshotRow;

    fn make_snapshot(timestamp: i64, room_id: &str, event_type: &str) -> SnapshotRow {
        SnapshotRow {
            id: 0,
            timestamp,
            room_id: room_id.to_string(),
            intent_id: None,
            event_type: event_type.to_string(),
            workspace: "{}".to_string(),
            git_head: None,
            notes: None,
        }
    }

    fn room_colors() -> Vec<(String, String, String)> {
        vec![
            ("room-1".into(), "API Server".into(), "#007AFF".into()),
            ("room-2".into(), "Web App".into(), "#FF3B30".into()),
        ]
    }

    #[test]
    fn single_room_single_span() {
        let snapshots = vec![
            make_snapshot(1000, "room-1", "periodic"),
            make_snapshot(2000, "room-1", "periodic"),
            make_snapshot(3000, "room-1", "periodic"),
        ];
        let spans = compute_spans(&snapshots, &room_colors());
        assert_eq!(spans.len(), 1);
        assert_eq!(spans[0].room_id, "room-1");
        assert_eq!(spans[0].start_ms, 1000);
        assert_eq!(spans[0].end_ms, 3000);
        assert_eq!(spans[0].color_hex, "#007AFF");
    }

    #[test]
    fn room_switch_creates_two_spans() {
        let snapshots = vec![
            make_snapshot(1000, "room-1", "periodic"),
            make_snapshot(2000, "room-1", "periodic"),
            make_snapshot(3000, "room-2", "room_switch"),
            make_snapshot(4000, "room-2", "periodic"),
        ];
        let spans = compute_spans(&snapshots, &room_colors());
        assert_eq!(spans.len(), 2);
        assert_eq!(spans[0].room_id, "room-1");
        assert_eq!(spans[0].end_ms, 2000);
        assert_eq!(spans[1].room_id, "room-2");
        assert_eq!(spans[1].start_ms, 3000);
    }

    #[test]
    fn idle_gap_breaks_span() {
        let snapshots = vec![
            make_snapshot(1000, "room-1", "periodic"),
            make_snapshot(2000, "room-1", "periodic"),
            // Gap of 6 minutes (360000ms) > 5 min threshold
            make_snapshot(362000, "room-1", "periodic"),
            make_snapshot(363000, "room-1", "periodic"),
        ];
        let spans = compute_spans(&snapshots, &room_colors());
        assert_eq!(spans.len(), 2);
        assert_eq!(spans[0].end_ms, 2000);
        assert_eq!(spans[1].start_ms, 362000);
    }

    #[test]
    fn extract_non_periodic_events() {
        let snapshots = vec![
            make_snapshot(1000, "room-1", "periodic"),
            make_snapshot(2000, "room-1", "room_switch"),
            make_snapshot(3000, "room-2", "periodic"),
            make_snapshot(4000, "room-2", "tab_open"),
        ];
        let events = extract_events(&snapshots);
        assert_eq!(events.len(), 2);
        assert_eq!(events[0].event_type, "room_switch");
        assert_eq!(events[1].event_type, "tab_open");
    }

    #[test]
    fn time_report_computation() {
        let spans = vec![
            TimelineSpan {
                room_id: "room-1".into(),
                color_hex: "#007AFF".into(),
                start_ms: 0,
                end_ms: 3000,
            },
            TimelineSpan {
                room_id: "room-2".into(),
                color_hex: "#FF3B30".into(),
                start_ms: 3000,
                end_ms: 5000,
            },
            TimelineSpan {
                room_id: "room-1".into(),
                color_hex: "#007AFF".into(),
                start_ms: 5000,
                end_ms: 7000,
            },
        ];
        let report = compute_time_report(&spans, &room_colors());
        assert_eq!(report.len(), 2);
        // room-1 has 3000 + 2000 = 5000ms total
        assert_eq!(report[0].room_id, "room-1");
        assert_eq!(report[0].total_ms, 5000);
        // room-2 has 2000ms
        assert_eq!(report[1].room_id, "room-2");
        assert_eq!(report[1].total_ms, 2000);
    }

    #[test]
    fn empty_snapshots() {
        let spans = compute_spans(&[], &room_colors());
        assert!(spans.is_empty());
    }

    #[test]
    fn integration_with_db() {
        let db = Database::open_in_memory().unwrap();
        db.update_room_index("room-1", "API Server", "#007AFF", 0)
            .unwrap();
        db.update_room_index("room-2", "Web App", "#FF3B30", 0)
            .unwrap();

        db.insert_snapshot(1000, "room-1", None, "periodic", "{}", None, None)
            .unwrap();
        db.insert_snapshot(2000, "room-1", None, "periodic", "{}", None, None)
            .unwrap();
        db.insert_snapshot(3000, "room-2", None, "room_switch", "{}", None, Some("Switched"))
            .unwrap();
        db.insert_snapshot(4000, "room-2", None, "periodic", "{}", None, None)
            .unwrap();

        let (spans, events) = query_timeline(&db, 0, 5000, None).unwrap();
        assert_eq!(spans.len(), 2);
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].event_type, "room_switch");

        let report = query_time_report(&db, 0, 5000).unwrap();
        assert_eq!(report.len(), 2);
    }
}
