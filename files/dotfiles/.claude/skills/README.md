# Claude Code Skills

This directory contains custom skills for Claude Code with a shared Python environment.

## Shared Python Environment

All Python-based skills share a single virtual environment located at `.venv/` to:
- Reduce disk space usage
- Simplify dependency management
- Ensure consistent package versions across skills

### Setup

The shared environment is managed with `uv` and configured in `pyproject.toml`:

```bash
# Install/update dependencies
cd ~/.claude/skills
uv sync

# Add new dependencies
# Edit pyproject.toml, then run:
uv sync
```

### Using the Shared Environment

Python skills should invoke scripts using the shared interpreter:

```bash
~/.claude/skills/.venv/bin/python ~/.claude/skills/<skill-name>/script.py [args]
```

## Available Skills

### `/confluence`
Confluence Documentation Manager - Create and update Confluence pages directly from Claude.
- Location: `confluence/`
- Script: `confluence_manager.py`
- Dependencies: atlassian-python-api, markdown, keyring

### `/ticket`
JIRA Ticket Manager - Create, update, search, and transition JIRA issues.
- Location: `ticket/`
- Script: `jira_ticket_manager.py`
- Dependencies: atlassian-python-api, keyring

### `/note`
Zettelkasten Note Generator - Generate markdown notes from conversation context.
- Location: `note/`
- Dependencies: None (uses `zk` CLI)

### `/spec`
Feature Spec - Interview-driven feature planning that cross-checks answers against the codebase and outputs a spec.
- Location: `spec/`
- Output: `<repo root>/.claude/docs/<feature-slug>.md`
- Dependencies: None

### `/doc`, `/mkdoc`
Docstrings and markdown documentation for code, matching the project's existing style.
- Location: `doc/`, `mkdoc/`
- Dependencies: None

### `/pr`, `/review`
Create or update the GitHub PR for the current branch; review a PR, commits or changes.
- Location: `pr/`, `review/`
- Dependencies: None (uses `gh`)

## Work Skills

Skills are discovered exactly one level deep (`skills/<name>/SKILL.md`); grouping them in subfolders does not work.
To use skills from another repo (e.g. work), link them in with a prefix to keep the namespaces apart:

```bash
dot claude <path-to-.claude-dir> --prefix ps
```

This symlinks `<path>/skills/<name>/...` to `~/.claude/skills/ps-<name>/...`; the prefix is one lowercase word, joined
to the skill name with `-`. Re-run it after adding files; use `--force` to overwrite existing files. To unlink them
again:

```bash
dot claude <path-to-.claude-dir> --prefix ps --clean
```

Only symlinks pointing into that repo are removed, so personal skills and other prefixes are untouched.

## Cross-file References

Skills can point Claude at other files: "Before X, read `${CLAUDE_SKILL_DIR}/file.md`". Name the trigger, keep it one
hop deep, and use resolvable paths. `@file` imports are documented for `CLAUDE.md`; don't rely on them in skills.

## Writing SKILL.md Instructions

Keep this list updated as new conventions come up while refining skills.

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

## Adding New Python Skills

1. Create a new skill directory:
   ```bash
   mkdir ~/.claude/skills/my-skill
   ```

2. Create `SKILL.md` with skill metadata (see existing skills for examples)

3. Add Python scripts that use the shared venv:
   ```python
   #!/usr/bin/env python3
   # Use: ~/.claude/skills/.venv/bin/python this_script.py
   ```

4. Add any new dependencies to `pyproject.toml`:
   ```toml
   dependencies = [
       "existing-package>=1.0.0",
       "new-package>=2.0.0",  # Add here
   ]
   ```

5. Sync dependencies:
   ```bash
   cd ~/.claude/skills && uv sync
   ```

## Directory Structure

```
~/.claude/skills/
├── .venv/              # Shared virtual environment
├── pyproject.toml      # Shared dependencies
├── uv.lock            # Lock file
├── README.md          # This file
├── confluence/        # Confluence documentation skill
│   ├── SKILL.md
│   └── confluence_manager.py
├── ticket/            # JIRA ticket management skill
│   ├── SKILL.md
│   └── jira_ticket_manager.py
└── doc/, mkdoc/, pr/, review/, spec/, note/   # SKILL.md only
```

## Maintenance

### Update Dependencies
```bash
cd ~/.claude/skills
uv sync --upgrade
```

### Rebuild Environment
```bash
cd ~/.claude/skills
rm -rf .venv uv.lock
uv sync
```
