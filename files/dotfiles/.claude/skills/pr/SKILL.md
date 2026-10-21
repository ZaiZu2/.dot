---
name: pr
description:
    "[auto] Create or update the PR for the current branch, on GitHub or Azure DevOps, with a generated title and
    description. Use when the user asks to open, create or update a PR."
context: fork
model: sonnet
---

# Pull Request

Create a PR for the current branch, or update its existing one, with a description generated from the changes. A good
description lets a reviewer see what the PR achieves and where to look, without filler. The host is detected from the
remote; the description and title are the same on every host.

## Target

The current branch, against the base branch the request names, else the repo's default branch, called `<base>` below.
Stop and reply only with the reason if the current branch is `<base>`, has no commits ahead of it, or is not pushed
(`git status -sb` shows no upstream or unpushed commits). Don't push.

If the request names a directory, work there: `cd` into it first, as a command of its own.

## Tools

Detect the host from `git remote get-url origin`:

- **GitHub**: `github.com`. Use `gh`. Default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`.
- **Azure DevOps**: `dev.azure.com` or `visualstudio.com`. Use the `mcp__azure-devops__*` tools. Default branch:
  `git symbolic-ref --short refs/remotes/origin/HEAD`, minus the `origin/` prefix.

Stop and reply only with the reason for any other host. For Azure DevOps, take `<org>`, `<project>` and `<repo>` from
`https://dev.azure.com/<org>/<project>/_git/<repo>` (or the `git@ssh.dev.azure.com:v3/<org>/<project>/<repo>` and
`<org>@vs-ssh.visualstudio.com` forms), decoding `%20`. The server is bound to one organization (`absarails`): stop
with that reason if `<org>` differs. If no `azure-devops` tools are available, stop and reply that the user must run
`dot claude mcp`, then `/mcp` to sign in. Don't fall back to `az` or REST calls.

## Actions

### 1. Gather changes

Run `git log --oneline <base>..HEAD` and `git diff <base>...HEAD`. Then check for an existing PR from the branch:

- GitHub: `gh pr view --json number,title,url`. Success means update, failure means create.
- Azure DevOps: `repo_repository` (`get`, name `<repo>`, project `<project>`) gives the `repositoryId` used below. Then
  `repo_pull_request` (`list`, source `refs/heads/<branch>`, target `refs/heads/<base>`, status active): a hit means
  update, none means create.

### 2. Find the ticket

Look for `[A-Z]+-[0-9]+` in the branch name (e.g. `FAPE-1319`). If found, fetch its summary with the Atlassian MCP
(`getJiraIssue`) and link it as `https://absa.atlassian.net/browse/<TICKET>`, with the link text `<TICKET>: <summary>`.
If the ticket isn't found in the branch name, or the fetch fails, omit it rather than guessing a summary.

### 3. Write the description

```markdown
## Summary

- <outcome the PR achieves>

## Implementation

- <specific changed function, class or file, and what it does>
- <supporting changes: CI, config, migrations, docs>

## Related

- [TICKET: Summary](https://absa.atlassian.net/browse/TICKET)
- <URL of a related PR the request names>
```

- Summary says what the PR achieves; Implementation says how, naming concrete files, functions or classes.
- One tight point per bullet, no filler. For a trivially small change, one sentence of prose per section is fine.
- No "Generated with Claude Code" footer.
- Include `Related` only when there's a ticket link or the request names related PRs.
- Azure DevOps rejects descriptions over 4000 characters: shorten Implementation until it fits, keeping Summary and
  Related intact.

### 4. Choose the title

Use a title from the request verbatim. Otherwise `<TICKET>: <short description>`, or just the description without a
ticket.

### 5. Create or update

GitHub:

```bash
gh pr create --base <base> --title "<title>" --body "$(cat <<'PRBODY'
<description>
PRBODY
)"
```

To update, use `gh pr edit --title "<title>" --body ...` the same way.

Azure DevOps: call `repo_pull_request_write` with `repositoryId`, `project`, `title` and `description`. To create, use
action `create` with `sourceRefName` `refs/heads/<branch>` and `targetRefName` `refs/heads/<base>`; to update, action
`update` with the `pullRequestId` from step 1. If it fails with a permission error (TF401027 or 403), stop and reply
with the error: the user lacks the `Contribute to pull requests` permission on the repository.

## Report

State whether the PR was created or updated, its URL (on Azure DevOps
`https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<id>`), and the Summary section.
