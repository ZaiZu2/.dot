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

**Note:** All skills share a common Python environment managed at `~/.claude/skills/`. Dependencies are defined in `~/.claude/skills/pyproject.toml`.

## Instructions for Claude

When this skill is invoked with `/ticket [command] [args]`:

### 1. Parse the user's intent

Determine which operation the user wants:
- **create**: Needs at minimum a project key and summary
- **get**: Needs an issue key (e.g. FAPE-1293)
- **search**: Needs a JQL query or natural language that you convert to JQL
- **comment**: Needs an issue key and comment text
- **transition**: Needs an issue key and target status name
- **update**: Needs an issue key and fields to change

### 2. Build and execute the command

Use the example commands above as templates. Always pass `--url` and `--username` as shown.

For **create**, prompt the user for any missing required fields:
- `--project` (required): Project key like FAPE
- `--summary` (required): One-line summary
- `--type` (default: Task): Story, Bug, Task, Epic, Sub-task
- `--priority` (default: Medium): Highest, High, Medium, Low, Lowest
- `--description` (optional): Full description in markdown
- `--assignee` (optional): Assignee email or account ID
- `--labels` (optional): Comma-separated labels

For **search**, if the user gives natural language, convert it to JQL. Common patterns:
- "my open tickets" → `assignee = currentUser() AND status != Done`
- "FAPE bugs" → `project = FAPE AND type = Bug`
- "created this week" → `created >= startOfWeek()`

For **update**, supported fields:
- `--summary` (new summary)
- `--description` (new description)
- `--priority` (Highest/High/Medium/Low/Lowest)
- `--assignee` (account ID)
- `--labels` (comma-separated; replaces existing labels)
- `--due-date` (YYYY-MM-DD; sets the Due Date field)

### 6. Deprecation date convention (FAPE SFTP migration)

When setting a deprecation date on a `Deprecate old transfers for <Client>` ticket:
- Set the `Due Date` field via `--due-date YYYY-MM-DD`
- Also append the date to the summary in parentheses, e.g.:
  `Deprecate old transfers for Fairtree (2026-06-29)`
- Do both in a single `update` call:
  ```bash
  ... update --key FAPE-1422 \
    --summary "Deprecate old transfers for Fairtree (2026-06-29)" \
    --due-date 2026-06-29
  ```

### 7. Title prefix and label convention

When creating tickets, apply a project tag as both a **title prefix** and a **JIRA label**:

Available tags (short prefix → full label):
- **fa** → label `front-arena` — File Automation / SFTP / Front Arena-related work
- **prime** → label `prime-portal` — Prime Portal application work
- **ps_rep** → label `ps-reporting` — PS Reporting work

**Rules:**
- Prefix the summary with the short `[TAG]`, e.g. `[fa] Add retry logic to SFTP connector`
- Add the corresponding **full** tag name as a label via `--labels` (append to any other labels)
- Infer the appropriate tag from context (e.g. SFTP/file transfers → `fa`/`front-arena`, portal UI/APIs → `prime`/`prime-portal`, reporting → `ps_rep`/`ps-reporting`)
- If the tag cannot be confidently inferred, ask the user which project the task belongs to before creating the ticket

**Examples:**
- Summary: `[fa] Add retry logic to SFTP connector` + label: `front-arena`
- Summary: `[prime] Fix session timeout on dashboard` + label: `prime-portal`
- Summary: `[ps_rep] Add monthly reconciliation report` + label: `ps-reporting`

### 8. Description preferences

When creating tickets, keep descriptions **very concise** — aim for a ticket a busy reader can scan in ~10 seconds. Prefer omission over completeness; the code, PR, and commit messages carry the detail.
- Structure with **Objective** and **Scope** sections only
- Objective: 1-2 short sentences stating what and why. No background paragraphs.
- Scope: 2-4 bullets max, each one line. Reference key files/symbols with `{{...}}` but do NOT enumerate every touched file.
- Skip test-scope bullets unless tests are the point of the ticket — testing is assumed
- Do NOT include "Acceptance Criteria" sections unless the user explicitly asks for them
- If the user pushes back on length, cut ruthlessly — combine bullets, drop context that's obvious from the summary

**Formatting — use Jira wiki markup, NOT Markdown.** The JIRA REST v2 API used by this skill renders wiki markup; Markdown characters (`#`, `**`, `` ` ``, `-` for bullets) are shown literally and look broken.

Use this mapping:
- Headings: `h1.`, `h2.`, `h3.` (e.g. `h2. Objective`) — never `##`
- Bold: `*bold*` — never `**bold**`
- Italic: `_italic_`
- Bullet list: lines starting with `* ` (asterisk + space) — never `- `
- Numbered list: lines starting with `# `
- Inline code / filenames / identifiers: `{{code}}` — never backticks
- Code block: `{code}...{code}` or `{code:python}...{code}`
- Link: `[text|https://url]`
- Quote: `bq. text` or `{quote}...{quote}`
- Leave a blank line between a heading and the following paragraph/list

Example description body:
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
