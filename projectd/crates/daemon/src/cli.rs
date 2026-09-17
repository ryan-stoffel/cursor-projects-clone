//! M0 CLI test client. Built with `--features cli`.

use projectd_control::client::RpcClient;
use projectd_protocol::{events, methods};
use serde_json::{json, Value};
use std::path::PathBuf;

#[tokio::main]
async fn main() {
    if let Err(err) = run().await {
        eprintln!("projectd-cli: {err}");
        std::process::exit(1);
    }
}

async fn run() -> Result<(), String> {
    let mut args: Vec<String> = std::env::args().skip(1).collect();
    if args.is_empty() || args.iter().any(|a| a == "--help" || a == "-h") {
        print_help();
        return Ok(());
    }
    let socket = take_socket(&mut args);
    if args.is_empty() {
        print_help();
        return Ok(());
    }
    let cmd = args.remove(0);
    let mut client = RpcClient::connect_retry(&socket, 40).await?;
    match cmd.as_str() {
        "machines" => {
            print_json(&client.call(methods::MACHINE_LIST, json!({})).await?)?;
        }
        "list" => {
            print_json(&client.call(methods::PROJECT_LIST, json!({})).await?)?;
        }
        "create" => {
            let name = flag(&args, "--name")?.ok_or("create requires --name")?;
            let repo = flag(&args, "--repo")?.unwrap_or_default();
            let branch = flag(&args, "--branch")?.unwrap_or_else(|| "main".into());
            let machine = flag(&args, "--machine")?.unwrap_or_else(|| "local".into());
            let coordinator = flag(&args, "--coordinator")?.unwrap_or_else(|| "stub".into());
            let worker = flag(&args, "--worker")?.unwrap_or_else(|| coordinator.clone());
            let project = client
                .call(
                    methods::PROJECT_CREATE,
                    json!({
                        "name": name,
                        "repo_url": repo,
                        "default_branch": branch,
                        "primary_machine_id": machine,
                        "coordinator_model": coordinator,
                        "worker_model": worker
                    }),
                )
                .await?;
            print_json(&project)?;
        }
        "thread" => {
            let project_id = flag(&args, "--project")?.ok_or("thread requires --project")?;
            let after = flag(&args, "--after")?;
            let mut params = json!({"project_id": project_id});
            if let Some(after) = after {
                params["after_message_id"] = json!(after);
            }
            print_json(&client.call(methods::THREAD_GET, params).await?)?;
        }
        "send" => {
            let project_id = flag(&args, "--project")?.ok_or("send requires --project")?;
            let content = flag(&args, "--content")?.ok_or("send requires --content")?;
            let user = client
                .call(
                    methods::THREAD_SEND,
                    json!({"project_id": project_id, "content": content}),
                )
                .await?;
            println!(
                "user {}",
                user.get("id").and_then(|v| v.as_str()).unwrap_or("?")
            );
            loop {
                let (method, params) = client.next_event().await?;
                if method == events::MESSAGE_DELTA {
                    if let Some(text) = params.get("text").and_then(|v| v.as_str()) {
                        eprint!("{text}");
                    }
                }
                if method == events::MESSAGE_APPENDED
                    && params.pointer("/message/role").and_then(|v| v.as_str())
                        == Some("coordinator")
                {
                    eprintln!();
                    if let Some(content) =
                        params.pointer("/message/content").and_then(|v| v.as_str())
                    {
                        println!("{content}");
                    }
                    break;
                }
            }
        }
        other => return Err(format!("unknown command {other}")),
    }
    Ok(())
}

fn take_socket(args: &mut Vec<String>) -> PathBuf {
    if let Some(i) = args.iter().position(|a| a == "--socket") {
        if i + 1 < args.len() {
            let path = PathBuf::from(&args[i + 1]);
            args.drain(i..i + 2);
            return path;
        }
    }
    if let Some(i) = args.iter().position(|a| a.starts_with("--socket=")) {
        let path = PathBuf::from(args[i].trim_start_matches("--socket="));
        args.remove(i);
        return path;
    }
    projectd_control::paths::socket_path()
}

fn flag(args: &[String], name: &str) -> Result<Option<String>, String> {
    if let Some(i) = args.iter().position(|a| a == name) {
        let v = args
            .get(i + 1)
            .ok_or_else(|| format!("missing value for {name}"))?;
        return Ok(Some(v.clone()));
    }
    let prefix = format!("{name}=");
    if let Some(a) = args.iter().find(|a| a.starts_with(&prefix)) {
        return Ok(Some(a[prefix.len()..].to_string()));
    }
    Ok(None)
}

fn print_json(v: &Value) -> Result<(), String> {
    println!(
        "{}",
        serde_json::to_string_pretty(v).map_err(|e| format!("encode: {e}"))?
    );
    Ok(())
}

fn print_help() {
    eprintln!(
        "\
projectd-cli [--socket PATH] <command>

commands:
  machines
  list
  create --name NAME [--repo URL] [--branch main] [--machine local] [--coordinator MODEL] [--worker MODEL]
  thread --project ID [--after MESSAGE_ID]
  send   --project ID --content TEXT

send writes coordinator tokens to stderr and the final message to stdout."
    );
}
