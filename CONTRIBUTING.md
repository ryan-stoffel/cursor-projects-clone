# Contributing

Thanks for helping. This is a native macOS app plus a Rust daemon. Read [SPEC.md](./SPEC.md) before proposing work. Coding agents must also follow [AGENTS.md](./AGENTS.md).

By participating you agree to the [Code of Conduct](./CODE_OF_CONDUCT.md).

## Issues first

Every change needs a GitHub issue **before** the branch exists.

1. Search existing issues.
2. Open one with a template under `.github/ISSUE_TEMPLATE/`.
3. Name the branch after that issue number.

Pull requests that do not link an issue fail CI and will not be merged.

## Branching model

- `develop` is the default integration branch. Day-to-day PRs target `develop`.
- `main` is the release branch. Merge `develop` (or a `release/<issue>-<name>` branch) into `main` only when cutting a release.
- Never push commits directly to `develop` or `main`.

Details and the exact branch-name regex: [docs/git-workflow.md](./docs/git-workflow.md). Maintainer settings (protection rules, Actions permissions, signing): [docs/maintainer-setup.md](./docs/maintainer-setup.md).

### Branch names

```
<type>/<issue-number>-<short-name>
```

| Type | Example |
| --- | --- |
| Feature | `feature/12-json-rpc-server` |
| Bug | `bug/34-socket-hang` |
| Hotfix, chore, docs, release, and anything else | `hotfix/56-ci-signing`, `chore/78-gitignore`, `docs/90-readme` |

`<short-name>` is lowercase letters, digits, and hyphens. CI rejects other names (Dependabot and the `cursor/` worker wrapper are allowed).

## Pull requests

1. Branch from latest `develop`.
2. Open the PR against `develop` (against `main` only for release/hotfix).
3. Fill in `.github/PULL_REQUEST_TEMPLATE.md`. The **Issue** field is required: `Closes #N`.
4. Wait for CI: `branch-name`, `pr-issue`, `rust-linux`, `rust-macos`, `macos-app`. Feature PRs also get a screenshot comment from `pr-screenshots`.
5. Squash-merge once checks are green.

## Commits

Prefer [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(protocol): add TaskStatus transitions
fix(daemon): parse --role=agent
docs: describe branch protection clicks
chore(ci): embed screenshots in PR comments
```

No emoji in commits, code, or CI logs.

## Local development

### Daemon

```sh
cargo build --manifest-path projectd/Cargo.toml --workspace
cargo test --manifest-path projectd/Cargo.toml --workspace
cargo build --manifest-path projectd/Cargo.toml -p projectd --features cli
PROJECTD_STUB_PROVIDER=1 ./projectd/target/debug/projectd --role both
```

`projectd-cli` (feature `cli`) talks JSON-RPC to a running daemon: `list`, `create`, `send`, `thread`.

Allowed crates are listed in [SPEC.md](./SPEC.md) section 4. `crates/protocol` may depend only on `serde`. The HTTP client is `ureq` (JSON + SSE to an OpenAI-compatible gateway).

### macOS app

Requires macOS 15 and Xcode 16+. No Swift package dependencies in v1.

```sh
xcodebuild -project Projects/Projects.xcodeproj -scheme Projects \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY=- \
  build
```

Open `Projects/Projects.xcodeproj` in Xcode if you prefer. Do not add a third-party Swift package.

Workers without a Mac should push and use the `macos-app` GitHub Actions job as the compiler.

## Crate and protocol sync

When you change a type in `projectd/crates/protocol`, change the Codable mirror in `Projects/Projects/Protocol` in the **same PR**.

## Security

Report vulnerabilities as described in [SECURITY.md](./SECURITY.md). Do not file public issues for them.
