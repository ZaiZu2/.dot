---
name: pr
description:
    "[auto] Create or update the GitHub PR for the current branch with a generated title and description. Use when the
    user asks to open, create or update a PR."
context: fork
model: sonnet
---

# Pull Request

Create a PR for the current branch, or update its existing one, with a description generated from the changes. A good
description lets a reviewer see what the PR achieves and where to look, without filler.

## Target

The current branch, against the base branch the request names, else the repo's default branch
(`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`), called `<base>` below. Stop and reply only with the
reason if the current branch is `<base>`, has no commits ahead of it, or is not pushed (`git status -sb` shows no
upstream or unpushed commits). Don't push.

If the request names a directory, work there: `cd` into it first, as a command of its own.

## Actions

### 1. Gather changes

Run `git log --oneline <base>..HEAD` and `git diff <base>...HEAD`. Check for an existing PR with
`gh pr view --json number,title,url`: success means update, failure means create.

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

### 4. Choose the title

Use a title from the request verbatim. Otherwise `<TICKET>: <short description>`, or just the description without a
ticket.

### 5. Create or update

```bash
gh pr create --base <base> --title "<title>" --body "$(cat <<'PRBODY'
<description>
PRBODY
)"
```

To update, use `gh pr edit --title "<title>" --body ...` the same way.

## Report

State whether the PR was created or updated, its URL, and the Summary section.
