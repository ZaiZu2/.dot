---
name: ticket
description: "[hitl] Create, update, search, comment on and transition Jira issues."
model: sonnet
---

# Jira Tickets

Manage Jira issues on `https://absa.atlassian.net` as `jakub.kawecki@absa.africa`.

## Command

```bash
~/.claude/skills/.venv/bin/python ~/.claude/skills/ticket/jira_ticket_manager.py \
  --url https://absa.atlassian.net --username jakub.kawecki@absa.africa <subcommand> ...
```

| Subcommand | Flags |
|------------|-------|
| `create` | `--project KEY --summary S`, optional `--type` (Task), `--priority` (Medium), `--description`, `--assignee`, `--labels a,b` |
| `get` | `--key KEY` |
| `search` | `--jql Q`, optional `--max-results N` (50) |
| `comment` | `--key KEY --body TEXT` |
| `transition` | `--key KEY --status NAME` |
| `update` | `--key KEY`, any of `--summary`, `--description`, `--priority`, `--assignee`, `--labels` (replaces all), `--due-date YYYY-MM-DD` |

- Types: Story, Bug, Task, Epic, Sub-task. Priorities: Highest, High, Medium, Low, Lowest.
- `--assignee` takes an account ID. `create` assigns to the user by default
  (`712020:8e7a54c5-a95d-4d2e-be17-7a7a6348c4e4`).
- Convert natural-language searches to JQL, e.g. "my open tickets" → `assignee = currentUser() AND status != Done`.

## Rules

- Ask for missing required values (project, summary, issue key) rather than guessing.
- Before `create`, `update`, `comment` or `transition`, show what will be sent and wait for approval.
- After running, report the result: key and URL for new issues, a key/summary/status/assignee table for searches, the
  changed fields or new status otherwise.

## Project tags

Prefix new ticket summaries with a project tag and add its label:

| Prefix | Label | Area |
|--------|-------|------|
| `[fa]` | `front-arena` | File automation, SFTP, Front Arena |
| `[prime]` | `prime-portal` | Prime Portal |
| `[ps_rep]` | `ps-reporting` | PS Reporting |

Example: `[fa] Add retry logic to SFTP connector` with label `front-arena`. Infer the tag from context; ask if unsure.

## Deprecation dates

For `Deprecate old transfers for <Client>` tickets, set `--due-date` and append the date to the summary in the same
`update`: `Deprecate old transfers for Fairtree (2026-06-29)`.

## Descriptions

Use only **Objective** and **Scope** sections; add acceptance criteria only on request. Write Jira wiki markup, not
Markdown, which the API shows literally:

- Headings `h2. Objective`, bold `*text*`, italic `_text_`
- Bullets `* item`, numbered `# item`
- Inline code `{{name}}`, code block `{code:python}...{code}`
- Link `[text|https://url]`, quote `bq. text`
- Blank line after each heading

```
h2. Objective

Short paragraph on what we want to achieve.

h2. Scope

* First bullet referencing {{some/file.py}}.
* Second bullet with a [link|https://example.com].
```

## Auth

The script reads the API token from the system keyring (service `jira-api-token`, user `$USER`, shared with
`/confluence`). If auth fails, tell the user to run `~/.claude/skills/.venv/bin/keyring set jira-api-token "$USER"`.
