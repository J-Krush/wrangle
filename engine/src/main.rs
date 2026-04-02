mod db;
mod protocol;
mod snapshot;
mod timeline;

use db::Database;
use protocol::*;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::UnixListener;
use tokio::sync::Mutex;

fn default_socket_path() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".into());
    PathBuf::from(home)
        .join("Library/Application Support/Wrangle")
        .join("engine.sock")
}

fn default_db_path() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".into());
    PathBuf::from(home)
        .join("Library/Application Support/Wrangle")
        .join("timeline.db")
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();

    let socket_path = args
        .iter()
        .position(|a| a == "--socket-path")
        .and_then(|i| args.get(i + 1))
        .map(PathBuf::from)
        .unwrap_or_else(default_socket_path);

    let db_path = args
        .iter()
        .position(|a| a == "--db-path")
        .and_then(|i| args.get(i + 1))
        .map(PathBuf::from)
        .unwrap_or_else(default_db_path);

    // Ensure parent directories exist
    if let Some(parent) = socket_path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    if let Some(parent) = db_path.parent() {
        std::fs::create_dir_all(parent)?;
    }

    // Remove stale socket file
    let _ = std::fs::remove_file(&socket_path);

    // Open database
    let db_path_str = db_path.to_string_lossy().to_string();
    let db = Arc::new(Mutex::new(Database::open(&db_path_str)?));

    eprintln!(
        "wrangle-engine: starting (socket={}, db={})",
        socket_path.display(),
        db_path.display()
    );

    // Bind socket
    let listener = UnixListener::bind(&socket_path)?;
    eprintln!("wrangle-engine: listening on {}", socket_path.display());

    // Handle SIGTERM for graceful shutdown
    let shutdown_signal = tokio::signal::ctrl_c();
    tokio::pin!(shutdown_signal);

    loop {
        tokio::select! {
            accept_result = listener.accept() => {
                match accept_result {
                    Ok((stream, _addr)) => {
                        eprintln!("wrangle-engine: client connected");
                        let db = Arc::clone(&db);
                        let socket_path_clone = socket_path.clone();
                        if let Err(e) = handle_client(stream, db).await {
                            eprintln!("wrangle-engine: client error: {e}");
                        }
                        eprintln!("wrangle-engine: client disconnected");
                        // If we got a shutdown command, the handle_client will have returned.
                        // Check if the socket file still exists; if not, we were asked to shut down.
                        if !socket_path_clone.exists() {
                            eprintln!("wrangle-engine: shutting down (socket removed)");
                            break;
                        }
                    }
                    Err(e) => {
                        eprintln!("wrangle-engine: accept error: {e}");
                    }
                }
            }
            _ = &mut shutdown_signal => {
                eprintln!("wrangle-engine: received signal, shutting down");
                break;
            }
        }
    }

    // Cleanup
    let _ = std::fs::remove_file(&socket_path);
    eprintln!("wrangle-engine: stopped");
    Ok(())
}

async fn handle_client(
    stream: tokio::net::UnixStream,
    db: Arc<Mutex<Database>>,
) -> Result<(), Box<dyn std::error::Error>> {
    let (reader, writer) = stream.into_split();
    let mut reader = BufReader::new(reader);
    let writer = Arc::new(Mutex::new(writer));
    let mut line = String::new();

    loop {
        line.clear();
        let bytes_read = reader.read_line(&mut line).await?;
        if bytes_read == 0 {
            // Client disconnected
            break;
        }

        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        let msg: InboundMessage = match serde_json::from_str(trimmed) {
            Ok(m) => m,
            Err(e) => {
                let error = OutboundMessage::Error(ErrorMsg {
                    request_id: None,
                    message: format!("Parse error: {e}"),
                });
                send_message(&writer, &error).await?;
                continue;
            }
        };

        match msg {
            InboundMessage::Shutdown => {
                eprintln!("wrangle-engine: shutdown requested");
                return Ok(());
            }

            InboundMessage::RecordSnapshot(snap_msg) => {
                let db = db.lock().await;
                match snapshot::handle_record_snapshot(&db, snap_msg) {
                    Ok(response) => send_message(&writer, &response).await?,
                    Err(e) => {
                        let error = OutboundMessage::Error(ErrorMsg {
                            request_id: None,
                            message: e,
                        });
                        send_message(&writer, &error).await?;
                    }
                }
            }

            InboundMessage::UpdateRoomIndex(room_msg) => {
                let db = db.lock().await;
                let now_ms = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_millis() as i64;
                if let Err(e) =
                    db.update_room_index(&room_msg.room_id, &room_msg.name, &room_msg.color_hex, now_ms)
                {
                    let error = OutboundMessage::Error(ErrorMsg {
                        request_id: None,
                        message: format!("DB error: {e}"),
                    });
                    send_message(&writer, &error).await?;
                }
            }

            InboundMessage::QueryTimeline(query_msg) => {
                let db = db.lock().await;
                match timeline::query_timeline(
                    &db,
                    query_msg.start_ms,
                    query_msg.end_ms,
                    query_msg.room_id.as_deref(),
                ) {
                    Ok((spans, events)) => {
                        let response = OutboundMessage::TimelineResult(TimelineResultMsg {
                            request_id: query_msg.request_id,
                            spans,
                            events,
                        });
                        send_message(&writer, &response).await?;
                    }
                    Err(e) => {
                        let error = OutboundMessage::Error(ErrorMsg {
                            request_id: Some(query_msg.request_id),
                            message: format!("Query error: {e}"),
                        });
                        send_message(&writer, &error).await?;
                    }
                }
            }

            InboundMessage::QuerySnapshot(query_msg) => {
                let db = db.lock().await;
                match db.query_nearest_snapshot(query_msg.timestamp_ms) {
                    Ok(Some(row)) => {
                        let workspace: serde_json::Value =
                            serde_json::from_str(&row.workspace).unwrap_or_default();
                        let response = OutboundMessage::SnapshotResult(SnapshotResultMsg {
                            request_id: query_msg.request_id,
                            timestamp_ms: row.timestamp,
                            room_id: row.room_id,
                            intent_id: row.intent_id,
                            event_type: row.event_type,
                            workspace,
                            git_head: row.git_head,
                            notes: row.notes,
                        });
                        send_message(&writer, &response).await?;
                    }
                    Ok(None) => {
                        let error = OutboundMessage::Error(ErrorMsg {
                            request_id: Some(query_msg.request_id),
                            message: "No snapshots found".into(),
                        });
                        send_message(&writer, &error).await?;
                    }
                    Err(e) => {
                        let error = OutboundMessage::Error(ErrorMsg {
                            request_id: Some(query_msg.request_id),
                            message: format!("Query error: {e}"),
                        });
                        send_message(&writer, &error).await?;
                    }
                }
            }

            InboundMessage::QueryTimeReport(query_msg) => {
                let db = db.lock().await;
                match timeline::query_time_report(&db, query_msg.start_ms, query_msg.end_ms) {
                    Ok(entries) => {
                        let response = OutboundMessage::TimeReportResult(TimeReportResultMsg {
                            request_id: query_msg.request_id,
                            entries,
                        });
                        send_message(&writer, &response).await?;
                    }
                    Err(e) => {
                        let error = OutboundMessage::Error(ErrorMsg {
                            request_id: Some(query_msg.request_id),
                            message: format!("Query error: {e}"),
                        });
                        send_message(&writer, &error).await?;
                    }
                }
            }
        }
    }

    Ok(())
}

async fn send_message(
    writer: &Arc<Mutex<tokio::net::unix::OwnedWriteHalf>>,
    msg: &OutboundMessage,
) -> Result<(), Box<dyn std::error::Error>> {
    let json = serde_json::to_string(msg)?;
    let mut writer = writer.lock().await;
    writer.write_all(json.as_bytes()).await?;
    writer.write_all(b"\n").await?;
    writer.flush().await?;
    Ok(())
}
