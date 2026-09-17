//! JSON-RPC 2.0 client over a newline-delimited unix socket.

use serde_json::{json, Value};
use std::path::Path;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::UnixStream;

pub struct RpcClient {
    write: tokio::net::unix::OwnedWriteHalf,
    reader: BufReader<tokio::net::unix::OwnedReadHalf>,
    next_id: u64,
    pending_events: Vec<(String, Value)>,
}

impl RpcClient {
    pub async fn connect(path: &Path) -> Result<Self, String> {
        let stream = UnixStream::connect(path)
            .await
            .map_err(|e| format!("connect {}: {e}", path.display()))?;
        let (read, write) = stream.into_split();
        Ok(Self {
            write,
            reader: BufReader::new(read),
            next_id: 1,
            pending_events: Vec::new(),
        })
    }

    pub async fn connect_retry(path: &Path, attempts: u32) -> Result<Self, String> {
        let mut last = String::new();
        for i in 0..attempts {
            match Self::connect(path).await {
                Ok(c) => return Ok(c),
                Err(e) => last = e,
            }
            if i + 1 < attempts {
                tokio::time::sleep(std::time::Duration::from_millis(50)).await;
            }
        }
        Err(last)
    }

    pub async fn call(&mut self, method: &str, params: Value) -> Result<Value, String> {
        let id = self.next_id;
        self.next_id += 1;
        let req = json!({
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params
        });
        let line = serde_json::to_string(&req).map_err(|e| format!("encode rpc: {e}"))?;
        self.write
            .write_all(line.as_bytes())
            .await
            .map_err(|e| format!("write rpc {method}: {e}"))?;
        self.write
            .write_all(b"\n")
            .await
            .map_err(|e| format!("write rpc newline {method}: {e}"))?;
        self.write
            .flush()
            .await
            .map_err(|e| format!("flush rpc {method}: {e}"))?;
        loop {
            let v = self.read_value().await?;
            if v.get("id") == Some(&json!(id)) {
                if let Some(err) = v.get("error") {
                    let msg = err
                        .get("message")
                        .and_then(|m| m.as_str())
                        .unwrap_or("rpc error");
                    return Err(msg.to_string());
                }
                return Ok(v.get("result").cloned().unwrap_or(Value::Null));
            }
            if let Some(m) = v.get("method").and_then(|m| m.as_str()) {
                self.pending_events.push((
                    m.to_string(),
                    v.get("params").cloned().unwrap_or(Value::Null),
                ));
            }
        }
    }

    pub async fn next_event(&mut self) -> Result<(String, Value), String> {
        if !self.pending_events.is_empty() {
            return Ok(self.pending_events.remove(0));
        }
        loop {
            let v = self.read_value().await?;
            if let Some(m) = v.get("method").and_then(|m| m.as_str()) {
                return Ok((
                    m.to_string(),
                    v.get("params").cloned().unwrap_or(Value::Null),
                ));
            }
        }
    }

    async fn read_value(&mut self) -> Result<Value, String> {
        let mut line = String::new();
        let n = self
            .reader
            .read_line(&mut line)
            .await
            .map_err(|e| format!("read rpc: {e}"))?;
        if n == 0 {
            return Err("rpc connection closed".into());
        }
        serde_json::from_str(line.trim()).map_err(|e| format!("parse rpc {e}: {line}"))
    }
}
