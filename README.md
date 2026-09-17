# Projects / projectd

A macOS desktop app for coordinator-and-subagent project workflows. One coordinator chat per project plans work, delegates to parallel workers, keeps shared context, and brings finished branches back for review.

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

Until a product name is chosen, the daemon binary and Cargo workspace are `projectd`, and the macOS target is `Projects`. Do not put a competing product's name in any identifier or bundle id.

## Status

This repository is a **scaffold**: repo layout, protocol stubs, a real SwiftUI window, and CI that builds both sides. Milestone M0 (JSON-RPC, SQLite, `projectd-cli`, provider round-trip) is not implemented yet. Track work in GitHub issues; do not start a milestone until the previous completion criterion in [SPEC.md](./SPEC.md) passes.

## Layout

```
projectd/                 Cargo workspace
  crates/
    protocol/             serde types (RPC, events, entities)
    control/              SQLite, coordinator, JSON-RPC (from M0)
    agent/                worktrees, worker loop (from M1)
    daemon/               binary: --role control|agent|both
Projects/                 Xcode project, SwiftUI
  Projects/
    Protocol/             Codable mirrors of crates/protocol
    Views/
    Client/               socket / RPC client stub
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

Daemon:

```sh
cargo build --manifest-path projectd/Cargo.toml --workspace
./projectd/target/debug/projectd --help
```

macOS app (on a Mac):

```sh
xcodebuild -project Projects/Projects.xcodeproj -scheme Projects -configuration Debug \
  -derivedDataPath .ci/DerivedData \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES \
  build
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
