# Global CLAUDE settings

## General

- NEVER commit anything to GIT by yourself, even when explicitly asked. Any commits can only be done by ME, the user.
  The only exception is a `/feature` run, which commits and pushes on the feature branch it created for that run, and
  on no other branch.
- When a Bash command (or set of commands) is denied by the permission system, do NOT silently retry with a variant.
  Stop, tell the user what was denied, and ASK whether to proceed — the denial may be an intentional safeguard rather
  than a permission-list gap. Only re-invoke the same action after the user confirms in-conversation.
- NEVER add emojis to any generated artifact (PR bodies, PR titles, commit messages, code, docs, file contents).

## Skills

Every skill is either model-invoked or user-invoked, and runs in one of two modes given by the prefix of its
`description`:

- **`[auto]`**: runs to completion on its own. It is model-invoked unless its frontmatter sets
  `disable-model-invocation: true` (e.g. `note`): start it yourself, without being asked by name, whenever the request
  matches its description. Do NOT ask the user for confirmation, approval or clarification mid-run. Resolve ambiguity
  with the skill's defaults or the most reasonable assumption, finish the work, and list the assumptions you made in the
  final report. Stop early only on a stop condition the skill itself names (e.g. no target given), with a one-line
  reason.
- **`[hitl]`**: only works under the user's scrutiny (interviews, confirmation before writing to shared systems), so it
  is always user-invoked. Once it runs, ask the questions and wait at the steps the skill defines; never skip them, even
  when the answer seems obvious.

A **user-invoked** skill (`disable-model-invocation: true`) is started only by the user typing `/<name>`. Never run it
on your own, never reproduce its side effects by hand, and never reach it from another skill; if it fits the request,
tell the user to run `/<name>`.

`[auto]` does not override the rules in [General](#general): a denied command still means stop and ask.

### Setup

See `~/.claude/skills/README.md` for the full skills setup, directory structure, and instructions for
adding/updating/removing skills. Read its "Writing SKILL.md Instructions" section before writing or editing a skill.

## Context

Knowledge I want you to keep is stored as bundles in
[Open Knowledge Format 0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md). Whenever
you would save a memory, or create any other standalone context/knowledge file, write it as an OKF concept into one of
these bundles instead of into `~/.claude/projects/<project>/memory/`. Files with a format fixed by Claude Code
(`CLAUDE.md`, `SKILL.md`, agent definitions) are exempt. Whenever you are unsure how to write such a file, read the spec
under the link above first; it is the authority, the rules below only summarise it.

The `SessionStart` hook `~/.claude/hooks/context-index.sh` prints the index of every bundle that applies to the session;
read a concept when its line is relevant to the task. Pick the bundle by what the concept is about:

- **Personal** (`~/.claude/context/personal/`, tracked in the dot repo under
  `files/dotfiles/.claude/context/personal/`): facts about me and preferences that hold across projects. Write into the
  dot repo directory, then run `dot link` (`zsh ~/.dot/dot.sh link`) so the new file surfaces under
  `~/.claude/context/personal/`.
- **Project** (`<project root>/.claude/context/`): facts about the current project. Create the bundle on first use: an
  `index.md` starting with an `okf_version: "0.2"` frontmatter block, and a `log.md`.
- **Mounted** (`~/.claude/context/<prefix>/`, symlinked from another repo by `dot claude context`): knowledge shared
  across the projects of one scope, e.g. a work repo. Write there whatever belongs to that scope rather than to me or
  to a single project; the symlink resolves into the other repo, so new files need no `dot link`.

Rules for every bundle:

- **Concept**: one fact per file, named `<kebab-case-slug>.md`, with this frontmatter:

    ```yaml
    ---
    type: user | feedback | project | reference
    title: <display name>
    description: <one-sentence summary>
    tags: [<tag>, ...]
    status: draft | stable | deprecated
    generated: { by: claude-code/<model id>, at: <ISO 8601 UTC datetime> }
    sources:
        - id: <stable key>
          resource: <URL, path, or scope descriptor such as "Claude Code session <id>">
          author: human:jakub
    ---
    ```

- **Trust**: `generated.at` is the last meaningful content change. Add `verified: { by: human:jakub, at: ... }` only
  after I confirm the content in conversation, never on your own. Set `stale_after` on anything time-bound (project
  state, deadlines).
- **Lifecycle**: mark a superseded concept `status: deprecated` and link its replacement. Delete only concepts that were
  wrong.
- **Body**: structural markdown. Link other concepts with bundle-relative markdown links (`[title](/slug.md)`), not
  `[[slug]]`. Attribute individual claims with footnotes keyed to `sources[].id`.
- **Index**: `index.md` must always list every concept of its bundle, grouped under one heading per `type`, one
  `* [title](slug.md) - description` line per concept. Keeping it complete is your job: update it in the same change
  that creates, renames, re-describes or removes a concept, and fix any drift you notice between the index and the
  files. The session-start hook shows only what the index lists.
- **Log**: record every creation, update and deprecation in `log.md`, newest first, under `## YYYY-MM-DD` headings.

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
The only exception is a `/feature` run, which creates the Jira issues I approved at its `Confirm` step.

Never work on another site, even if the account can reach one. If no `atlassian` tools are available, tell me to run
`dot claude mcp`, then `/mcp` to sign in.
