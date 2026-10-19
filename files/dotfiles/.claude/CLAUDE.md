# Personal CLAUDE settings

## General

- Commit only through the `commit` skill, never with a hand-written `git commit`, so every commit follows its
  Conventional Commits format and the project's scopes.
- When a Bash command (or set of commands) is denied by the permission system, do NOT silently retry with a variant.
  Stop, tell the user what was denied, and ASK whether to proceed — the denial may be an intentional safeguard rather
  than a permission-list gap. Only re-invoke the same action after the user confirms in-conversation.
- NEVER add emojis to any generated artifact (PR bodies, PR titles, commit messages, code, docs, file contents).
- Do not run the full test suite after each change while we iterate on a feature together. After a change, run at most
  the tests that cover the code you touched (one file, class or test), and only when the change is not trivial. Run the
  full suite only when I ask, when a skill's verification step requires it, or once before declaring a larger piece of
  work done; say which tests you ran and which you skipped.

## Project instructions

Instructions for agents in a repository go into `AGENTS.md`, so they work for any coding agent, not only Claude Code.
This file stays `CLAUDE.md`: Claude Code has no user-level `AGENTS.md`.

- Create and edit `AGENTS.md`, never `CLAUDE.md`: at the repository root, and in a subdirectory that needs instructions
  of its own. Claude Code reads a root `AGENTS.md` at launch and a subdirectory's once it reads a file there.
- Never create a `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md` in a repository: one in the working directory or
  above it makes Claude Code skip every `AGENTS.md` there, and one in a subdirectory hides that subdirectory's
  `AGENTS.md`. Rename the `CLAUDE.md` that `/init` writes to `AGENTS.md`.
- A repository that already has a `CLAUDE.md` keeps it until I say otherwise: edit it there, since an `AGENTS.md` beside
  it would not be loaded, and offer once to rename it to `AGENTS.md`.
- To read a project's instructions (commit scopes, test commands), look in its `AGENTS.md`, else its `CLAUDE.md`.

## Skills

A skill's `description` starts with its mode:

- **`[auto]`**: run it to completion without asking for confirmation, approval or clarification. Resolve ambiguity with
  the skill's defaults or the most reasonable assumption, and list the assumptions in the final report. Stop early only
  on a stop condition the skill names, with a one-line reason. A denied command still means stop and ask (see
  [General](#general)).
- **`[hitl]`**: work on your own, and ask me only where my input is actually needed: a decision you can't settle from
  the code or the request, and the confirmation the skill requires before writing to a shared system (Jira,
  Confluence). Don't check in between.

Never reproduce a user-invoked skill's side effects by hand; tell me to run `/<name>` instead.

### Setup

See `~/.claude/skills/README.md` for the full skills setup, directory structure, and instructions for
adding/updating/removing skills. Read its "Writing SKILL.md Instructions" section before writing or editing a skill.

## Context

Knowledge I want you to keep is stored as bundles in Open Knowledge Format (OKF) 0.2, never in
`~/.claude/projects/<project>/memory/`. Whenever you would save a memory, or create any other standalone
context/knowledge file, call the Skill tool with `remember`. Files with a format fixed by Claude Code (`CLAUDE.md`,
`AGENTS.md`, `SKILL.md`, agent definitions) are exempt.

The index of every bundle under `~/.claude/context/` is imported below, through a file `dot` generates; links in an
index are relative to the directory of that `index.md`. A project's `AGENTS.md` imports its own bundle. Read a concept
when its line is relevant to the task. Mounted bundles are symlinks, so search them with `grep -R` / `find -L` (never
`grep -r`) before concluding a fact is not recorded.

@~/.claude/context/imports.md

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
the `ticket` and `confluence` skills, which are user-invoked, so tell me to run `/ticket` or `/confluence` instead.
The only exception is a `/scope` run, which creates and updates the Jira issues I approved at its `Confirm` step.

Never work on another site, even if the account can reach one. If no `atlassian` tools are available, tell me to run
`dot claude mcp`, then `/mcp` to sign in.
