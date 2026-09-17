use projectd_protocol::{Machine, MachineKind, Message, MessageRole, Project};
use rusqlite::{params, Connection, Row};
use std::path::Path;
use std::time::Duration;

const MIGRATIONS: &[(i32, &str)] = &[(1, include_str!("../migrations/001_init.sql"))];

pub fn open(path: &Path) -> Result<Connection, String> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .map_err(|e| format!("create data dir {}: {e}", parent.display()))?;
    }
    let conn =
        Connection::open(path).map_err(|e| format!("open sqlite {}: {e}", path.display()))?;
    conn.busy_timeout(Duration::from_secs(5))
        .map_err(|e| format!("sqlite busy_timeout: {e}"))?;
    conn.execute_batch("PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;")
        .map_err(|e| format!("sqlite pragma: {e}"))?;
    apply_migrations(&conn)?;
    Ok(conn)
}

pub fn ensure_local_workspace(conn: &Connection, root: &Path) -> Result<(), String> {
    std::fs::create_dir_all(root)
        .map_err(|e| format!("create workspace root {}: {e}", root.display()))?;
    let root_s = root.to_string_lossy();
    conn.execute(
        "UPDATE machines SET workspace_root = ?1
         WHERE id = 'local' AND (workspace_root IS NULL OR workspace_root = '')",
        params![root_s.as_ref()],
    )
    .map_err(|e| format!("set local workspace_root: {e}"))?;
    Ok(())
}

fn apply_migrations(conn: &Connection) -> Result<(), String> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            applied_at TEXT NOT NULL
        );",
    )
    .map_err(|e| format!("schema_migrations: {e}"))?;
    for (version, sql) in MIGRATIONS {
        let already: i64 = conn
            .query_row(
                "SELECT COUNT(*) FROM schema_migrations WHERE version = ?1",
                params![version],
                |row| row.get(0),
            )
            .map_err(|e| format!("read migrations: {e}"))?;
        if already > 0 {
            continue;
        }
        conn.execute_batch(sql)
            .map_err(|e| format!("migration {version}: {e}"))?;
        conn.execute(
            "INSERT INTO schema_migrations (version, applied_at) VALUES (?1, ?2)",
            params![version, crate::id::now_rfc3339()],
        )
        .map_err(|e| format!("record migration {version}: {e}"))?;
    }
    Ok(())
}

pub fn list_machines(conn: &Connection) -> Result<Vec<Machine>, String> {
    let mut stmt = conn
        .prepare(
            "SELECT id, name, kind, ssh_host, ssh_user, ssh_port, workspace_root, max_parallel, status
             FROM machines ORDER BY name",
        )
        .map_err(|e| format!("prepare machine.list: {e}"))?;
    let rows = stmt
        .query_map([], machine_from_row)
        .map_err(|e| format!("machine.list: {e}"))?;
    collect_rows(rows, "machine.list")
}

pub fn machine_exists(conn: &Connection, id: &str) -> Result<bool, String> {
    let n: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM machines WHERE id = ?1",
            params![id],
            |row| row.get(0),
        )
        .map_err(|e| format!("lookup machine {id}: {e}"))?;
    Ok(n > 0)
}

pub fn list_projects(conn: &Connection) -> Result<Vec<Project>, String> {
    let mut stmt = conn
        .prepare(
            "SELECT id, name, repo_url, default_branch, primary_machine_id,
                    coordinator_model, worker_model, created_at
             FROM projects ORDER BY created_at DESC",
        )
        .map_err(|e| format!("prepare project.list: {e}"))?;
    let rows = stmt
        .query_map([], project_from_row)
        .map_err(|e| format!("project.list: {e}"))?;
    collect_rows(rows, "project.list")
}

pub fn get_project(conn: &Connection, id: &str) -> Result<Project, String> {
    conn.query_row(
        "SELECT id, name, repo_url, default_branch, primary_machine_id,
                coordinator_model, worker_model, created_at
         FROM projects WHERE id = ?1",
        params![id],
        project_from_row,
    )
    .map_err(|e| format!("project {id}: {e}"))
}

pub fn create_project(
    conn: &Connection,
    name: &str,
    repo_url: &str,
    default_branch: &str,
    primary_machine_id: &str,
    coordinator_model: &str,
    worker_model: &str,
) -> Result<Project, String> {
    if !machine_exists(conn, primary_machine_id)? {
        return Err(format!(
            "primary_machine_id {primary_machine_id} does not exist"
        ));
    }
    let project = Project {
        id: crate::id::new_id("prj"),
        name: name.to_string(),
        repo_url: repo_url.to_string(),
        default_branch: default_branch.to_string(),
        primary_machine_id: primary_machine_id.to_string(),
        coordinator_model: coordinator_model.to_string(),
        worker_model: worker_model.to_string(),
        created_at: crate::id::now_rfc3339(),
    };
    conn.execute(
        "INSERT INTO projects (
            id, name, repo_url, default_branch, primary_machine_id,
            coordinator_model, worker_model, created_at
         ) VALUES (?1,?2,?3,?4,?5,?6,?7,?8)",
        params![
            project.id,
            project.name,
            project.repo_url,
            project.default_branch,
            project.primary_machine_id,
            project.coordinator_model,
            project.worker_model,
            project.created_at
        ],
    )
    .map_err(|e| format!("insert project: {e}"))?;
    let thread_id = crate::id::new_id("thr");
    conn.execute(
        "INSERT INTO threads (id, project_id, rolling_summary, pinned_facts)
         VALUES (?1, ?2, '', '[]')",
        params![thread_id, project.id],
    )
    .map_err(|e| format!("insert thread for project {}: {e}", project.id))?;
    Ok(project)
}

pub fn thread_id_for_project(conn: &Connection, project_id: &str) -> Result<String, String> {
    conn.query_row(
        "SELECT id FROM threads WHERE project_id = ?1",
        params![project_id],
        |row| row.get(0),
    )
    .map_err(|e| format!("no thread for project {project_id}: {e}"))
}

pub fn list_messages(
    conn: &Connection,
    project_id: &str,
    after_message_id: Option<&str>,
) -> Result<Vec<Message>, String> {
    let thread_id = thread_id_for_project(conn, project_id)?;
    let mut stmt = conn
        .prepare(
            "SELECT id, thread_id, role, content, card, created_at
             FROM messages WHERE thread_id = ?1
             ORDER BY created_at ASC, id ASC",
        )
        .map_err(|e| format!("prepare thread.get: {e}"))?;
    let rows = stmt
        .query_map(params![thread_id], message_from_row)
        .map_err(|e| format!("thread.get: {e}"))?;
    let mut out = collect_rows(rows, "thread.get")?;
    if let Some(after) = after_message_id {
        if let Some(pos) = out.iter().position(|m| m.id == after) {
            out = out.split_off(pos + 1);
        }
    }
    Ok(out)
}

pub fn insert_message(conn: &Connection, msg: &Message) -> Result<(), String> {
    conn.execute(
        "INSERT INTO messages (id, thread_id, role, content, card, created_at)
         VALUES (?1,?2,?3,?4,?5,?6)",
        params![
            msg.id,
            msg.thread_id,
            role_wire(msg.role),
            msg.content,
            msg.card,
            msg.created_at
        ],
    )
    .map_err(|e| format!("insert message {}: {e}", msg.id))?;
    Ok(())
}

fn collect_rows<T, E>(rows: impl Iterator<Item = Result<T, E>>, ctx: &str) -> Result<Vec<T>, String>
where
    E: std::fmt::Display,
{
    let mut out = Vec::new();
    for row in rows {
        out.push(row.map_err(|e| format!("{ctx}: {e}"))?);
    }
    Ok(out)
}

fn machine_from_row(row: &Row) -> rusqlite::Result<Machine> {
    let kind: String = row.get(2)?;
    Ok(Machine {
        id: row.get(0)?,
        name: row.get(1)?,
        kind: if kind == "ssh" {
            MachineKind::Ssh
        } else {
            MachineKind::Local
        },
        ssh_host: row.get(3)?,
        ssh_user: row.get(4)?,
        ssh_port: row
            .get::<_, Option<i64>>(5)?
            .map(|p| p.clamp(0, u16::MAX as i64) as u16),
        workspace_root: row.get(6)?,
        max_parallel: row.get::<_, i64>(7)? as u32,
        status: row.get(8)?,
    })
}

fn project_from_row(row: &Row) -> rusqlite::Result<Project> {
    Ok(Project {
        id: row.get(0)?,
        name: row.get(1)?,
        repo_url: row.get(2)?,
        default_branch: row.get(3)?,
        primary_machine_id: row.get(4)?,
        coordinator_model: row.get(5)?,
        worker_model: row.get(6)?,
        created_at: row.get(7)?,
    })
}

fn message_from_row(row: &Row) -> rusqlite::Result<Message> {
    let role: String = row.get(2)?;
    Ok(Message {
        id: row.get(0)?,
        thread_id: row.get(1)?,
        role: parse_role(&role),
        content: row.get(3)?,
        card: row.get(4)?,
        created_at: row.get(5)?,
    })
}

fn parse_role(s: &str) -> MessageRole {
    match s {
        "coordinator" => MessageRole::Coordinator,
        "system" => MessageRole::System,
        _ => MessageRole::User,
    }
}

fn role_wire(role: MessageRole) -> &'static str {
    match role {
        MessageRole::User => "user",
        MessageRole::Coordinator => "coordinator",
        MessageRole::System => "system",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_db() -> (std::path::PathBuf, Connection) {
        let dir = std::env::temp_dir().join(format!("projectd-db-{}", crate::id::new_id("t")));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("projectd.sqlite");
        let conn = open(&path).unwrap();
        (dir, conn)
    }

    #[test]
    fn init_migration_creates_local_machine() {
        let (dir, conn) = temp_db();
        let name: String = conn
            .query_row("SELECT name FROM machines WHERE id = 'local'", [], |row| {
                row.get(0)
            })
            .unwrap();
        assert_eq!(name, "This Mac");
        let _ = std::fs::remove_dir_all(dir);
    }

    #[test]
    fn create_project_and_thread() {
        let (dir, conn) = temp_db();
        ensure_local_workspace(&conn, &dir.join("ws")).unwrap();
        let p = create_project(
            &conn,
            "Demo",
            "https://example.com/repo.git",
            "main",
            "local",
            "stub",
            "stub",
        )
        .unwrap();
        assert_eq!(p.name, "Demo");
        let tid = thread_id_for_project(&conn, &p.id).unwrap();
        assert!(tid.starts_with("thr_"));
        assert!(get_project(&conn, "nope").is_err());
        let _ = std::fs::remove_dir_all(dir);
    }
}
