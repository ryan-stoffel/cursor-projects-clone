CREATE TABLE machines (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,
    ssh_host TEXT,
    ssh_user TEXT,
    ssh_port INTEGER,
    workspace_root TEXT NOT NULL,
    max_parallel INTEGER NOT NULL DEFAULT 3,
    status TEXT NOT NULL
);

CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    repo_url TEXT NOT NULL,
    default_branch TEXT NOT NULL,
    primary_machine_id TEXT NOT NULL,
    coordinator_model TEXT NOT NULL,
    worker_model TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (primary_machine_id) REFERENCES machines(id)
);

CREATE TABLE threads (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL UNIQUE,
    rolling_summary TEXT NOT NULL DEFAULT '',
    pinned_facts TEXT NOT NULL DEFAULT '[]',
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    thread_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    card TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (thread_id) REFERENCES threads(id)
);

CREATE INDEX messages_thread_id ON messages(thread_id);

CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    parent_task_id TEXT,
    title TEXT NOT NULL,
    spec TEXT NOT NULL,
    status TEXT NOT NULL,
    machine_id TEXT NOT NULL,
    worktree_path TEXT,
    branch TEXT,
    result_summary TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

CREATE TABLE agent_runs (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    model TEXT NOT NULL,
    backend TEXT NOT NULL,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    exit_reason TEXT,
    transcript_path TEXT NOT NULL,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

CREATE TABLE context_entries (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    path TEXT NOT NULL,
    kind TEXT NOT NULL,
    author TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

CREATE TABLE triggers (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    kind TEXT NOT NULL,
    config TEXT NOT NULL,
    last_fired_at TEXT,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

INSERT INTO machines (id, name, kind, workspace_root, max_parallel, status)
VALUES ('local', 'This Mac', 'local', '', 3, 'online');
