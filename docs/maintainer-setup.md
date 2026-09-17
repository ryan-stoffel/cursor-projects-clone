# Maintainer setup

Agents cannot apply these settings. A repository admin (Ryan) needs to click them in GitHub.

## 0. Create the GitHub repository

The GitHub MCP token used to bootstrap this project can read `RyanStoffel` but cannot `POST /user/repos` (403: resource not accessible by personal access token). Fine-grained tokens and many GitHub App installs cannot create user repositories.

Create a **public** repository on the **personal** account only (not an organization):

1. Open https://github.com/new
2. Owner: **RyanStoffel** (your user, not `cbu-machine-and-deep-learning-26` or any other org)
3. Name: **projectd**
4. Public
5. Add a README so `main` exists, or leave it empty
6. Create repository
7. If the Cursor GitHub App is limited to selected repositories, add `projectd` to the installation so the agent can push and file issues

Until that exists, this tree is the source of truth. After it exists, push `main`, create `develop` from `main`, and file the spec issues.

## 1. Branch protection

Settings, Branches, Add classic branch protection rule. Repeat for `main` and for `develop`.

Recommended:

- Require a pull request before merging
- Require approvals: 0 is acceptable while this is a solo repo; raise later
- Require status checks to pass: `branch-name`, `pr-issue`, `rust-linux`, `rust-macos`, `macos-app`
- Require branches to be up to date before merging (optional until the repo is busy)
- Require conversation resolution before merging
- Do not allow bypassing the above for administrators (optional)
- Do not allow force pushes
- Do not allow deletions

`pr-screenshots` posts a comment and should **not** be a required check. A missing screenshot comment is a workflow failure you can rerun; it should not block a docs-only PR if you later path-filter it, but today it runs on every PR to `main` or `develop`.

## 2. Actions permissions

Settings, Actions, General:

- Allow GitHub Actions to create and approve pull requests: not required
- Workflow permissions: **Read and write permissions**

The `pr-screenshots` workflow sets:

```yaml
permissions:
  contents: write
  pull-requests: write
```

`contents: write` lets it force-push `ci/pr-<n>-screenshots` so the PR comment can embed `raw.githubusercontent.com` image URLs (those render inline; artifact downloads do not). `pull-requests: write` lets it post or update that comment.

If the default GITHUB_TOKEN is read-only at the repo level, the workflow-level `permissions:` key is ignored and the comment step fails. Flip the setting above.

Fork PRs from strangers will not get a screenshot comment unless you also allow Actions to write from forks (not recommended). Same-repo feature branches work.

## 3. Private vulnerability reporting

Settings, Code security, Private vulnerability reporting: enable. [SECURITY.md](../SECURITY.md) points reporters there.

## 4. macOS signing and notarization

CI builds with ad-hoc signing (`CODE_SIGN_IDENTITY=-`). That is enough to launch `Projects.app` on the GitHub-hosted `macos-15` runner and take screenshots.

Distribution (Developer ID, notarization, Sparkle/Homebrew) needs:

- An Apple Developer Program membership
- A Developer ID Application certificate in a GitHub Actions secret (or a cloud signing service)
- An App Store Connect API key for notarization
- Hardened runtime and entitlements for the unix socket / SSH later

None of that is in this scaffold. Do not add a team id to the Xcode project until you are ready to sign for humans.

## 5. GitHub Projects board

Issues are the source of truth. A Projects board is optional. The GitHub MCP used to bootstrap this repo cannot create a Project, so none was created. A board with columns matching task status (`queued`, `running`, `blocked`, `review`, `merged`, `discarded`) is a reasonable later click: Projects, New project, and add the milestone issues.

## 6. Default branch

Keep **`main`** as GitHub's default branch (clone default, protected release history). Tell collaborators that day-to-day work targets **`develop`**. Optionally set the repo's default branch to `develop` if you want `git clone` to check it out; either is fine as long as [docs/git-workflow.md](./git-workflow.md) matches what you click.
