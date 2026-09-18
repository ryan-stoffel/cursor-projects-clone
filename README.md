# Foreman

Foreman is a macOS desktop app for coordinator-and-subagent project workflows. One coordinator chat per project plans work, delegates to parallel workers, keeps shared context, and brings finished branches back for review.

Two differences from hosted agent products:

1. The execution machine is yours: this Mac, or any host reachable over SSH.
2. Every model call goes through your own gateway (an OpenAI-compatible endpoint), so existing subscriptions stay outside this app.

This is **not** a code editor. Files open in the editor you already use. There is no hosted cloud, no multi-user mode, and no billing.

The product spec is [SPEC.md](./SPEC.md). Work the milestones in that file in order.

Source: https://github.com/RyanStoffel/cursor-projects-clone

## Two programs

| Program | Role |
| --- | --- |
| `projectd` | Rust daemon. `--role control`, `--role agent`, or both (local mode). |
| `Projects.app` | SwiftUI client. Renders UI and sends JSON-RPC. No business logic. Ships `projectd` in the bundle once M3 lands. |

```
Projects.app (SwiftUI) --JSON-RPC over unix socket or SSH tunnel--> projectd control
                                                                        |-- SQLite
                                                                        |-- coordinator loop
                                                                        |-- dispatch --> projectd agent
                                                                                           |-- git worktree per task
                                                              all LLM calls --> OpenAI-compatible gateway
```

The product name is Foreman. The daemon binary and Cargo workspace are `projectd`; the macOS target is `Projects`. Bundle id stays `dev.projectd.Projects` until a rename PR.

## Status

M0 is in this tree: JSON-RPC over a unix socket, SQLite migrations, `project.create` / `thread.send`, streamed `message.delta` events, `projectd-cli`, an OpenAI-compatible provider client (`providers.toml`), and a SwiftUI shell that can create a project, send a message, and append tokens on an `NSTextView`. Coordinator tools, workers, and worktrees start at M1.

## Layout

```
projectd/                 Cargo workspace
  crates/
    protocol/             serde types (RPC, events, entities)
    control/              SQLite, coordinator, JSON-RPC
    agent/                worktrees, worker loop (from M1)
    daemon/               binary: --role control|agent|both
    providers.toml.example
Projects/                 Xcode project, SwiftUI
  Projects/
    Protocol/             Codable mirrors of crates/protocol
    Views/
    Client/               unix socket JSON-RPC client
  Projects.xcodeproj
scripts/
  install-remote.sh       remote agent install (stub until M2)
SPEC.md                   product spec
```

## Requirements

- macOS 15 or later, Xcode 16+, for `Projects.app`
- Rust stable (see `rust-toolchain.toml`) for `projectd`
- Linux `x86_64-unknown-linux-gnu` is a first-class daemon target; the app is macOS-only

## Build

Daemon and CLI:

```sh
cargo test --manifest-path projectd/Cargo.toml --workspace
cargo build --manifest-path projectd/Cargo.toml -p projectd --features cli
```

Local round-trip with the canned coordinator (no API key):

```sh
export PROJECTD_STUB_PROVIDER=1
export PROJECTD_HOME=/tmp/projectd-dev
./projectd/target/debug/projectd --role both &
./projectd/target/debug/projectd-cli create --name Demo --repo https://example.com/repo.git
./projectd/target/debug/projectd-cli send --project <id> --content "Plan a README pass."
```

Point the same daemon at your gateway by copying `projectd/providers.toml.example` to `$PROJECTD_HOME/providers.toml` (macOS default: `~/Library/Application Support/projectd/providers.toml`) and unsetting `PROJECTD_STUB_PROVIDER`.

macOS app (on a Mac). If `projectd` is not inside the app bundle, set `PROJECTD_BIN` to the binary from `cargo build`:

```sh
xcodebuild -project Projects/Projects.xcodeproj -scheme Projects -configuration Debug \
  -derivedDataPath .ci/DerivedData \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES \
  build
PROJECTD_BIN="$(pwd)/projectd/target/debug/projectd" \
PROJECTD_STUB_PROVIDER=1 \
open .ci/DerivedData/Build/Products/Debug/Projects.app
```

CI uses the same `xcodebuild` invocation on `macos-15`. Signing is ad-hoc; there is no Apple Developer team in this scaffold.

## Git

Source: https://github.com/RyanStoffel/cursor-projects-clone

```sh
git clone https://github.com/RyanStoffel/cursor-projects-clone.git
cd cursor-projects-clone
git checkout develop
```

Default branches are `main` (release) and `develop` (integration). Every change starts as a GitHub issue. Branch names:

```
<type>/<issue-number>-<short-name>
```

Examples: `feature/12-json-rpc-server`, `bug/34-socket-hang`, `hotfix/56-ci-signing`. See [CONTRIBUTING.md](./CONTRIBUTING.md) and [docs/git-workflow.md](./docs/git-workflow.md).

Pull requests must link the issue (`Closes #N`). CI rejects PRs that do not.

## License

[MIT](./LICENSE).
