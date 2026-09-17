# Spec: open-source Cursor Projects alternative

Audience: a coding agent starting this repo from empty. Read fully before writing code. Work the milestones in order; each has a completion criterion, and the criterion is the definition of done.

Working name: TBD. Until named, the daemon binary is `projectd`, the Cargo workspace is `projectd`, and the macOS app target is `Projects`. Do not use "Cursor" in any name, identifier, or bundle id.

## 1. What this is

A macOS desktop app that reproduces the Cursor Projects workflow: one coordinator chat per project that plans, delegates to parallel subagents, keeps shared context across months, and brings finished work back for review. Two differences from Cursor:

1. The execution machine is the user's: this Mac, or any host reachable over SSH.
2. Every model call goes through the user's own gateway (Manifold, an OpenAI-compatible endpoint), so Claude, Codex, and Cursor subscriptions are pooled outside this app.

Not a code editor. Files open in the user's existing editor. No hosted cloud, no multi-user, no billing, no computer use.

## 2. Architecture

Two programs.

- `projectd`: one Rust binary with two roles, `control` and `agent`, selected by flag. Local mode runs both in one process.
- `Projects.app`: SwiftUI client. Renders and sends commands. No business logic. Ships `projectd` inside the bundle and starts it in local mode on launch if none is running.

```
Projects.app (SwiftUI) --JSON-RPC over unix socket or SSH tunnel--> projectd control
                                                                        |-- SQLite
                                                                        |-- coordinator loop
                                                                        |-- dispatch --> projectd agent (same process, or over SSH on another host)
                                                                                           |-- git worktree per task
                                                                                           |-- worker loop per task
                                                                                           |-- .context/ sync (rsync)
                                                              all LLM calls --> Manifold (OpenAI-compatible) --> subscriptions
```

Control role owns: SQLite, projects, coordinator thread, tasks, agent runs, triggers, dispatch, the JSON-RPC server, the coordinator loop.

Agent role owns: worktrees, branches, worker loops, the local `.context/` copy, rsync.

Remote machine: `projectd agent` installed as a launchd or systemd service. Control on the primary host reaches it over SSH using the user's `~/.ssh/config`. The app never stores keys or passwords.

Pinned task on a secondary machine: control rsyncs the worktree and `.context/` over, runs the worker through one SSH session, rsyncs results back. If the session drops, the task goes to `blocked` and the partial transcript is kept.

## 3. Repo layout

```
projectd/                 Cargo workspace
  crates/
    protocol/             serde types: every RPC request, response, event, and entity. No logic.
    control/              SQLite, coordinator loop, dispatch, JSON-RPC server
    agent/                worktrees, worker loop, context sync
    daemon/               binary: parses --role, hosts control, agent, or both
  Cargo.toml
Projects/                 Xcode project, SwiftUI
  Projects/
    Protocol/             Codable mirrors of crates/protocol, one file per type, kept in sync by hand
    Views/
    Client/               socket connection, SSH tunnel, RPC client
  Projects.xcodeproj
scripts/
  install-remote.sh       scp binary + service unit to a host
SPEC.md                   this file
```

## 4. Constraints

Rust

- Edition 2021, stable toolchain.
- Crates allowed: `tokio`, `rusqlite` (bundled feature), `serde`, `serde_json`, one HTTP client (`reqwest` with rustls, or `ureq`). `axum` is added at M5 only. Any other crate needs a one-line justification in the PR description.
- Build targets: `aarch64-apple-darwin` and `x86_64-unknown-linux-gnu`. CI cross-compiles both.
- `protocol` has zero dependencies beyond `serde`.

Swift

- SwiftUI for all views except the transcript and the diff. Those two are AppKit (`NSTextView`, `NSTableView`) wrapped in `NSViewRepresentable`, from the first commit that renders them. Streamed tokens append to `NSTextStorage`; a SwiftUI `Text` is never rebuilt per token.
- No third-party Swift packages in v1.
- macOS 15 or later.

Both

- Comments only where the logic is not obvious from the code. No emoji anywhere.
- Shell out to `git`, `rsync`, and `ssh` binaries. Do not link libgit2 or an SSH crate.
- Errors carry enough context to act on: which task, which machine, which command, its exit code and stderr tail.

## 5. Data model

One SQLite file per control role at `~/Library/Application Support/projectd/projectd.sqlite` on macOS, `~/.local/share/projectd/projectd.sqlite` on Linux. Migrations are numbered SQL files applied at startup.

| Table | Columns |
| --- | --- |
| `machines` | `id`, `name`, `kind` (`local` or `ssh`), `ssh_host`, `ssh_user`, `ssh_port`, `workspace_root`, `max_parallel` (default 3), `status` |
| `projects` | `id`, `name`, `repo_url`, `default_branch`, `primary_machine_id`, `coordinator_model`, `worker_model`, `created_at` |
| `threads` | `id`, `project_id`, `rolling_summary`, `pinned_facts` (JSON) |
| `messages` | `id`, `thread_id`, `role` (`user`, `coordinator`, `system`), `content`, `card` (JSON, nullable), `created_at` |
| `tasks` | `id`, `project_id`, `parent_task_id`, `title`, `spec`, `status`, `machine_id`, `worktree_path`, `branch`, `result_summary`, `created_at`, `updated_at` |
| `agent_runs` | `id`, `task_id`, `model`, `backend`, `started_at`, `ended_at`, `prompt_tokens`, `completion_tokens`, `exit_reason`, `transcript_path` |
| `context_entries` | `id`, `project_id`, `path`, `kind` (`research`, `artifact`, `convention`, `test_recipe`), `author`, `updated_at` |
| `triggers` | `id`, `project_id`, `kind` (`schedule`, `webhook`, `repo_event`), `config` (JSON), `last_fired_at` |

Task status: `queued`, `running`, `blocked`, `review`, `merged`, `discarded`. Transitions:

```
queued -> running -> review -> merged
                  -> blocked -> running
                  -> review -> queued   (user chose Changes; spec gets the note appended)
any    -> discarded
```

Context store: `<workspace_root>/<project>/.context/`, a plain folder of Markdown and files. `context_entries` is an index of it, rebuilt by scanning the folder. Agents read the index at start and append entries at finish. Control rsyncs the folder to a secondary machine before a run and back after.

Transcripts are files under `<workspace_root>/<project>/runs/<run_id>.jsonl`, one JSON object per model call or tool call. The database stores the path only.

## 6. Protocol

JSON-RPC 2.0, newline-delimited, over a unix socket at `~/Library/Application Support/projectd/projectd.sock` (Linux: `$XDG_RUNTIME_DIR/projectd.sock`). Server pushes events as notifications on the same connection.

Methods (client to control):

| Method | Params | Returns |
| --- | --- | --- |
| `machine.list` | | `[Machine]` |
| `machine.add` | `name, ssh_host, ssh_user, ssh_port?` | `Machine` |
| `machine.install` | `machine_id` | streams `machine.install.progress` events, then `Machine` |
| `project.list` | | `[Project]` |
| `project.create` | `name, repo_url, default_branch, primary_machine_id, coordinator_model, worker_model` | `Project` |
| `project.set_primary` | `project_id, machine_id` | `Project` |
| `thread.get` | `project_id, after_message_id?` | `[Message]` |
| `thread.send` | `project_id, content` | `Message` (the user message; coordinator replies arrive as events) |
| `thread.steer` | `project_id, content` | `Message` (pauses new task creation, delivers, coordinator revises) |
| `task.list` | `project_id` | `[Task]` |
| `task.get` | `task_id` | `Task` plus `[AgentRun]` |
| `task.merge` | `task_id` | `Task` |
| `task.request_changes` | `task_id, note` | `Task` |
| `task.discard` | `task_id` | `Task` |
| `task.pin` | `task_id, machine_id` | `Task` |
| `task.cancel` | `task_id` | `Task` |
| `task.diff` | `task_id` | `{ base, head, stat, unified }` |
| `context.list` | `project_id` | `[ContextEntry]` |
| `context.read` | `project_id, path` | `{ content }` |
| `context.write` | `project_id, path, content` | `ContextEntry` |
| `usage.project` | `project_id, since?` | `[{ model, prompt_tokens, completion_tokens }]` |

Events (control to client):

`message.appended`, `message.delta` (streaming coordinator text), `task.updated`, `run.delta` (streaming worker transcript line), `machine.updated`, `machine.install.progress`, `usage.updated`.

Every type in the tables above is a struct in `crates/protocol` and a `Codable` in `Projects/Protocol`. When one changes, the other changes in the same PR.

## 7. Coordinator loop

One long-running conversation per project, run by control. Model: `projects.coordinator_model`. The system prompt states the role: plan, delegate, review, never edit code. Each turn is built from: the rolling summary, pinned facts, the last N messages, and the `.context/` index.

Tools available to the coordinator, and nothing else:

| Tool | Effect |
| --- | --- |
| `read_context(path)` | Returns a context entry |
| `read_repo(path, ref?)` | Returns a file from the project branch |
| `search_repo(query)` | grep over the project branch |
| `create_task(title, spec, machine_id?, model?, parent_task_id?)` | Inserts a `queued` task |
| `wait_task(task_id)` | Blocks the turn until the task leaves `running` |
| `read_task(task_id)` | Returns task, result summary, diff stat |
| `write_context(path, kind, content)` | Writes an entry, authored as `coordinator` |
| `ask_user(question)` | Appends a message card and ends the turn |

The coordinator has no shell and no file write. When a task returns, the coordinator reads it, writes what was learned to `.context/`, and either creates follow-up tasks or moves the task to `review` with a summary card in the thread.

## 8. Worker loop

Run by agent, one per task, capped by `machines.max_parallel`. Model: task override, else `projects.worker_model`.

Setup: `git worktree add <workspace_root>/<project>/wt/<task_id> -b task/<task_id> <default_branch>`. Copy the `.context/` index into the prompt.

Tools:

| Tool | Effect |
| --- | --- |
| `read_file(path)`, `write_file(path, content)`, `list_dir(path)` | Scoped to the worktree; paths outside it are rejected |
| `run_shell(cmd, timeout_s)` | `cwd` is the worktree; stdout, stderr, exit code returned; 10 minute default timeout |
| `run_tests(cmd?)` | Same as `run_shell`, tagged for the transcript |
| `append_context(path, kind, content)` | Writes to `.context/`, authored as `worker:<task_id>` |
| `finish(summary)` | Commits all changes to the task branch and ends the run |

Exit reasons: `finished`, `cancelled`, `timeout`, `error`, `model_refused`. Anything but `finished` moves the task to `blocked` with the reason on the run.

Worker backend is a trait: `fn run(task, worktree, model) -> RunResult`. v1 implements `BuiltIn` (the loop above). `VendorCli` (Claude Code, Codex CLI headless) is M6.

Every model call and tool call is one line in the run's `.jsonl` transcript.

## 9. Model access

One config file: `~/Library/Application Support/projectd/providers.toml`.

```toml
[[provider]]
name = "manifold"
base_url = "http://mini.local:8317/v1"
api_key = ""
models = ["claude-sonnet", "gpt-5-codex", "cursor-composer"]
default = true

[[provider]]
name = "anthropic-direct"
base_url = "https://api.anthropic.com/v1"
api_key_env = "ANTHROPIC_API_KEY"
models = ["claude-sonnet"]
```

The daemon speaks the OpenAI chat completions API with tool calling and streaming to every provider. No vendor SDK. Token counts from each response are written to `agent_runs`.

## 10. Performance targets

Measured on a Mac mini before M3 is called done. Add a `scripts/perf/` harness that reproduces each.

| Target | Budget |
| --- | --- |
| Frame time on a 120 Hz display while a transcript streams | Under 8 ms, zero dropped frames over 60 s |
| Keystroke to glyph in the composer | Under 16 ms |
| Cold start to usable window | Under 300 ms |
| `task.list` round trip over the local socket, 200 tasks | Under 5 ms |
| Diff render, 5,000 changed lines | Under 100 ms |
| Memory at idle, one project open | Under 150 MB |

## 11. UI

Three-pane window. Left nav: projects grouped by machine, then Machines, then Settings. Center: coordinator thread. Right: task panel, collapsible.

| Surface | Contents | Interactions |
| --- | --- | --- |
| Left nav | Projects, Machines, Settings | New project; machine status dot; drag project onto machine to set primary |
| Thread | Chat with the coordinator. Task creation, delegation, and results are inline cards. | Send, steer, approve plan, request changes |
| Task panel | Kanban by status. Card shows machine, model, branch, elapsed. | Click opens detail; drag reorders queued |
| Task detail | Spec, live transcript, diff against base, test output, context entries written | Merge, Changes, Discard, Open worktree in editor |
| Run-on picker | Menu in thread header listing machines | Sets project primary; per-task pin lives in task detail |
| Context browser | Tree of `.context/` with Markdown preview | Edit; syncs on next run |
| Usage strip | Tokens per model, this project, this week | Click for per-run breakdown |

Review card: when a task enters `review`, the thread shows summary, diff stat, and three buttons: Merge, Changes, Discard. Merge rebases the task branch onto the project branch and fast-forwards. Changes reopens the task with the note appended to its spec. The user ships a task without leaving the thread.

Steering: a message sent while the coordinator is delegating pauses new task creation, delivers the message, and lets the coordinator revise. Running workers keep running unless cancelled from the task panel.

## 12. Milestones

Work in order. Do not start a milestone until the previous criterion passes. M0 through M2 use a CLI test client (`projectd-cli`, a small binary in `crates/daemon` behind a feature flag) so the SwiftUI client is built once against a stable protocol.

| Milestone | Build | Done when |
| --- | --- | --- |
| M0 | Workspace, `protocol` types, migrations, JSON-RPC server, `project.create`, `thread.send` against a configured provider, `projectd-cli`. Separately, a two-day SwiftUI spike: a streaming `NSTextView` transcript and a 10,000-row list. | `projectd-cli send` round-trips a message through the provider and it is stored in `messages`. The spike holds 8 ms frames on a 120 Hz display. |
| M1 | Coordinator loop with its tools, `BuiltIn` worker, worktree per task, all task transitions, `task.merge`, `task.request_changes`, `task.discard`, transcripts | On a real repo, one `thread.send` produces 2 tasks that run in parallel in separate worktrees and both merge cleanly to the default branch. |
| M2 | `machine.add`, `machine.install` via `scripts/install-remote.sh`, SSH tunnel in the CLI client, `.context/` store, index, and rsync sync, `task.pin` | CLI on one Mac drives a project whose control and workers run on a second host; the first Mac sleeps for 10 minutes; the tasks finish and appear on wake. |
| M3 | SwiftUI client: every surface in section 11, bundled `projectd` autostart | A full day of real work with no CLI use; all six performance targets pass in the harness. |
| M4 | Usage accounting and strip, `thread.steer`, `task.cancel`, transcript viewer | A week of real work with no daemon restarts. |
| M5 | `axum` endpoint for triggers; `schedule` and GitHub PR triggers | The coordinator opens a task from a PR comment without a user prompt. |
| M6 | `VendorCli` backend for Claude Code and Codex CLI | A task runs end to end on a vendor CLI and merges. |

First real project for dogfooding after M1: this repo.

## 13. Open decisions

Decide these before the affected milestone. Ask the user; do not guess.

- Name.
- Whether `projectd` is shared with Roster (a separate SwiftUI app). If yes, `Projects/Protocol` becomes a shared Swift package. Affects M0 repo layout.
- Whether Manifold reports per-subscription usage, or the daemon counts tokens itself. Affects M4.
- The list of UI changes from Cursor's layout. Affects M3.

## 14. Sources

- Cursor Projects: https://cursor.com/changelog/projects
- Cursor self-hosted machines: https://cursor.com/changelog/self-hosted-machines
