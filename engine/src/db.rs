use rusqlite::{params, Connection, Result as SqlResult};

#[allow(dead_code)]
const CURRENT_SCHEMA_VERSION: i32 = 1;

pub struct Database {
    conn: Connection,
}

impl Database {
    pub fn open(path: &str) -> SqlResult<Self> {
        let conn = Connection::open(path)?;
        conn.pragma_update(None, "journal_mode", "WAL")?;
        conn.pragma_update(None, "synchronous", "NORMAL")?;
        conn.pragma_update(None, "busy_timeout", 5000)?;

        let db = Database { conn };
        db.run_migrations()?;
        Ok(db)
    }

    #[allow(dead_code)]
    pub fn open_in_memory() -> SqlResult<Self> {
        let conn = Connection::open_in_memory()?;
        let db = Database { conn };
        db.run_migrations()?;
        Ok(db)
    }

    fn run_migrations(&self) -> SqlResult<()> {
        self.conn.execute_batch(
            "CREATE TABLE IF NOT EXISTS schema_version (version INTEGER NOT NULL);",
        )?;

        let version: i32 = self
            .conn
            .query_row(
                "SELECT COALESCE(MAX(version), 0) FROM schema_version",
                [],
                |row| row.get(0),
            )
            .unwrap_or(0);

        if version < 1 {
            self.migrate_v1()?;
        }

        Ok(())
    }

    fn migrate_v1(&self) -> SqlResult<()> {
        self.conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS snapshots (
                id          INTEGER PRIMARY KEY,
                timestamp   INTEGER NOT NULL,
                room_id     TEXT NOT NULL,
                intent_id   TEXT,
                event_type  TEXT NOT NULL,
                workspace   TEXT NOT NULL,
                git_head    TEXT,
                notes       TEXT
            );

            CREATE INDEX IF NOT EXISTS idx_snap_time ON snapshots(timestamp);
            CREATE INDEX IF NOT EXISTS idx_snap_room ON snapshots(room_id, timestamp);
            CREATE INDEX IF NOT EXISTS idx_snap_event ON snapshots(event_type, timestamp);

            CREATE TABLE IF NOT EXISTS rooms_index (
                room_id     TEXT PRIMARY KEY,
                name        TEXT NOT NULL,
                color_hex   TEXT NOT NULL,
                updated_at  INTEGER NOT NULL
            );

            INSERT OR REPLACE INTO schema_version (version) VALUES (1);
            ",
        )?;
        Ok(())
    }

    pub fn insert_snapshot(
        &self,
        timestamp: i64,
        room_id: &str,
        intent_id: Option<&str>,
        event_type: &str,
        workspace: &str,
        git_head: Option<&str>,
        notes: Option<&str>,
    ) -> SqlResult<i64> {
        self.conn.execute(
            "INSERT INTO snapshots (timestamp, room_id, intent_id, event_type, workspace, git_head, notes)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            params![timestamp, room_id, intent_id, event_type, workspace, git_head, notes],
        )?;
        Ok(self.conn.last_insert_rowid())
    }

    pub fn update_room_index(
        &self,
        room_id: &str,
        name: &str,
        color_hex: &str,
        updated_at: i64,
    ) -> SqlResult<()> {
        self.conn.execute(
            "INSERT OR REPLACE INTO rooms_index (room_id, name, color_hex, updated_at)
             VALUES (?1, ?2, ?3, ?4)",
            params![room_id, name, color_hex, updated_at],
        )?;
        Ok(())
    }

    #[allow(dead_code)]
    pub fn get_room_color(&self, room_id: &str) -> SqlResult<Option<String>> {
        let result = self.conn.query_row(
            "SELECT color_hex FROM rooms_index WHERE room_id = ?1",
            params![room_id],
            |row| row.get(0),
        );
        match result {
            Ok(color) => Ok(Some(color)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e),
        }
    }

    pub fn get_all_room_colors(&self) -> SqlResult<Vec<(String, String, String)>> {
        let mut stmt = self
            .conn
            .prepare("SELECT room_id, name, color_hex FROM rooms_index")?;
        let rows = stmt.query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
            ))
        })?;
        rows.collect()
    }

    /// Query snapshots in a time range, optionally filtered by room.
    pub fn query_snapshots(
        &self,
        start_ms: i64,
        end_ms: i64,
        room_id: Option<&str>,
    ) -> SqlResult<Vec<SnapshotRow>> {
        let (sql, params_vec): (String, Vec<Box<dyn rusqlite::types::ToSql>>) = match room_id {
            Some(rid) => (
                "SELECT id, timestamp, room_id, intent_id, event_type, workspace, git_head, notes
                 FROM snapshots WHERE timestamp >= ?1 AND timestamp <= ?2 AND room_id = ?3
                 ORDER BY timestamp ASC"
                    .into(),
                vec![
                    Box::new(start_ms),
                    Box::new(end_ms),
                    Box::new(rid.to_string()),
                ],
            ),
            None => (
                "SELECT id, timestamp, room_id, intent_id, event_type, workspace, git_head, notes
                 FROM snapshots WHERE timestamp >= ?1 AND timestamp <= ?2
                 ORDER BY timestamp ASC"
                    .into(),
                vec![Box::new(start_ms), Box::new(end_ms)],
            ),
        };

        let params_refs: Vec<&dyn rusqlite::types::ToSql> =
            params_vec.iter().map(|p| p.as_ref()).collect();
        let mut stmt = self.conn.prepare(&sql)?;
        let rows = stmt.query_map(params_refs.as_slice(), |row| {
            Ok(SnapshotRow {
                id: row.get(0)?,
                timestamp: row.get(1)?,
                room_id: row.get(2)?,
                intent_id: row.get(3)?,
                event_type: row.get(4)?,
                workspace: row.get(5)?,
                git_head: row.get(6)?,
                notes: row.get(7)?,
            })
        })?;
        rows.collect()
    }

    /// Find the nearest snapshot to a given timestamp.
    pub fn query_nearest_snapshot(&self, timestamp_ms: i64) -> SqlResult<Option<SnapshotRow>> {
        // Try the closest snapshot before or at the timestamp, then after
        let result = self.conn.query_row(
            "SELECT id, timestamp, room_id, intent_id, event_type, workspace, git_head, notes
             FROM snapshots
             ORDER BY ABS(timestamp - ?1) ASC
             LIMIT 1",
            params![timestamp_ms],
            |row| {
                Ok(SnapshotRow {
                    id: row.get(0)?,
                    timestamp: row.get(1)?,
                    room_id: row.get(2)?,
                    intent_id: row.get(3)?,
                    event_type: row.get(4)?,
                    workspace: row.get(5)?,
                    git_head: row.get(6)?,
                    notes: row.get(7)?,
                })
            },
        );
        match result {
            Ok(row) => Ok(Some(row)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e),
        }
    }

    /// Prune snapshots older than the given timestamp.
    #[allow(dead_code)]
    pub fn prune_before(&self, timestamp_ms: i64) -> SqlResult<usize> {
        self.conn.execute(
            "DELETE FROM snapshots WHERE timestamp < ?1",
            params![timestamp_ms],
        )
    }

    /// Get total snapshot count (for diagnostics).
    #[allow(dead_code)]
    pub fn snapshot_count(&self) -> SqlResult<i64> {
        self.conn
            .query_row("SELECT COUNT(*) FROM snapshots", [], |row| row.get(0))
    }
}

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct SnapshotRow {
    pub id: i64,
    pub timestamp: i64,
    pub room_id: String,
    pub intent_id: Option<String>,
    pub event_type: String,
    pub workspace: String,
    pub git_head: Option<String>,
    pub notes: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_and_query() {
        let db = Database::open_in_memory().unwrap();

        let id = db
            .insert_snapshot(
                1000,
                "room-1",
                None,
                "periodic",
                r#"{"tabs":[]}"#,
                None,
                None,
            )
            .unwrap();
        assert_eq!(id, 1);

        db.insert_snapshot(
            2000,
            "room-2",
            Some("intent-1"),
            "room_switch",
            r#"{"tabs":[{"id":"t1"}]}"#,
            Some("abc123"),
            Some("Switched to room-2"),
        )
        .unwrap();

        let snapshots = db.query_snapshots(0, 3000, None).unwrap();
        assert_eq!(snapshots.len(), 2);
        assert_eq!(snapshots[0].room_id, "room-1");
        assert_eq!(snapshots[1].room_id, "room-2");
    }

    #[test]
    fn query_by_room() {
        let db = Database::open_in_memory().unwrap();
        db.insert_snapshot(1000, "room-1", None, "periodic", "{}", None, None)
            .unwrap();
        db.insert_snapshot(2000, "room-2", None, "periodic", "{}", None, None)
            .unwrap();
        db.insert_snapshot(3000, "room-1", None, "periodic", "{}", None, None)
            .unwrap();

        let snapshots = db.query_snapshots(0, 4000, Some("room-1")).unwrap();
        assert_eq!(snapshots.len(), 2);
    }

    #[test]
    fn nearest_snapshot() {
        let db = Database::open_in_memory().unwrap();
        db.insert_snapshot(1000, "room-1", None, "periodic", "{}", None, None)
            .unwrap();
        db.insert_snapshot(5000, "room-2", None, "periodic", "{}", None, None)
            .unwrap();

        let nearest = db.query_nearest_snapshot(1200).unwrap().unwrap();
        assert_eq!(nearest.room_id, "room-1");

        let nearest = db.query_nearest_snapshot(4500).unwrap().unwrap();
        assert_eq!(nearest.room_id, "room-2");
    }

    #[test]
    fn room_index() {
        let db = Database::open_in_memory().unwrap();
        db.update_room_index("room-1", "API Server", "#007AFF", 1000)
            .unwrap();
        db.update_room_index("room-2", "Web App", "#FF3B30", 1000)
            .unwrap();

        let color = db.get_room_color("room-1").unwrap().unwrap();
        assert_eq!(color, "#007AFF");

        let all = db.get_all_room_colors().unwrap();
        assert_eq!(all.len(), 2);
    }

    #[test]
    fn prune() {
        let db = Database::open_in_memory().unwrap();
        db.insert_snapshot(1000, "r", None, "periodic", "{}", None, None)
            .unwrap();
        db.insert_snapshot(2000, "r", None, "periodic", "{}", None, None)
            .unwrap();
        db.insert_snapshot(3000, "r", None, "periodic", "{}", None, None)
            .unwrap();

        let pruned = db.prune_before(2500).unwrap();
        assert_eq!(pruned, 2);
        assert_eq!(db.snapshot_count().unwrap(), 1);
    }
}
