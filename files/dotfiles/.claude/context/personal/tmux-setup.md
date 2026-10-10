---
type: reference
title: My tmux setup
description: >-
    High-level map of my tmux setup in the dot repo: the session and project window model, the Claude Code integration
    through per-pane state files, and where to look for the details.
tags: [tmux, dotfiles, workflow, claude-code]
status: stable
generated: { by: claude-code/claude-opus-5-5, at: 2026-10-10T13:43:09Z }
sources:
    - id: tmux-dir
      resource: ~/.dot/files/dotfiles/.config/tmux/
      title: tmux.conf and the workspace scripts
      author: human:jakub
    - id: claude-dir
      resource: ~/.dot/files/dotfiles/.claude/
      title: Claude Code hooks, statusline.sh and settings.json
      author: human:jakub
---

# My tmux setup

An overview to orient by. Key bindings, options, plugins and the behavior of each script are not repeated here: read
`tmux.conf` and the header comment of the script in question.

## Where things are

- `~/.dot/files/dotfiles/.config/tmux/`: `tmux.conf` plus the workspace scripts, which are plain shell scripts bound to
  keys in `tmux.conf`, not tpm plugins[^tmux-dir]. See [the dot repo](/dotfiles-managed-by-dot-repo.md) for linking.
- `~/.dot/files/dotfiles/.claude/`: the Claude Code side of the integration (`hooks/`, `statusline.sh`,
  `settings.json`)[^claude-dir].

## Workspace model

- A fixed set of sessions, one per main project, created automatically when the tmux server starts.
- One window per project, in a three-pane layout: utility | code | Claude. Scripts rely on that shape, e.g. the middle
  pane's cwd is what identifies a window's project[^tmux-dir].
- Navigation goes through fzf popups ("pickers") instead of tmux's own choosers: one for project windows, one for
  Claude panes across all sessions.

## Claude Code integration

Claude Code and tmux talk through small per-pane state files under `$TMPDIR`, named after the tmux pane id. Claude's
side writes them, tmux's side reads them:

| State                              | Written by                         | Read by                                 |
| ---------------------------------- | ---------------------------------- | --------------------------------------- |
| working / waiting on me / idle     | `hooks/claude-waiting-mark.sh`     | Claude picker (state dot)               |
| prompt cache expiry                | `statusline.sh`                    | Claude picker (cache column)            |
| pending cache-expiry reminders     | `claude_cache_notify.sh`           | its own popup                           |

The status line is the source of truth for the prompt cache: Claude Code passes it the cache TTL and expiry, and a
refresh interval in `settings.json` keeps it running while a session is idle. It shows the time left and starts the
reminder shortly before a cache expires[^claude-dir].

Decisions that the code alone does not explain:

- Reminders are only for the 1h cache; a 5m cache would remind after every short break.
- Several expiring panes share one popup rather than a popup each.
- No desktop notification on Windows/WSL, by choice; macOS and Linux desktops get one.

[^tmux-dir]: `~/.dot/files/dotfiles/.config/tmux/`

[^claude-dir]: `~/.dot/files/dotfiles/.claude/`
