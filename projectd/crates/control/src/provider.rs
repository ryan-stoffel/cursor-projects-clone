//! OpenAI-compatible chat completions. No vendor SDK.

use serde_json::{json, Value};
use std::io::{BufRead, BufReader, Read};
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

#[derive(Clone, Debug)]
pub struct Provider {
    pub name: String,
    pub base_url: String,
    pub api_key: String,
    pub models: Vec<String>,
}

pub struct StreamDelta {
    pub text: String,
    pub prompt_tokens: Option<u64>,
    pub completion_tokens: Option<u64>,
    pub done: bool,
}

pub fn load_default() -> Result<Provider, String> {
    if std::env::var("PROJECTD_STUB_PROVIDER").ok().as_deref() == Some("1") {
        return Ok(stub_provider());
    }
    let path = crate::paths::providers_path();
    if !path.exists() {
        return Err(format!(
            "no providers file at {} and PROJECTD_STUB_PROVIDER is not set. Copy projectd/providers.toml.example to that path.",
            path.display()
        ));
    }
    let text =
        std::fs::read_to_string(&path).map_err(|e| format!("read {}: {e}", path.display()))?;
    let providers = parse_providers_toml(&text)?;
    providers
        .into_iter()
        .next()
        .ok_or_else(|| format!("no [[provider]] entries in {}", path.display()))
}

pub fn stub_provider() -> Provider {
    Provider {
        name: "stub".into(),
        base_url: "stub://".into(),
        api_key: String::new(),
        models: vec!["stub".into()],
    }
}

#[derive(Clone, Debug)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

pub fn stream_chat(
    provider: &Provider,
    model: &str,
    messages: Vec<ChatMessage>,
    tx: mpsc::Sender<Result<StreamDelta, String>>,
) {
    let provider = provider.clone();
    let model = model.to_string();
    thread::spawn(move || {
        let result = if provider.base_url.starts_with("stub:") {
            run_stub(&tx)
        } else {
            run_openai(&provider, &model, &messages, &tx)
        };
        if let Err(err) = result {
            let _ = tx.send(Err(err));
        }
    });
}

fn run_stub(tx: &mpsc::Sender<Result<StreamDelta, String>>) -> Result<(), String> {
    let text = "I am the Foreman coordinator. I will plan and delegate; I never edit code. Tell me the outcome you want and I will break it into tasks.";
    for word in text.split(' ') {
        thread::sleep(Duration::from_millis(15));
        tx.send(Ok(StreamDelta {
            text: format!("{word} "),
            prompt_tokens: None,
            completion_tokens: None,
            done: false,
        }))
        .map_err(|_| "provider stream closed".to_string())?;
    }
    tx.send(Ok(StreamDelta {
        text: String::new(),
        prompt_tokens: Some(0),
        completion_tokens: Some(text.split(' ').count() as u64),
        done: true,
    }))
    .map_err(|_| "provider stream closed".to_string())?;
    Ok(())
}

fn run_openai(
    provider: &Provider,
    model: &str,
    messages: &[ChatMessage],
    tx: &mpsc::Sender<Result<StreamDelta, String>>,
) -> Result<(), String> {
    let url = format!(
        "{}/chat/completions",
        provider.base_url.trim_end_matches('/')
    );
    let msgs: Vec<Value> = messages
        .iter()
        .map(|m| json!({"role": m.role, "content": m.content}))
        .collect();
    let body = json!({
        "model": model,
        "stream": true,
        "messages": msgs
    });
    let mut req = ureq::post(&url).set("Content-Type", "application/json");
    if !provider.api_key.is_empty() {
        req = req.set("Authorization", &format!("Bearer {}", provider.api_key));
    }
    let resp = req
        .send_json(body)
        .map_err(|e| format!("provider {} POST {url} failed: {e}", provider.name))?;
    let status = resp.status();
    if status >= 400 {
        let mut text = String::new();
        let _ = resp.into_reader().take(2048).read_to_string(&mut text);
        return Err(format!(
            "provider {} POST {url} HTTP {status}: {}",
            provider.name,
            text.trim()
        ));
    }
    let reader = BufReader::new(resp.into_reader());
    let mut prompt_tokens = None;
    let mut completion_tokens = None;
    for line in reader.lines() {
        let line = line.map_err(|e| format!("provider {} stream read: {e}", provider.name))?;
        let line = line.trim();
        if line.is_empty() || line.starts_with(':') {
            continue;
        }
        let Some(data) = line.strip_prefix("data:") else {
            continue;
        };
        let data = data.trim();
        if data == "[DONE]" {
            break;
        }
        let value: Value = serde_json::from_str(data)
            .map_err(|e| format!("provider {} SSE JSON: {e}: {data}", provider.name))?;
        if let Some(usage) = value.get("usage") {
            prompt_tokens = usage.get("prompt_tokens").and_then(|v| v.as_u64());
            completion_tokens = usage.get("completion_tokens").and_then(|v| v.as_u64());
        }
        let piece = value
            .pointer("/choices/0/delta/content")
            .and_then(|v| v.as_str())
            .unwrap_or("");
        if !piece.is_empty() {
            tx.send(Ok(StreamDelta {
                text: piece.to_string(),
                prompt_tokens: None,
                completion_tokens: None,
                done: false,
            }))
            .map_err(|_| "provider stream closed".to_string())?;
        }
    }
    tx.send(Ok(StreamDelta {
        text: String::new(),
        prompt_tokens,
        completion_tokens,
        done: true,
    }))
    .map_err(|_| "provider stream closed".to_string())?;
    Ok(())
}

pub fn parse_providers_toml(text: &str) -> Result<Vec<Provider>, String> {
    let mut out = Vec::new();
    let mut current: Option<ProviderBuilder> = None;
    let mut default_name: Option<String> = None;
    for raw in text.lines() {
        let line = raw.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if line == "[[provider]]" {
            if let Some(b) = current.take() {
                out.push(b.finish()?);
            }
            current = Some(ProviderBuilder::default());
            continue;
        }
        let Some(eq) = line.find('=') else {
            return Err(format!("providers.toml: expected key = value, got {line}"));
        };
        let key = line[..eq].trim();
        let value = line[eq + 1..].trim();
        let b = current
            .as_mut()
            .ok_or_else(|| "providers.toml: key outside [[provider]]".to_string())?;
        match key {
            "name" => b.name = Some(unquote(value)),
            "base_url" => b.base_url = Some(unquote(value)),
            "api_key" => b.api_key = unquote(value),
            "api_key_env" => {
                let env_name = unquote(value);
                if let Ok(v) = std::env::var(&env_name) {
                    b.api_key = v;
                }
            }
            "default" => {
                if value == "true" {
                    default_name = b.name.clone();
                }
            }
            "models" => b.models = parse_string_array(value)?,
            _ => {}
        }
    }
    if let Some(b) = current.take() {
        out.push(b.finish()?);
    }
    if let Some(name) = default_name {
        if let Some(idx) = out.iter().position(|p| p.name == name) {
            let chosen = out.remove(idx);
            out.insert(0, chosen);
        }
    }
    Ok(out)
}

#[derive(Default)]
struct ProviderBuilder {
    name: Option<String>,
    base_url: Option<String>,
    api_key: String,
    models: Vec<String>,
}

impl ProviderBuilder {
    fn finish(self) -> Result<Provider, String> {
        Ok(Provider {
            name: self.name.ok_or("providers.toml: missing name")?,
            base_url: self.base_url.ok_or("providers.toml: missing base_url")?,
            api_key: self.api_key,
            models: self.models,
        })
    }
}

fn unquote(v: &str) -> String {
    let v = v.trim();
    if let Some(inner) = v.strip_prefix('"').and_then(|s| s.strip_suffix('"')) {
        inner.to_string()
    } else {
        v.to_string()
    }
}

fn parse_string_array(v: &str) -> Result<Vec<String>, String> {
    let v = v.trim();
    let inner = v
        .strip_prefix('[')
        .and_then(|s| s.strip_suffix(']'))
        .ok_or_else(|| format!("providers.toml: expected array, got {v}"))?;
    Ok(inner
        .split(',')
        .map(|s| unquote(s.trim()))
        .filter(|s| !s.is_empty())
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_example_providers() {
        let text = r#"
[[provider]]
name = "manifold"
base_url = "http://mini.local:8317/v1"
api_key = ""
models = ["claude-sonnet", "gpt-5-codex"]
default = true
"#;
        let list = parse_providers_toml(text).unwrap();
        assert_eq!(list[0].name, "manifold");
        assert_eq!(list[0].models.len(), 2);
    }

    #[test]
    fn openai_client_reads_sse() {
        use std::io::{Read, Write};
        use std::net::TcpListener;

        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let port = listener.local_addr().unwrap().port();
        thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            let mut buf = [0u8; 4096];
            let _ = stream.read(&mut buf);
            let body = "data: {\"choices\":[{\"delta\":{\"content\":\"Hello from gateway\"}}]}\n\ndata: [DONE]\n\n";
            let resp = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                body.len(),
                body
            );
            let _ = stream.write_all(resp.as_bytes());
        });

        let provider = Provider {
            name: "mock".into(),
            base_url: format!("http://127.0.0.1:{port}/v1"),
            api_key: "sk-test".into(),
            models: vec!["mock-model".into()],
        };
        let (tx, rx) = mpsc::channel();
        stream_chat(
            &provider,
            "mock-model",
            vec![ChatMessage {
                role: "user".into(),
                content: "hi".into(),
            }],
            tx,
        );
        let mut text = String::new();
        let mut done = false;
        while let Ok(item) = rx.recv_timeout(Duration::from_secs(3)) {
            let delta = item.unwrap();
            text.push_str(&delta.text);
            if delta.done {
                done = true;
                break;
            }
        }
        assert!(done, "stream never finished; got {text:?}");
        assert!(text.contains("Hello from gateway"), "got {text:?}");
    }
}
