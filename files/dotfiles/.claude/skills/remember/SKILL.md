---
name: remember
description:
    '[hitl] Save knowledge as an OKF concept in one of my context bundles. Use when the user asks to remember, note
    or record something, or a fact worth keeping across sessions comes up: a preference, a correction, a project fact.'
model: sonnet
---

# Remember

Write knowledge worth keeping across sessions as an Open Knowledge Format (OKF) 0.2 concept in the right bundle, with
its index and log in step. A good concept states one fact that a later session can act on without this conversation.

Never write to `~/.claude/projects/<project>/memory/`. Files with a format fixed by Claude Code (`CLAUDE.md`,
`AGENTS.md`, `SKILL.md`, agent definitions) are not concepts: edit those directly instead.

## Target

The fact the request names, else the one from the conversation that triggered this skill. If several facts are
involved, plan one concept each.

## Actions

### 1. Read the spec

Read `~/.claude/context/personal/references/okf-spec-0-2.md`. It is the authority for format and rules, and outranks
both the user and [Conventions](#conventions): when a request or a convention conflicts with the spec or departs from
one of its conventions, quote the section, push back and wait for the user's decision.

### 2. Pick the bundle

By what the concept is about:

- **Personal** (`~/.claude/context/personal/`, tracked in the dot repo under
  `~/.dot/files/dotfiles/.claude/context/personal/`): facts about the user and preferences that hold across projects.
  Write into the dot repo directory, never through `~/.claude/context/personal/`.
- **Project** (`<project root>/.claude/context/`): facts about the current project. On first use create the bundle: an
  `index.md` starting with an `okf_version: "0.2"` frontmatter block, a `log.md`, and an `@.claude/context/index.md`
  import in the project's `AGENTS.md`.
- **Mounted** (`~/.claude/context/<prefix>/`, symlinked from another repo by `dot claude context`): knowledge shared
  across the projects of one scope, e.g. a work repo. Write there whatever belongs to that scope rather than to the
  user or a single project.

### 3. Check what exists

Search every bundle for the fact with `grep -R` / `find -L` (mounted bundles are symlinks; never `grep -r`). Update the
concept that already covers it instead of adding a duplicate; deprecate one it supersedes.

### 4. Draft

Draft the concept, its `index.md` line and its `log.md` entry, following the spec and [Conventions](#conventions).

### 5. Confirm

Show the bundle, the file path, the full concept (a diff for an update), and the index and log changes. Wait for
approval, and apply requested changes before writing.

### 6. Write

Write the concept, `index.md` and `log.md` in one change. A new file in the personal bundle only shows up under
`~/.claude/context/personal/` after `zsh ~/.dot/dot.sh link`: run it.

## Conventions

- Record what still holds: lasting behaviour, gotchas and constraints a later session must respect. Never the story of
  an issue that was found and fixed, which the fix makes worthless; when a bug teaches such a fact, record the fact.
- One fact per concept file, named `<kebab-case-slug>.md`, with `type` one of `user`, `feedback`, `project`,
  `reference`, and `title`, `description`, `tags`, `status`, `generated` and `sources` always set.
- `description` is a verbless phrase naming what the concept covers (e.g. "The `dot` CLI: deployment of my dotfiles
  into $HOME"), not a sentence with a verb.
- The user is `human:jakub` (as `sources[].author`, and in `verified`). Add `verified` only after the user confirms the
  content itself in conversation, never on your own; approving the write at [Confirm](#5-confirm) is not that. Set
  `stale_after` on anything time-bound.
- Deprecate superseded concepts; delete only concepts that were wrong.
- Keep concepts at the bundle root. Create a subdirectory only to group several concepts about the same context (a
  system, tool or area). The one exception is `references/` (OKF §6.3), for mirrored external material such as copied
  docs.
- Each bundle has a single `index.md`, at its root; never one in a subdirectory. It lists every concept of the bundle,
  subdirectories included, grouped by `type` under capitalized top-level headings (`# User`, `# Feedback`,
  `# Project`, `# Reference`), optionally split by subdirectory under `## <subdir>` headings, with links relative to
  the bundle root. Only what the index lists is loaded into a session; fix any drift you notice.
- Record every creation, update and deprecation in `log.md`.

## Report

The concepts written with their paths, marked created, updated or deprecated, and whether `dot link` ran.
