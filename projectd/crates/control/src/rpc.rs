//! JSON-RPC 2.0, newline-delimited, over a unix socket.

use crate::provider::{self, ChatMessage, Provider};
use crate::{db, id};
use projectd_protocol::{
    events, methods, Message, MessageAppendedEvent, MessageDeltaEvent, MessageRole,
    ProjectCreateParams, ThreadGetParams, ThreadSendParams,
};
use serde_json::{json, Value};
use std::path::PathBuf;
use std::sync::{mpsc, Arc, Mutex};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::UnixListener;
use tokio::sync::mpsc as tokio_mpsc;

const COORDINATOR_SYSTEM: &str = "You are the Foreman coordinator. You plan work, delegate to worker agents, and review results. You never edit code yourself and you never run a shell. Until worker tools exist, answer with a short plan: what you would inspect, which tasks you would create, and what done looks like. Be concrete.";

pub struct ControlConfig {
    pub sqlite: PathBuf,
    pub socket: PathBuf,
    pub provider: Provider,
}

struct Inner {
    conn: Mutex<rusqlite::Connection>,
    provider: Provider,
    clients: Mutex<Vec<tokio_mpsc::UnboundedSender<String>>>,
}

pub async fn serve(config: ControlConfig) -> Result<(), String> {
    let conn = db::open(&config.sqlite)?;
    let workspaces = config
        .sqlite
        .parent()
        .unwrap_or_else(|| std::path::Path::new("."))
        .join("workspaces");
    db::ensure_local_workspace(&conn, &workspaces)?;
    let inner = Arc::new(Inner {
        conn: Mutex::new(conn),
        provider: config.provider,
        clients: Mutex::new(Vec::new()),
    });

    if let Some(parent) = config.socket.parent() {
        std::fs::create_dir_all(parent)
            .map_err(|e| format!("create socket dir {}: {e}", parent.display()))?;
    }
    let _ = std::fs::remove_file(&config.socket);
    let listener = UnixListener::bind(&config.socket)
        .map_err(|e| format!("bind {}: {e}", config.socket.display()))?;

    loop {
        let (stream, _) = listener
            .accept()
            .await
            .map_err(|e| format!("accept on {}: {e}", config.socket.display()))?;
        let inner = inner.clone();
        tokio::spawn(async move {
            if let Err(err) = handle_client(inner, stream).await {
                eprintln!("projectd client: {err}");
            }
        });
    }
}

async fn handle_client(inner: Arc<Inner>, stream: tokio::net::UnixStream) -> Result<(), String> {
    let (read, mut write) = stream.into_split();
    let (tx, mut rx) = tokio_mpsc::unbounded_channel::<String>();
    {
        let mut clients = inner
            .clients
            .lock()
            .map_err(|e| format!("clients lock: {e}"))?;
        clients.push(tx.clone());
    }
    let writer = tokio::spawn(async move {
        while let Some(line) = rx.recv().await {
            if write.write_all(line.as_bytes()).await.is_err() {
                break;
            }
            if write.write_all(b"\n").await.is_err() {
                break;
            }
            if write.flush().await.is_err() {
                break;
            }
        }
    });

    let mut lines = BufReader::new(read).lines();
    while let Some(line) = lines.next_line().await.map_err(|e| format!("read: {e}"))? {
        if line.trim().is_empty() {
            continue;
        }
        match dispatch(&inner, &line) {
            Ok(Some(resp)) => {
                let _ = tx.send(resp);
            }
            Ok(None) => {}
            Err(resp) => {
                let _ = tx.send(resp);
            }
        }
    }
    drop(tx);
    let _ = writer.await;
    Ok(())
}

fn dispatch(inner: &Arc<Inner>, line: &str) -> Result<Option<String>, String> {
    let req: Value = match serde_json::from_str(line) {
        Ok(v) => v,
        Err(e) => {
            return Ok(Some(error_obj(
                Value::Null,
                -32700,
                &format!("parse error: {e}"),
            )));
        }
    };
    let id = req.get("id").cloned().unwrap_or(Value::Null);
    let Some(method) = req.get("method").and_then(|m| m.as_str()) else {
        return Ok(Some(error_obj(id, -32600, "missing method")));
    };
    if id.is_null() {
        return Ok(None);
    }
    let params = req.get("params").cloned().unwrap_or(json!({}));
    let result = match method {
        methods::MACHINE_LIST => machine_list(inner),
        methods::PROJECT_LIST => project_list(inner),
        methods::PROJECT_CREATE => project_create(inner, params),
        methods::THREAD_GET => thread_get(inner, params),
        methods::THREAD_SEND => thread_send(inner, params),
        other => Err(format!(
            "{other} is not implemented in M0 (see SPEC.md milestones)"
        )),
    };
    match result {
        Ok(value) => Ok(Some(ok_obj(id, value))),
        Err(msg) => {
            let code = if msg.contains("not implemented") {
                -32601
            } else {
                -32000
            };
            Ok(Some(error_obj(id, code, &msg)))
        }
    }
}

fn machine_list(inner: &Inner) -> Result<Value, String> {
    let conn = lock_db(inner)?;
    let machines = db::list_machines(&conn)?;
    serde_json::to_value(machines).map_err(|e| format!("encode machines: {e}"))
}

fn project_list(inner: &Inner) -> Result<Value, String> {
    let conn = lock_db(inner)?;
    let projects = db::list_projects(&conn)?;
    serde_json::to_value(projects).map_err(|e| format!("encode projects: {e}"))
}

fn project_create(inner: &Inner, params: Value) -> Result<Value, String> {
    let p: ProjectCreateParams = serde_json::from_value(params)
        .map_err(|e| format!("invalid project.create params: {e}"))?;
    if p.name.trim().is_empty() {
        return Err("project.create: name is required".into());
    }
    let machine = if p.primary_machine_id.trim().is_empty() {
        "local".to_string()
    } else {
        p.primary_machine_id
    };
    let branch = if p.default_branch.trim().is_empty() {
        "main".to_string()
    } else {
        p.default_branch
    };
    let conn = lock_db(inner)?;
    let project = db::create_project(
        &conn,
        p.name.trim(),
        &p.repo_url,
        &branch,
        &machine,
        &p.coordinator_model,
        &p.worker_model,
    )?;
    serde_json::to_value(project).map_err(|e| format!("encode project: {e}"))
}

fn thread_get(inner: &Inner, params: Value) -> Result<Value, String> {
    let p: ThreadGetParams =
        serde_json::from_value(params).map_err(|e| format!("invalid thread.get params: {e}"))?;
    let conn = lock_db(inner)?;
    let messages = db::list_messages(&conn, &p.project_id, p.after_message_id.as_deref())?;
    serde_json::to_value(messages).map_err(|e| format!("encode messages: {e}"))
}

fn thread_send(inner: &Arc<Inner>, params: Value) -> Result<Value, String> {
    let p: ThreadSendParams =
        serde_json::from_value(params).map_err(|e| format!("invalid thread.send params: {e}"))?;
    if p.content.trim().is_empty() {
        return Err("thread.send: content is required".into());
    }
    let (user, project) = {
        let conn = lock_db(inner)?;
        let project = db::get_project(&conn, &p.project_id)?;
        let thread_id = db::thread_id_for_project(&conn, &p.project_id)?;
        let user = Message {
            id: id::new_id("msg"),
            thread_id,
            role: MessageRole::User,
            content: p.content.clone(),
            card: None,
            created_at: id::now_rfc3339(),
        };
        db::insert_message(&conn, &user)?;
        (user, project)
    };
    broadcast(
        inner,
        events::MESSAGE_APPENDED,
        serde_json::to_value(MessageAppendedEvent {
            message: user.clone(),
        })
        .map_err(|e| format!("encode message.appended: {e}"))?,
    );
    let inner_for_coord = inner.clone();
    let project_for_coord = project.clone();
    let user_for_coord = user.clone();
    std::thread::spawn(move || {
        run_coordinator(&inner_for_coord, &project_for_coord, &user_for_coord);
    });
    serde_json::to_value(user).map_err(|e| format!("encode user message: {e}"))
}

fn run_coordinator(inner: &Inner, project: &projectd_protocol::Project, user: &Message) {
    let coordinator_id = id::new_id("msg");
    let history = match lock_db(inner).and_then(|conn| db::list_messages(&conn, &project.id, None))
    {
        Ok(h) => h,
        Err(err) => {
            finish_coordinator_error(inner, user, coordinator_id, err);
            return;
        }
    };

    let mut chat = vec![ChatMessage {
        role: "system".into(),
        content: COORDINATOR_SYSTEM.into(),
    }];
    for m in &history {
        let role = match m.role {
            MessageRole::User => "user",
            MessageRole::Coordinator => "assistant",
            MessageRole::System => "system",
        };
        chat.push(ChatMessage {
            role: role.into(),
            content: m.content.clone(),
        });
    }

    let (tx, rx) = mpsc::channel();
    provider::stream_chat(&inner.provider, &project.coordinator_model, chat, tx);

    let mut body = String::new();
    loop {
        match rx.recv() {
            Ok(Ok(delta)) => {
                if !delta.text.is_empty() {
                    body.push_str(&delta.text);
                    let ev = MessageDeltaEvent {
                        message_id: coordinator_id.clone(),
                        text: delta.text,
                    };
                    if let Ok(params) = serde_json::to_value(ev) {
                        broadcast(inner, events::MESSAGE_DELTA, params);
                    }
                }
                if delta.done {
                    break;
                }
            }
            Ok(Err(err)) => {
                finish_coordinator_error(inner, user, coordinator_id, err);
                return;
            }
            Err(_) => {
                finish_coordinator_error(
                    inner,
                    user,
                    coordinator_id,
                    "provider stream ended without a terminal event".into(),
                );
                return;
            }
        }
    }

    let message = Message {
        id: coordinator_id,
        thread_id: user.thread_id.clone(),
        role: MessageRole::Coordinator,
        content: body,
        card: None,
        created_at: id::now_rfc3339(),
    };
    if let Err(err) = lock_db(inner).and_then(|conn| db::insert_message(&conn, &message)) {
        eprintln!("projectd persist coordinator message {}: {err}", message.id);
        return;
    }
    if let Ok(params) = serde_json::to_value(MessageAppendedEvent {
        message: message.clone(),
    }) {
        broadcast(inner, events::MESSAGE_APPENDED, params);
    }
}

fn finish_coordinator_error(inner: &Inner, user: &Message, id: String, err: String) {
    let message = Message {
        id,
        thread_id: user.thread_id.clone(),
        role: MessageRole::Coordinator,
        content: format!("Provider error: {err}"),
        card: None,
        created_at: id::now_rfc3339(),
    };
    let _ = lock_db(inner).and_then(|conn| db::insert_message(&conn, &message));
    if let Ok(params) = serde_json::to_value(MessageAppendedEvent { message }) {
        broadcast(inner, events::MESSAGE_APPENDED, params);
    }
}

fn lock_db(inner: &Inner) -> Result<std::sync::MutexGuard<'_, rusqlite::Connection>, String> {
    inner.conn.lock().map_err(|e| format!("sqlite lock: {e}"))
}

fn broadcast(inner: &Inner, method: &str, params: Value) {
    let Ok(line) = serde_json::to_string(&json!({
        "jsonrpc": "2.0",
        "method": method,
        "params": params
    })) else {
        return;
    };
    let Ok(mut clients) = inner.clients.lock() else {
        return;
    };
    clients.retain(|tx| tx.send(line.clone()).is_ok());
}

fn ok_obj(id: Value, result: Value) -> String {
    serde_json::to_string(&json!({
        "jsonrpc": "2.0",
        "id": id,
        "result": result
    }))
    .unwrap_or_else(|_| {
        r#"{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"encode"}}"#.into()
    })
}

fn error_obj(id: Value, code: i32, message: &str) -> String {
    serde_json::to_string(&json!({
        "jsonrpc": "2.0",
        "id": id,
        "error": {"code": code, "message": message}
    }))
    .unwrap_or_else(|_| {
        r#"{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"encode"}}"#.into()
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::client::RpcClient;
    use crate::provider::stub_provider;
    use std::time::Duration;

    async fn start_server() -> (
        std::path::PathBuf,
        tokio::task::JoinHandle<Result<(), String>>,
    ) {
        let dir = std::env::temp_dir().join(format!("pd{}", id::new_id("s")));
        std::fs::create_dir_all(&dir).unwrap();
        let cfg = ControlConfig {
            sqlite: dir.join("d.sqlite"),
            socket: dir.join("s.sock"),
            provider: stub_provider(),
        };
        let socket = cfg.socket.clone();
        let handle = tokio::spawn(async move { serve(cfg).await });
        for _ in 0..80 {
            if socket.exists() {
                break;
            }
            tokio::time::sleep(Duration::from_millis(25)).await;
        }
        (dir, handle)
    }

    #[tokio::test]
    async fn create_and_send_roundtrip() {
        let (dir, server) = start_server().await;
        let socket = dir.join("s.sock");
        let mut client = RpcClient::connect_retry(&socket, 40).await.unwrap();

        let machines = client.call(methods::MACHINE_LIST, json!({})).await.unwrap();
        assert_eq!(machines[0]["id"], "local");

        let project = client
            .call(
                methods::PROJECT_CREATE,
                json!({
                    "name": "Demo",
                    "repo_url": "https://example.com/repo.git",
                    "default_branch": "main",
                    "primary_machine_id": "local",
                    "coordinator_model": "stub",
                    "worker_model": "stub"
                }),
            )
            .await
            .unwrap();
        let pid = project["id"].as_str().unwrap().to_string();
        assert_eq!(project["name"], "Demo");

        let listed = client.call(methods::PROJECT_LIST, json!({})).await.unwrap();
        assert_eq!(listed.as_array().unwrap().len(), 1);

        let user = client
            .call(
                methods::THREAD_SEND,
                json!({"project_id": pid, "content": "Plan a README pass."}),
            )
            .await
            .unwrap();
        assert_eq!(user["role"], "user");

        let mut saw_delta = false;
        let mut coordinator_text = String::new();
        let deadline = tokio::time::Instant::now() + Duration::from_secs(8);
        while tokio::time::Instant::now() < deadline {
            let (method, params) =
                tokio::time::timeout(Duration::from_secs(8), client.next_event())
                    .await
                    .expect("event timeout")
                    .unwrap();
            if method == events::MESSAGE_DELTA {
                saw_delta = true;
            }
            if method == events::MESSAGE_APPENDED && params["message"]["role"] == "coordinator" {
                coordinator_text = params["message"]["content"].as_str().unwrap().to_string();
                break;
            }
        }
        assert!(saw_delta, "expected message.delta events");
        assert!(
            coordinator_text.contains("Foreman"),
            "unexpected coordinator text: {coordinator_text}"
        );

        let thread = client
            .call(methods::THREAD_GET, json!({"project_id": pid}))
            .await
            .unwrap();
        assert_eq!(thread.as_array().unwrap().len(), 2);

        server.abort();
        let _ = std::fs::remove_dir_all(dir);
    }
}
