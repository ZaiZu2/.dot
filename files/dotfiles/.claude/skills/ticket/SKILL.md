---
name: ticket
title: JIRA Ticket Manager
description: Create, update, and search JIRA issues/tickets directly from Claude
permissions:
  - bash
---

# JIRA Ticket Manager

This skill enables Claude to create, update, and search JIRA issues.

## Capabilities

- **Create Tickets**: Create new JIRA issues with summary, description, type, priority, assignee, labels, and more
- **Update Tickets**: Modify existing issues (status, description, assignee, etc.)
- **Get Ticket Details**: Retrieve full details of an issue by key
- **Search Tickets**: Find issues using JQL queries
- **Add Comments**: Add comments to existing issues
- **Transition Tickets**: Move issues through workflow states (e.g. To Do → In Progress → Done)

## Usage Examples

### Create a Ticket
"Create a JIRA ticket in FAPE project: 'Add retry logic to SFTP connector' as a Story with High priority"

`/ticket create FAPE --type Story --priority High --summary "Add retry logic to SFTP connector"`

### Get Ticket Details
"Show me FAPE-1293"

`/ticket get FAPE-1293`

### Search for Tickets
"Find all open bugs assigned to me in FAPE"

`/ticket search "project = FAPE AND assignee = currentUser() AND type = Bug AND status != Done"`

### Update a Ticket
"Add a comment to FAPE-1293 with the implementation notes"

`/ticket comment FAPE-1293 "Implemented retry logic with exponential backoff"`

### Transition a Ticket
"Move FAPE-1293 to In Progress"

`/ticket transition FAPE-1293 "In Progress"`

## Requirements

### User Setup (one-time)

**Store API Token in Keychain** (same token as Confluence — shared Atlassian auth):
```bash
# Save API token to keychain (skip if already done for /confluence skill)
security add-generic-password -s "jira-api-token" -a "$USER" -w "YOUR_API_TOKEN_HERE"

# Verify
security find-generic-password -s "jira-api-token" -a "$USER" -w
```

## Configuration

JIRA instance details:
- **URL**: `https://absa.atlassian.net`
- **Username**: `jakub.kawecki@absa.africa`
- **Account ID**: `712020:8e7a54c5-a95d-4d2e-be17-7a7a6348c4e4` (use this for `--assignee` when assigning to Jakub Kawecki)

## Implementation

Uses the shared Python environment at `~/.claude/skills/.venv` to execute `jira_ticket_manager.py`. The script:
- Retrieves API token from macOS Keychain (service: `jira-api-token`)
- Accepts URL and username as command-line arguments

Example commands:
```bash
# Create issue
~/.claude/skills/.venv/bin/python ~/.claude/skills/ticket/jira_ticket_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  create --project FAPE --summary "Add retry logic" --type Story --priority High \
  --description "Implement exponential backoff for SFTP connections"

# Get issue
~/.claude/skills/.venv/bin/python ~/.claude/skills/ticket/jira_ticket_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  get --key FAPE-1293

# Search issues
~/.claude/skills/.venv/bin/python ~/.claude/skills/ticket/jira_ticket_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  search --jql "project = FAPE AND status = 'In Progress'"

# Add comment
~/.claude/skills/.venv/bin/python ~/.claude/skills/ticket/jira_ticket_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  comment --key FAPE-1293 --body "Implementation complete, ready for review"

# Transition issue
~/.claude/skills/.venv/bin/python ~/.claude/skills/ticket/jira_ticket_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  transition --key FAPE-1293 --status "In Progress"

# Update issue fields
~/.claude/skills/.venv/bin/python ~/.claude/skills/ticket/jira_ticket_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  update --key FAPE-1293 --summary "New summary" --priority High --labels "backend,urgent"
```

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

### 3. Description preferences

When creating tickets, keep descriptions lean:
- Structure with **Objective** and **Scope** sections only
- Do NOT include "Acceptance Criteria" sections unless the user explicitly asks for them

### 4. Report results

- For **create**: Show the new issue key and URL
- For **get**: Show key, summary, status, assignee, priority, description, and URL
- For **search**: Show a table of results (key, summary, status, assignee)
- For **comment**: Confirm the comment was added
- For **transition**: Confirm the new status
- For **update**: Confirm which fields were updated
