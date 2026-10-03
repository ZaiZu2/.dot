# Claude Code Skills

Custom skills for Claude Code. A skill is a directory with a `SKILL.md`; its instructions drive Claude's built-in
tools, CLIs already on the machine (`gh`, `zk`, `git`) and tools from [MCP servers](#mcp-servers).

To reach an external system, use an MCP server: it brings the client and the authentication, and the skill keeps only
the conventions.

## Available Skills

| Skill         | Purpose                                                              | Uses                   |
| ------------- | -------------------------------------------------------------------- | ---------------------- |
| `/doc`        | Docstrings for files or code objects, matching the project's style   | -                      |
| `/mkdoc`      | Markdown documentation for a part of a project                       | -                      |
| `/note`       | Zettelkasten note from the conversation                              | `zk`                   |
| `/pr`         | Create or update the GitHub PR for the current branch                | `gh`                   |
| `/review`     | Review a PR, commits or changes                                      | `gh`                   |
| `/spec`       | Interview-driven feature spec, written to `.claude/docs/<slug>.md`   | -                      |
| `/jira`       | Create, update, search, comment on and transition Jira issues        | `atlassian` MCP server |
| `/confluence` | Get, search, create and update Confluence pages                      | `atlassian` MCP server |

## Directory Structure

```
~/.claude/skills/
├── README.md
└── confluence/, doc/, jira/, mkdoc/, note/, pr/, review/, spec/   # one SKILL.md each
```

Skills are discovered exactly one level deep (`skills/<name>/SKILL.md`); grouping them in subfolders does not work.

## Adding a Skill

To add one, create `<name>/SKILL.md` and follow [Writing SKILL.md Instructions](#writing-skillmd-instructions). In
this repo, run `dot link` afterwards so the new file is symlinked into `~/.claude/skills/`.

### Cross-file References

Skills can point Claude at other files: "Before X, read `${CLAUDE_SKILL_DIR}/file.md`". Name the trigger, keep it one
hop deep, and use resolvable paths. `@file` imports are documented for `CLAUDE.md`; don't rely on them in skills.

## MCP Servers

Claude Code keeps user-scope MCP servers in `~/.claude.json`, mixed with its own state, so that file can't be tracked.
The servers are declared in `~/.claude/mcp.json` instead (tracked in the dotfiles repo, same `mcpServers` format as a
project `.mcp.json`) and registered with:

```bash
dot claude mcp   # register new or changed servers in user scope; unchanged ones are skipped
/mcp             # inside Claude Code: sign in to servers that use OAuth
```

Claude Code does not read `~/.claude/mcp.json` itself, so re-run `dot claude mcp` after editing it. Servers registered by
hand (`claude mcp add`) are left alone, and removing an entry from the file does not unregister it; use
`claude mcp remove <name> -s user`. Keep secrets out of the file: use OAuth or `${VAR}` expansion.

In a skill, refer to the server's tools as `mcp__<server>__*` and tell Claude what to do when they are missing (see
`jira/SKILL.md`).

## Work Skills

To use skills from another repo (e.g. work), link them in with a prefix to keep the namespaces apart:

```bash
dot claude skills <path-to-.claude-dir> --prefix ps
```

This creates one symlink per skill, `~/.claude/skills/ps-<name>` -> `<path>/skills/<name>`; the prefix is one
lowercase word, joined to the skill name with `-`. Files added to a linked skill show up on their own, so re-run it
only for new skills. `--force` repoints a symlink that leads elsewhere; a real directory is never replaced. To unlink
them again:

```bash
dot claude skills <path-to-.claude-dir> --prefix ps --clean
```

Only symlinks pointing into that repo are removed, so personal skills and other prefixes are untouched.

## Writing SKILL.md Instructions

Keep this list updated as new conventions come up while refining skills.

- **Mode prefix.** Start every `description` with `[hitl]` (needs the user
  during the run: interviews, confirmations before writes to shared systems)
  or `[auto]` (runs to completion on its own). Quote the description, since a
  leading `[` is otherwise parsed by YAML as a list.
- **User-only side effects.** An `[auto]` skill may write to a shared system
  without confirming only if it sets `disable-model-invocation: true`, so
  that the user's invocation is the approval (`pr`).
- **Lean descriptions.** Say what the skill does. Add trigger phrases ("Use
  when the user asks to plan a feature") only when auto-triggering needs
  them; never "Use when the user invokes /x", since invoking by name always
  works.
- **Fork `[auto]` skills** with `context: fork` when their input is the repo,
  files or arguments alone. A forked skill runs in a background subagent
  without the conversation history, so keep skills that rely on the chat
  (summaries, selected code) inline. Always fork skills that judge work
  (reviews), so they aren't biased by the conversation that produced it.
  Unless its target is fixed (e.g. `pr` always works on the current
  branch), a forked skill must require an explicit target in the request
  (PR, commits, files) and stop if none is given, since it can't see the
  chat or ask; state this under `Target`. It also can't confirm mid-run, so replace any "confirm before X"
  step with a safe default.
- **Model choice.** Set `model` on forked skills and routine inline ones
  (API wrappers, note-taking): `sonnet` for routine work, `opus` where
  judgment matters (reviews). Use the aliases, which track the latest
  version, not pinned model IDs. Leave it unset on skills that need the
  session's model, like `spec`.
- **Supported frontmatter only.** Unknown keys such as `title` or
  `permissions` are ignored locally and rejected by claude.ai. See
  https://code.claude.com/docs/en/skills for the valid fields.
- **Be concise.** State each rule once, in as few words as carry it. Cut
  restatements, explanations of the obvious, and filler intros.
- **Short, plain headers.** A few straightforward words (`Interview`,
  `Report results`), no sentence-style titles or parenthetical asides.
  Number only the `###` steps under `Actions`; see
  [Structure](#structure).
- **No Capabilities sections.** They repeat the frontmatter description.
- **No personas.** Don't open with "You are a senior engineer…" or similar
  role-play. State the skill's purpose (what it's for and what a good
  result looks like) and give concrete rules for the behavior you want.
  Specific rules and a clear goal guide judgment better than a role label.
- **No usage-example sections or argument syntax.** Skills take a
  free-form request. State the default behavior and let the request
  override it ("review against `master` unless the request names other
  changes"), instead of documenting positional arguments or flags.

### Structure

Every skill uses these sections, in this order. Leave out a section that doesn't apply, but never reorder them. The
names `Target`, `Tools`, `Actions`, `Rules` and `Report` are fixed.

```markdown
---
name: <name>
description: "[hitl|auto] <what it does>. <trigger phrases, if needed>"
context: fork                    # see Fork
model: <sonnet | opus>          # see Model choice
disable-model-invocation: true   # see User-only side effects
---

# <Title>

<Purpose: what the skill is for and what a good result looks like, in 1-3 sentences. Constraints that hold for the
whole run go here too ("Read-only: don't modify files").>

## Target

<What it works on: the default, how the request overrides it, and every stop condition (nothing named, ambiguous
match, wrong branch). Forked skills stop with a one-line reason; inline skills ask.>

## Tools

<Only when an MCP server or CLI needs non-obvious handling: how to pick tools, what to do when they are missing.>

## Actions

<What the skill does. One numbered `###` header per step when the steps are distinct and run in a strict order:>

### 1. <Step>

### 2. <Step>

<A short paragraph instead, when the skill is too simple for steps (`doc`) or its flow depends on the request
(`jira`).>

## Rules

<Rules that aren't tied to one step.>

## <Topic>

<Reference sections (`Python`, `Project tags`, `Notebooks`). An output template lives in the step or topic that
produces it.>

## Report

<What the final message contains. Always last.>
```
