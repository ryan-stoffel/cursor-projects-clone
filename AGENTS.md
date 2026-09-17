# Agent instructions

This file is the source of instructions for coding agents (including Claude Code; see [CLAUDE.md](./CLAUDE.md)). Humans should read [CONTRIBUTING.md](./CONTRIBUTING.md) and [SPEC.md](./SPEC.md).

## Before writing code

1. Read [SPEC.md](./SPEC.md) fully. The milestone completion criterion is the definition of done.
2. Open or reuse a GitHub issue. Do not start work without an issue number.
3. Branch from latest `develop` using `type/<issue-number>-<short-name>` (see [docs/git-workflow.md](./docs/git-workflow.md)).
4. Do not start a milestone until the previous one passes its criterion.

## Names

Working name is TBD. Until then:

- Daemon binary and Cargo workspace: `projectd`
- macOS app target: `Projects`
- Bundle id: `dev.projectd.Projects`

Do not use a competing product's name in any name, identifier, or bundle id.

## Architecture

Two programs. `Projects.app` is a SwiftUI client: it renders and sends JSON-RPC commands. It contains no business logic. `projectd` owns SQLite, the coordinator, dispatch, worktrees, and model calls.

Local mode runs control and agent in one process. Remote workers are `projectd --role agent` reached over SSH. The app never stores keys or passwords.

## Rust

- Edition 2021, stable toolchain (`rust-toolchain.toml`).
- Allowed crates: `tokio`, `rusqlite` (bundled), `serde`, `serde_json`, one HTTP client (`reqwest` with rustls, or `ureq`). `axum` is added at M5 only. Any other crate needs a one-line justification in the PR description.
- `crates/protocol` has zero dependencies beyond `serde`.
- Build targets: `aarch64-apple-darwin` and `x86_64-unknown-linux-gnu`. CI builds both.
- Shell out to `git`, `rsync`, and `ssh`. Do not link libgit2 or an SSH crate.
- Errors must include enough context to act: which task, which machine, which command, exit code, and stderr tail.

## Swift

- SwiftUI for all views except the transcript and the diff. Those two are AppKit (`NSTextView`, `NSTableView`) wrapped in `NSViewRepresentable`, from the first commit that renders them. Streamed tokens append to `NSTextStorage`; a SwiftUI `Text` is never rebuilt per token.
- No third-party Swift packages in v1.
- macOS 15 or later.
- `Projects/Protocol` Codable types are hand-kept in sync with `crates/protocol`. When one changes, the other changes in the same PR.

## Style

- Comments only where the logic is not obvious from the code.
- No emoji anywhere (code, comments, commit messages, issue titles, PR bodies, CI output).
- Do not add product features beyond the issue you are on.

## GitHub workflow

- Issues first. The PR template and CI require a linked GitHub issue number.
- Target `develop` unless the issue is a release or hotfix for `main`.
- Fill in `.github/PULL_REQUEST_TEMPLATE.md`. Use `Closes #N`.
- Workers without a Mac: GitHub Actions `macos-15` is the compiler. Do not claim the app builds until that job is green.

## Open decisions

Do not guess. Ask the user before the affected milestone:

- Product name.
- Whether `projectd` is shared with Roster. If yes, `Projects/Protocol` becomes a shared Swift package (affects M0 layout).
- Whether the gateway reports per-subscription usage, or the daemon counts tokens (affects M4).
- The list of UI changes from the reference Projects layout (affects M3).
