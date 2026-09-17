# Git workflow

Default working branches: **`main`** and **`develop`**. `develop` is created from `main` and is the integration branch.

```
feature/12-json-rpc-server ──┐
bug/34-socket-hang ──────────┼──> develop ──> main
hotfix/56-ci-signing ────────┘         (release)
```

## Issue first

No branch, PR, or merge without a GitHub issue number. Create the issue, then name the branch after it, then open the PR with `Closes #N`.

## Branch name format

Every topic branch uses the same format, including hotfixes, chores, and docs:

```
<type>/<issue-number>-<short-name>
```

| Kind | Pattern | Example |
| --- | --- | --- |
| Feature | `feature/<issue>-<name>` | `feature/12-json-rpc-server` |
| Bug | `bug/<issue>-<name>` | `bug/34-socket-hang` |
| Hotfix | `hotfix/<issue>-<name>` | `hotfix/56-ci-signing` |
| Chore | `chore/<issue>-<name>` | `chore/78-gitignore` |
| Docs | `docs/<issue>-<name>` | `docs/90-readme` |
| Release | `release/<issue>-<name>` | `release/101-0-1-0` |

Rules enforced by `scripts/check-branch-name.sh`:

- `<type>` is a lowercase identifier (`[a-z]+`).
- `<issue-number>` is one or more digits (the GitHub issue).
- `<short-name>` is lowercase letters, digits, and hyphens, and must start with a letter or digit.

Allowed exceptions: `main`, `develop`, `dependabot/*`, screenshot publish branches `ci/pr-<n>-screenshots`, and Cursor cloud worker branches `cursor/<type>-<issue>-<slug>-<id>`.

## Pull requests

- Target **`develop`** for ordinary work.
- Target **`main`** only for release or production hotfix PRs.
- The PR body must contain a GitHub issue reference: `Closes #12`, `Fixes #12`, or a `github.com/.../issues/12` URL. `scripts/check-pr-issue.sh` fails the `pr-issue` job otherwise.
- Squash-merge. Delete the topic branch after merge.

## `main` vs `develop`

| Branch | Purpose | Who merges |
| --- | --- | --- |
| `develop` | Integration. All feature and bug PRs. | Squash-merge from topic branches after CI. |
| `main` | Release history. Tags are cut from here. | PR from `develop` (or a `release/<issue>-<name>` branch). |

Do not commit directly to either branch. Protection rules are listed in [maintainer-setup.md](./maintainer-setup.md); a repository admin must click them in GitHub.

## After merge

1. Delete the remote topic branch (GitHub can do this automatically).
2. Close the issue with `Closes #N` if the PR did not.
3. Start the next issue. Do not pile unrelated work on a merged branch.
