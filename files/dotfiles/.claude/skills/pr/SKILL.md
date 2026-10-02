---
name: pr
description: "[auto] Create or update the GitHub PR for the current branch with a generated title and description."
context: fork
model: sonnet
---

# Pull Request

Create a PR for the current branch, or update its existing one, with a description generated from the changes.

## 1. Gather changes

Run `git branch --show-current`, `git log --oneline master..HEAD` and `git diff master...HEAD`. Check for an existing PR
with `gh pr view --json number,title,url`: success means update, failure means create.

## 2. Find the ticket

Look for `[A-Z]+-[0-9]+` in the branch name (e.g. `FAPE-1319`). If found, link it as
`https://absa.atlassian.net/browse/<TICKET>`; if not, omit the ticket header.

## 3. Write the description

```markdown
### [TICKET](https://absa.atlassian.net/browse/TICKET)

## Summary

- <outcome the PR achieves>

## Implementation

- <specific changed function, class or file, and what it does>
- <supporting changes: CI, config, migrations, docs>
```

- Summary says what the PR achieves; Implementation says how, naming concrete files, functions or classes.
- One tight point per bullet, no filler. For a trivially small change, one sentence of prose per section is fine.
- No "Generated with Claude Code" footer.

## 4. Choose the title

Use a title from the request verbatim. Otherwise `<TICKET>: <short description>`, or just the description without a
ticket.

## 5. Create or update

```bash
gh pr create --base master --title "<title>" --body "$(cat <<'PRBODY'
<description>
PRBODY
)"
```

To update, use `gh pr edit --title "<title>" --body ...` the same way.

## 6. Report

State whether the PR was created or updated, its URL, and the Summary section.
