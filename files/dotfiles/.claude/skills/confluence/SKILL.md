---
name: confluence
description: "[hitl] Get, search, create and update Confluence pages."
model: sonnet
---

# Confluence

Read and write Confluence pages on `https://absa.atlassian.net` as `jakub.kawecki@absa.africa`.

## Command

```bash
~/.claude/skills/.venv/bin/python ~/.claude/skills/confluence/confluence_manager.py \
  --url https://absa.atlassian.net --username jakub.kawecki@absa.africa <subcommand> ...
```

| Subcommand | Flags |
|------------|-------|
| `get` | `--page-id ID` or `--title T --space KEY` |
| `search` | `--query Q`, optional `--space KEY` |
| `create` | `--space KEY --title T --content C`, optional `--parent-id ID`, `--format markdown\|html` |
| `update` | `--page-id ID --content C`, optional `--title T`, `--format markdown\|html` |

`--format` defaults to `markdown`.

## Rules

- Before `create` or `update`, show the title, target (space/parent or page) and content, and wait for approval. Pages
  are shared, so never write without it.
- `update` replaces the whole page body. Fetch the page first with `get` and merge your changes into it.
- Resolve a page by title with `get`/`search` when the user gives no ID.
- After writing, report the page title and URL.

## Auth

The script reads the API token from the system keyring (service `jira-api-token`, user `$USER`, shared with `/ticket`).
If auth fails, tell the user to run `~/.claude/skills/.venv/bin/keyring set jira-api-token "$USER"`.
