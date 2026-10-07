# Personal CLAUDE settings

## General

- Commit only through the `commit` skill, never with a hand-written `git commit`, so every commit follows its
  Conventional Commits format and the project's scopes.
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

Knowledge I want you to keep is stored as bundles in Open Knowledge Format (OKF) 0.2. Whenever you would save a memory,
or create any other standalone context/knowledge file, write it as an OKF concept into one of these bundles instead of
into `~/.claude/projects/<project>/memory/`. Files with a format fixed by Claude Code (`CLAUDE.md`, `SKILL.md`, agent
definitions) are exempt.

Before creating or updating any file in a bundle (concept, `index.md`, `log.md`), read the spec at
`~/.claude/context/personal/references/okf-spec-0-2.md` and follow it; it is the authority for format and rules. It
also outranks me: when a request of mine, or one of my conventions below, conflicts with the spec or departs from one of
its conventions, push back, quote the section, and wait for my decision before acting.

The index of every bundle under `~/.claude/context/` is imported below, through a file `dot` generates; links in an
index are relative to the directory of that `index.md`. Read a concept when its line is relevant to the task. Mounted
bundles are symlinks, so search them with `grep -R` / `find -L` (never `grep -r`) before concluding a fact is not
recorded.

@~/.claude/context/imports.md

Pick the bundle by what the concept is about:

- **Personal** (`~/.claude/context/personal/`, tracked in the dot repo under
  `files/dotfiles/.claude/context/personal/`): facts about me and preferences that hold across projects. Write into the
  dot repo directory, then run `dot link` (`zsh ~/.dot/dot.sh link`) so the new file surfaces under
  `~/.claude/context/personal/`.
- **Project** (`<project root>/.claude/context/`): facts about the current project. Create the bundle on first use: an
  `index.md` starting with an `okf_version: "0.2"` frontmatter block, and a `log.md`, and import the index from the
  project's `CLAUDE.md` with `@.claude/context/index.md`.
- **Mounted** (`~/.claude/context/<prefix>/`, symlinked from another repo by `dot claude context`): knowledge shared
  across the projects of one scope, e.g. a work repo. Write there whatever belongs to that scope rather than to me or to
  a single project; the symlink resolves into the other repo, so new files need no `dot link`. Mounting or removing
  a bundle with `dot claude context` updates the imports above.

My conventions on top of the spec:

- One fact per concept file, named `<kebab-case-slug>.md`, with `type` one of `user`, `feedback`, `project`,
  `reference`, and `title`, `description`, `tags`, `status`, `generated` and `sources` always set.
- Write `description` as a verbless phrase naming what the concept covers (e.g. "The `dot` CLI: deployment of my
  dotfiles into $HOME"), not as a sentence with a verb.
- I am `human:jakub` (as `sources[].author`, and in `verified`). Add `verified` only after I confirm the content in
  conversation, never on your own. Set `stale_after` on anything time-bound.
- Deprecate superseded concepts; delete only concepts that were wrong.
- Keep concepts at the bundle root by default. Create a subdirectory only to group several concepts about the same
  context (a system, tool or area). The one exception is `references/` (OKF §6.3), which holds mirrored external
  material such as copied docs.
- Each bundle has a single `index.md`, at its root; never create one in a subdirectory. It lists every concept of the
  bundle, subdirectories included, grouped by `type` under capitalized top-level headings (`# User`, `# Feedback`,
  `# Project`, `# Reference`), optionally split by subdirectory under `## <subdir>` headings, with links relative to the
  bundle root. Update it in the same change as the concepts; fix any drift you notice. Only what the index lists is
  loaded into the session.
- Record every creation, update and deprecation in `log.md`.

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
