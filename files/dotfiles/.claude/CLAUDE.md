# Global CLAUDE settings

## General

- NEVER commit anything to GIT by yourself, even when explicitly asked. Any commits can only be done by ME, the user.
- When a Bash command (or set of commands) is denied by the permission system, do NOT silently retry with a variant. Stop, tell the user what was denied, and ASK whether to proceed — the denial may be an intentional safeguard rather than a permission-list gap. Only re-invoke the same action after the user confirms in-conversation.
- NEVER add emojis to any generated artifact (PR bodies, PR titles, commit messages, code, docs, file contents).

## Skills

Every skill is either model-invoked or user-invoked, and runs in one of two modes given by the prefix of its
`description`:

- **`[auto]`**: runs to completion on its own. It is model-invoked unless its frontmatter sets
  `disable-model-invocation: true` (e.g. `note`): start it yourself, without being asked by name, whenever the
  request matches its description. Do NOT ask the user for confirmation, approval or clarification mid-run. Resolve
  ambiguity with the skill's defaults or the most reasonable assumption, finish the work, and list the assumptions
  you made in the final report. Stop early only on a stop condition the skill itself names (e.g. no target given),
  with a one-line reason.
- **`[hitl]`**: only works under the user's scrutiny (interviews, confirmation before writing to shared systems), so
  it is always user-invoked. Once it runs, ask the questions and wait at the steps the skill defines; never skip
  them, even when the answer seems obvious.

A **user-invoked** skill (`disable-model-invocation: true`) is started only by the user typing `/<name>`. Never run
it on your own, never reproduce its side effects by hand, and never reach it from another skill; if it fits the
request, tell the user to run `/<name>`.

`[auto]` does not override the rules in [General](#general): a denied command still means stop and ask.

### Setup

See `~/.claude/skills/README.md` for the full skills setup, directory structure, and instructions for
adding/updating/removing skills.

## MCPs

Below rules define when each listed MCP should be used.

### Context7

Up-to-date Code Docs - Context7 MCP pulls up-to-date, version-specific documentation and code examples straight from the
source — and places them directly into your prompt.

Always use context7 when answering questions about API, interfaces or internal workings of a given library. This means
you should automatically use the Context7 MCP tools to resolve library id and get library docs without me having to
explicitly ask.

### Atlassian

Jira and Confluence access - Atlassian MCP reads and writes Jira issues and Confluence pages on `absa.atlassian.net`.

Use it to read whenever a request refers to a Jira issue (a key such as `FAPE-1319`) or a Confluence page, without me
having to explicitly ask. Never create, update, comment on or transition anything with it directly: writes go through
the `jira` and `confluence` skills, which are user-invoked, so tell me to run `/jira` or `/confluence` instead.

Never work on another site, even if the account can reach one. If no `atlassian` tools are available, tell me to run
`dot claude mcp`, then `/mcp` to sign in.
