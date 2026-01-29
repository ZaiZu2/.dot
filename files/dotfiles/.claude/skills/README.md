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

### `/jira`
Confluence Documentation Manager - Create and update Confluence pages directly from Claude.
- Location: `jira/`
- Script: `confluence_manager.py`
- Dependencies: atlassian-python-api, markdown, keyring

### `/note`
Zettelkasten Note Generator - Generate markdown notes from conversation context.
- Location: `note/`
- Dependencies: None (uses `zk` CLI)

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
├── jira/              # Jira/Confluence skill
│   ├── SKILL.md
│   └── confluence_manager.py
└── note/              # Note-taking skill
    └── SKILL.md
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
