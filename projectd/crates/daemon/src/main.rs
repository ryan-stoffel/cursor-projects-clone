//! projectd: `--role control|agent|both`. JSON-RPC and coordinator loops start at M0.

fn print_help() {
    eprintln!(
        "\
projectd --role control|agent|both

Roles:
  control   SQLite, coordinator, JSON-RPC server
  agent     worktrees, worker loop, context sync
  both      local mode (default)

This binary is a scaffold until M0. See SPEC.md."
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

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match parse_role(&args) {
        Ok("help") => print_help(),
        Ok(role) => {
            println!(
                "projectd scaffold (role={role}; control={}; agent={}). JSON-RPC is not listening yet (M0).",
                projectd_control::role_name(),
                projectd_agent::role_name()
            );
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
