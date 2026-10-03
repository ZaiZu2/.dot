# Claude Code Skills

Custom skills for Claude Code. A skill is one of two kinds:

- **Markdown skill** — a directory with only a `SKILL.md`. The instructions drive Claude's built-in tools, CLIs
  already on the machine (`gh`, `zk`, `git`) and tools from [MCP servers](#mcp-servers). This is the default.
- **Integration skill** — a `SKILL.md` plus a Python script that talks to an external system. These run in the
  shared Python environment described under [Integration skills](#integration-skills).

Start with a markdown skill. To reach an external system, prefer an MCP server: it brings the client and the
authentication, and the skill keeps only the conventions. Write a script only when no suitable server exists or the
logic is unreliable as prose instructions.

## Available Skills

| Skill         | Kind        | Purpose                                                              | Uses                          |
| ------------- | ----------- | -------------------------------------------------------------------- | ----------------------------- |
| `/doc`        | markdown    | Docstrings for files or code objects, matching the project's style   | -                             |
| `/mkdoc`      | markdown    | Markdown documentation for a part of a project                       | -                             |
| `/note`       | markdown    | Zettelkasten note from the conversation                              | `zk`                          |
| `/pr`         | markdown    | Create or update the GitHub PR for the current branch                | `gh`                          |
| `/review`     | markdown    | Review a PR, commits or changes                                      | `gh`                          |
| `/spec`       | markdown    | Interview-driven feature spec, written to `.claude/docs/<slug>.md`   | -                             |
| `/jira`       | markdown    | Create, update, search, comment on and transition Jira issues        | `atlassian` MCP server        |
| `/confluence` | integration | Get, search, create and update Confluence pages                      | `confluence_manager.py`       |
| `/ticket`     | integration | Jira issues through the Python client; superseded by `/jira`         | `jira_ticket_manager.py`      |

## Directory Structure

```
~/.claude/skills/
├── README.md
├── doc/, jira/, mkdoc/, note/, pr/, review/, spec/   # markdown skills: SKILL.md only
├── confluence/                                # integration skills: SKILL.md + script
│   ├── SKILL.md
│   └── confluence_manager.py
├── ticket/
│   ├── SKILL.md
│   └── jira_ticket_manager.py
├── pyproject.toml                             # shared dependencies (integration skills only)
├── uv.lock
└── .venv/                                     # shared virtual environment, created by `uv sync`
```

Skills are discovered exactly one level deep (`skills/<name>/SKILL.md`); grouping them in subfolders does not work.

## Markdown Skills

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

## Integration Skills

Everything in this section applies only to skills that ship a Python script.

### Shared Environment

All integration skills share one virtual environment at `~/.claude/skills/.venv/`, managed with `uv` and declared in
`pyproject.toml`. One environment keeps package versions consistent across skills and avoids a venv per skill.

```bash
cd ~/.claude/skills
uv sync              # create the environment / install dependencies
uv sync --upgrade    # upgrade dependencies
rm -rf .venv uv.lock && uv sync   # rebuild from scratch
```

Current dependencies: `atlassian-python-api`, `keyring` (both skills), `markdown` (`/confluence`).

### Invoking Scripts

`SKILL.md` calls the script through the shared interpreter, with absolute paths:

```bash
~/.claude/skills/.venv/bin/python ~/.claude/skills/<skill-name>/script.py [args]
```

### Credentials

Scripts read secrets from the system keyring, never from files in this repo. `/confluence` and `/ticket` share one
Atlassian token:

```bash
~/.claude/skills/.venv/bin/keyring set jira-api-token "$USER"
```

### Adding an Integration Skill

1. Create `<name>/SKILL.md` as for a markdown skill.
2. Add the script next to it and invoke it from `SKILL.md` as shown above.
3. Add any new dependencies to `pyproject.toml`, then run `uv sync` in `~/.claude/skills`.
4. Run `dot link` so the new files are symlinked into `~/.claude/skills/`.

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

These apply to both kinds of skill. Keep this list updated as new conventions come up while refining skills.

- **Mode prefix.** Start every `description` with `[hitl]` (needs the user
  during the run: interviews, confirmations, writes to shared systems) or
  `[auto]` (runs to completion on its own). Quote the description, since a
  leading `[` is otherwise parsed by YAML as a list.
- **Fork `[auto]` skills** with `context: fork` when their input is the repo,
  files or arguments alone. A forked skill runs in a background subagent
  without the conversation history, so keep skills that rely on the chat
  (summaries, selected code) inline. Always fork skills that judge work
  (reviews), so they aren't biased by the conversation that produced it.
  Unless its target is fixed (e.g. `pr` always works on the current
  branch), a forked skill must require an explicit target in the request
  (PR, commits, files) and stop if none is given, since it can't see the
  chat or ask. It also can't confirm mid-run, so replace any "confirm before X"
  step with a safe default.
- **Model choice.** Set `model` on forked skills and routine inline ones
  (API wrappers, note-taking): `sonnet` (latest Sonnet) for routine work,
  a pinned Opus ID where judgment matters (reviews). Leave it unset on
  skills that need the session's model, like `spec`.
- **Supported frontmatter only.** Unknown keys such as `title` or
  `permissions` are ignored locally and rejected by claude.ai. See
  https://code.claude.com/docs/en/skills for the valid fields.
- **Be concise.** State each rule once, in as few words as carry it. Cut
  restatements, explanations of the obvious, and filler intros.
- **Short, plain headers.** A few straightforward words (`Interview`,
  `Report results`), no sentence-style titles or parenthetical asides.
  Number them only when the steps must run in a strict order.
- **No Capabilities sections.** They repeat the frontmatter description.
- **No personas.** Don't open with "You are a senior engineer…" or similar
  role-play. State the skill's purpose (what it's for and what a good
  result looks like) and give concrete rules for the behavior you want.
  Specific rules and a clear goal guide judgment better than a role label.
- **No usage-example sections or argument syntax.** Skills take a
  free-form request. State the default behavior and let the request
  override it ("review against `master` unless the request names other
  changes"), instead of documenting positional arguments or flags.
