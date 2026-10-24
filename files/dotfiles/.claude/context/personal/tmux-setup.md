---
type: reference
title: My tmux setup
description: >-
    High-level map of my tmux setup in the dot repo: the session and project window model, the Claude Code integration
    through `claude agents --json` and per-session state files, and where to look for the details.
tags: [tmux, dotfiles, workflow, claude-code]
status: stable
generated: { by: claude-code/claude-opus-5-5, at: 2026-10-24T12:23:50Z }
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
  every Claude across all sessions.

## Claude Code integration

The list of Claudes comes from `claude agents --json`, the documented list of every live session with its kind, pid
and status (busy / waiting / idle). `claude_sessions.sh` ties each session to a tmux pane when the pane's shell is an
ancestor of the session's pid[^tmux-dir]. That leaves three kinds of rows in the Claude picker and the reminder popup:

- a session with its pane: a plain `claude` started in that pane;
- a session without a pane (`◌ bg <id>`): moved to the background with `←` or `/background`, so it runs in a Claude
  daemon worker outside any pane;
- a pane running a Claude client with no session (`?`): agent view or `claude attach`, showing one of the background
  sessions.

Nothing documented says which background session such a pane shows. The client sets the pane title to the session's
name, so a client pane whose title and cwd match exactly one background session, and no other pane, is merged into
that session's row. Any ambiguity, or a release that changes the title, leaves the two listed apart.

State files under `$DOT_STATE_DIR/claude/` (`DOT_STATE_DIR` defaults to `$TMPDIR/dot-state`), one subfolder per kind
of state, carry what the session list does not; all but the pins are named after the session id:

| State                          | Path under `claude/`                | Written by               | Read by                                |
| ------------------------------ | ----------------------------------- | ------------------------ | -------------------------------------- |
| prompt cache expiry            | `expiry/<session_id>`               | `statusline.sh`          | Claude picker (cache column), reminder |
| reminder sent for an expiry    | `notified/<session_id>`             | `statusline.sh`          | `statusline.sh`                        |
| pending cache-expiry reminders | `queue/<session_id>`, `queue.lock/` | `claude_cache_notify.sh` | its own popup                          |
| pins, one file per slot        | `pins/<n>` (n = 1..4)               | `claude_pins.sh`         | `claude_pins.sh`, Claude picker        |

The Claude picker prunes `expiry/` and `notified/` files of sessions that are gone, and nothing else.

The status line is the source of truth for the prompt cache: Claude Code passes it the session id, cache TTL and
expiry on stdin, and a refresh interval in `settings.json` keeps it running while a session is idle. It shows the time
left and starts the reminder shortly before a cache expires[^claude-dir].

Pins put up to four Claudes on global keys: `claude_pins.sh` pins a session by its id (a `?` pane by its pane id and
the tmux server's start time) and resolves the pin through `claude_sessions.sh` on every jump, so a pin follows its
session to whichever pane shows it and is never served from a cached pane[^tmux-dir].

Decisions that the code alone does not explain:

- Per-session state is keyed by session, never by `$TMUX_PANE`: a background session's status line and hooks run
  without it. Only a pin of a `?` pane, which has no session, is keyed by its pane id.
- Nothing reads Claude Code's undocumented internals (`~/.claude/sessions/`, the daemon roster), which could change in
  any release. The pane title is used only for the merge above, where a mismatch fails safe.
- Reminders are only for the 1h cache; a 5m cache would remind after every short break.
- Several expiring sessions share one popup rather than a popup each.
- No desktop notification on Windows/WSL, by choice; macOS and Linux desktops get one.

[^tmux-dir]: `~/.dot/files/dotfiles/.config/tmux/`

[^claude-dir]: `~/.dot/files/dotfiles/.claude/`
