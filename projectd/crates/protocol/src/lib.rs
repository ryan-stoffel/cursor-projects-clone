//! Shared protocol types. Zero runtime dependencies beyond `serde`.
//! Codable mirrors live in `Projects/Projects/Protocol` and must change in the same PR.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MachineKind {
    Local,
    Ssh,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Machine {
    pub id: String,
    pub name: String,
    pub kind: MachineKind,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ssh_host: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ssh_user: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ssh_port: Option<u16>,
    pub workspace_root: String,
    pub max_parallel: u32,
    pub status: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Project {
    pub id: String,
    pub name: String,
    pub repo_url: String,
    pub default_branch: String,
    pub primary_machine_id: String,
    pub coordinator_model: String,
    pub worker_model: String,
    pub created_at: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Thread {
    pub id: String,
    pub project_id: String,
    pub rolling_summary: String,
    pub pinned_facts: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MessageRole {
    User,
    Coordinator,
    System,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Message {
    pub id: String,
    pub thread_id: String,
    pub role: MessageRole,
    pub content: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub card: Option<String>,
    pub created_at: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TaskStatus {
    Queued,
    Running,
    Blocked,
    Review,
    Merged,
    Discarded,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Task {
    pub id: String,
    pub project_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent_task_id: Option<String>,
    pub title: String,
    pub spec: String,
    pub status: TaskStatus,
    pub machine_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub worktree_path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub branch: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result_summary: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AgentRun {
    pub id: String,
    pub task_id: String,
    pub model: String,
    pub backend: String,
    pub started_at: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ended_at: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt_tokens: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub completion_tokens: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exit_reason: Option<String>,
    pub transcript_path: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ContextKind {
    Research,
    Artifact,
    Convention,
    TestRecipe,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ContextEntry {
    pub id: String,
    pub project_id: String,
    pub path: String,
    pub kind: ContextKind,
    pub author: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TriggerKind {
    Schedule,
    Webhook,
    RepoEvent,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Trigger {
    pub id: String,
    pub project_id: String,
    pub kind: TriggerKind,
    pub config: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_fired_at: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ExitReason {
    Finished,
    Cancelled,
    Timeout,
    Error,
    ModelRefused,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProjectCreateParams {
    pub name: String,
    pub repo_url: String,
    pub default_branch: String,
    pub primary_machine_id: String,
    pub coordinator_model: String,
    pub worker_model: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ThreadSendParams {
    pub project_id: String,
    pub content: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ThreadGetParams {
    pub project_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub after_message_id: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MessageDeltaEvent {
    pub message_id: String,
    pub text: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MessageAppendedEvent {
    pub message: Message,
}

/// JSON-RPC method names (client to control). Implemented from M0.
pub mod methods {
    pub const MACHINE_LIST: &str = "machine.list";
    pub const MACHINE_ADD: &str = "machine.add";
    pub const MACHINE_INSTALL: &str = "machine.install";
    pub const PROJECT_LIST: &str = "project.list";
    pub const PROJECT_CREATE: &str = "project.create";
    pub const PROJECT_SET_PRIMARY: &str = "project.set_primary";
    pub const THREAD_GET: &str = "thread.get";
    pub const THREAD_SEND: &str = "thread.send";
    pub const THREAD_STEER: &str = "thread.steer";
    pub const TASK_LIST: &str = "task.list";
    pub const TASK_GET: &str = "task.get";
    pub const TASK_MERGE: &str = "task.merge";
    pub const TASK_REQUEST_CHANGES: &str = "task.request_changes";
    pub const TASK_DISCARD: &str = "task.discard";
    pub const TASK_PIN: &str = "task.pin";
    pub const TASK_CANCEL: &str = "task.cancel";
    pub const TASK_DIFF: &str = "task.diff";
    pub const CONTEXT_LIST: &str = "context.list";
    pub const CONTEXT_READ: &str = "context.read";
    pub const CONTEXT_WRITE: &str = "context.write";
    pub const USAGE_PROJECT: &str = "usage.project";
}

/// JSON-RPC notification names (control to client).
pub mod events {
    pub const MESSAGE_APPENDED: &str = "message.appended";
    pub const MESSAGE_DELTA: &str = "message.delta";
    pub const TASK_UPDATED: &str = "task.updated";
    pub const RUN_DELTA: &str = "run.delta";
    pub const MACHINE_UPDATED: &str = "machine.updated";
    pub const MACHINE_INSTALL_PROGRESS: &str = "machine.install.progress";
    pub const USAGE_UPDATED: &str = "usage.updated";
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn task_status_wire_names() {
        let json = serde_json::to_string(&TaskStatus::Queued).unwrap();
        assert_eq!(json, "\"queued\"");
        let back: TaskStatus = serde_json::from_str(&json).unwrap();
        assert_eq!(back, TaskStatus::Queued);
    }

    #[test]
    fn method_names_are_stable() {
        assert_eq!(methods::PROJECT_CREATE, "project.create");
        assert_eq!(events::MESSAGE_DELTA, "message.delta");
    }

    #[test]
    fn project_create_params_roundtrip() {
        let p = ProjectCreateParams {
            name: "Demo".into(),
            repo_url: "https://example.com/repo.git".into(),
            default_branch: "main".into(),
            primary_machine_id: "local".into(),
            coordinator_model: "stub".into(),
            worker_model: "stub".into(),
        };
        let json = serde_json::to_string(&p).unwrap();
        assert!(json.contains("repo_url"));
        let back: ProjectCreateParams = serde_json::from_str(&json).unwrap();
        assert_eq!(back.name, "Demo");
    }
}
