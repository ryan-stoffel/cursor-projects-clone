//! projectd: `--role control|agent|both`. JSON-RPC over a unix socket.

use std::time::Duration;

fn print_help() {
    eprintln!(
        "\
projectd --role control|agent|both

Roles:
  control   SQLite, coordinator, JSON-RPC server
  agent     worktrees, worker loop, context sync (M1)
  both      local mode (default)

Environment:
  PROJECTD_HOME            data and socket directory
  PROJECTD_SQLITE          sqlite path
  PROJECTD_SOCKET          unix socket path
  PROJECTD_PROVIDERS_FILE  providers.toml path
  PROJECTD_STUB_PROVIDER=1 canned coordinator replies (CI / no gateway)"
    );
}

fn parse_role(args: &[String]) -> Result<&'static str, String> {
    let mut role = "both";
    let mut i = 0;
    while i < args.len() {
        let arg = &args[i];
        if arg == "--help" || arg == "-h" {
            return Ok("help");
        }
        if let Some(value) = arg.strip_prefix("--role=") {
            role = match value {
                "control" => "control",
                "agent" => "agent",
                "both" => "both",
                other => return Err(format!("unknown --role {other}")),
            };
            i += 1;
            continue;
        }
        if arg == "--role" {
            let value = args
                .get(i + 1)
                .ok_or_else(|| "missing value for --role".to_string())?;
            role = match value.as_str() {
                "control" => "control",
                "agent" => "agent",
                "both" => "both",
                other => return Err(format!("unknown --role {other}")),
            };
            i += 2;
            continue;
        }
        return Err(format!("unknown argument {arg}"));
    }
    Ok(role)
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match parse_role(&args) {
        Ok("help") => print_help(),
        Ok("agent") => {
            eprintln!(
                "projectd agent role has no worker loop until M1; sleeping so a supervisor can keep the process."
            );
            loop {
                tokio::time::sleep(Duration::from_secs(3600)).await;
            }
        }
        Ok(_) => {
            let provider = match projectd_control::load_default() {
                Ok(p) => p,
                Err(err) => {
                    eprintln!("projectd: {err}");
                    eprintln!(
                        "Copy projectd/providers.toml.example to the providers path, or set PROJECTD_STUB_PROVIDER=1."
                    );
                    std::process::exit(1);
                }
            };
            let cfg = projectd_control::ControlConfig {
                sqlite: projectd_control::paths::sqlite_path(),
                socket: projectd_control::paths::socket_path(),
                provider,
            };
            eprintln!(
                "projectd control listening on {} (sqlite {})",
                cfg.socket.display(),
                cfg.sqlite.display()
            );
            if let Err(err) = projectd_control::serve(cfg).await {
                eprintln!("projectd: {err}");
                std::process::exit(1);
            }
        }
        Err(err) => {
            eprintln!("projectd: {err}");
            print_help();
            std::process::exit(2);
        }
    }
}

#[cfg(test)]
mod tests {
    fn parse(args: &[&str]) -> Result<&'static str, String> {
        let owned: Vec<String> = args.iter().map(|s| (*s).to_string()).collect();
        super::parse_role(&owned)
    }

    #[test]
    fn default_is_both() {
        assert_eq!(parse(&[]).unwrap(), "both");
    }

    #[test]
    fn role_flag() {
        assert_eq!(parse(&["--role", "control"]).unwrap(), "control");
        assert_eq!(parse(&["--role=agent"]).unwrap(), "agent");
    }
}
