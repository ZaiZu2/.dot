---
name: jira
description: "[hitl] Create, update, search, comment on and transition Jira issues through the Atlassian MCP server."
model: sonnet
---

# Jira

Manage Jira issues on `https://absa.atlassian.net` with the Jira tools of the `atlassian` MCP server
(`mcp__atlassian__*`). A good result is a short, scannable ticket that follows the conventions below.

## Tools

- Pick the tool by its description; tool names change between server versions, so don't rely on remembered ones.
- Pass `absa.atlassian.net` where a tool asks for the site, or resolve its cloud ID with the server's
  accessible-resources tool first. Never work on another site, even if the account can reach one.
- If no `atlassian` tools are available, stop and tell the user to run `dot claude mcp`, then `/mcp` to sign in.

## Rules

- Ask for missing required values (project, summary, issue key) rather than guessing.
- Only modify issues assigned to the current user. Before commenting on, transitioning or updating an issue, fetch it
  and compare its assignee with the signed-in account; if it is unassigned or assigned to someone else, refuse and name
  the assignee.
- Before creating, updating, commenting on or transitioning an issue, show what will be sent and wait for approval.
- Defaults for new issues: type Task, priority Medium, assigned to the current user.
- Convert natural-language searches to JQL, e.g. "my open tickets" → `assignee = currentUser() AND status != Done`.
- For a transition, list the issue's available transitions and pick the one matching the requested status. If none
  matches, stop and list the available ones rather than picking a near match.
- Report the result: key and URL for new issues, a key/summary/status/assignee table for searches, the changed fields
  or new status otherwise.

## Project tags

Prefix new ticket summaries with a project tag and add its label, keeping any other labels:

| Prefix | Label | Area |
|--------|-------|------|
| `[fa]` | `front-arena` | File automation, SFTP, Front Arena |
| `[prime]` | `prime-portal` | Prime Portal |
| `[ps_rep]` | `ps-reporting` | PS Reporting |

Example: `[fa] Add retry logic to SFTP connector` with label `front-arena`. Infer the tag from context; ask if unsure.

## Deprecation dates

For `Deprecate old transfers for <Client>` tickets, set the due date and append it to the summary in the same update:
`Deprecate old transfers for Fairtree (2026-06-29)`.

## Descriptions

A busy reader should scan the ticket in about ten seconds; the code and PR carry the detail.

- Only **Objective** and **Scope** sections; add acceptance criteria only on request.
- Objective: one or two sentences on what and why, no background.
- Scope: two to four one-line bullets. Name key files or symbols in inline code, but don't list every touched file.
- Leave out test-scope bullets unless tests are the point of the ticket.
- If the user finds it too long, merge bullets and drop what the summary already says.
- Write in the format the tool's description field asks for (Markdown unless it says otherwise).
