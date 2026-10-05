---
type: reference
title: Dotfiles managed by the dot repo
description:
    The ~/.dot repo and its `dot` CLI: deployment of my dotfiles, tools and Claude Code config into $HOME, plus the
    mounting and loading of my personal, mounted and project OKF knowledge bundles.
tags: [dotfiles, dot, configuration, claude-code, setup]
status: stable
generated: { by: claude-code/claude-opus-5-5, at: 2026-10-05T15:21:44Z }
sources:
    - id: dot-claude-md
      resource: ~/.dot/CLAUDE.md
      author: human:jakub
    - id: global-claude-md
      resource: ~/.dot/files/dotfiles/.claude/CLAUDE.md
      author: human:jakub
    - id: dot-code
      resource: ~/.dot/code/commands.sh
      author: human:jakub
---

# Dotfiles managed by the dot repo

## Role of the repo

`~/.dot` is the single source of truth for my personal configuration on macOS and Linux[^dot-claude-md]. It holds:

- `files/dotfiles/` - a tree mirrored file by file into `$HOME` (shell, tmux, Neovim, Claude Code, ...).
- `tools/` - one install script per tool in my curated tool set.
- `code/` and `dot.sh` - the implementation of the `dot` CLI.

Configuration under `$HOME` (including `~/.claude/`) is mostly symlinks pointing back into this repo, so edits to config
should be made in `~/.dot/files/dotfiles/...`, not to the files in `$HOME`[^dot-claude-md].

## The `dot` tool

Invoked as `dot <cmd>` (alias for `zsh $DOT/dot.sh`); `dot --help` lists all subcommands[^dot-claude-md].

- `dot link [-f]` - symlink every file under `files/dotfiles/` into `$HOME`. Required after adding a new file; edits to
  already tracked files show up immediately through the existing symlink.
- `dot update [-f]` - `git pull` the repo, then `dot link` with the pulled code.
- `dot setup` - full bootstrap: link, font, package manager and all tools (`--only`, `--exclude`, `--force`,
  `--skip-pkg-mgr`).
- `dot export` / `dot import` - move `origin/master..master` commits between machines as a patch bundle when there is no
  shared remote.
- `dot claude skills <path> -p <prefix>` - symlink skills of another repo's `.claude` dir into `~/.claude/skills/`.
- `dot claude context <path> -p <prefix>` - mount another repo's OKF context bundle as `~/.claude/context/<prefix>`.
- `dot claude mcp [<path>]` - register MCP servers from an `mcp.json` into Claude Code's user scope.

## Multiple knowledge bases

My knowledge lives in several OKF bundles at once, all gathered under `~/.claude/context/`[^global-claude-md]:

- **Personal** (`~/.claude/context/personal/`): tracked in this repo under `files/dotfiles/.claude/context/personal/`
  and linked file by file by `dot link`.
- **Mounted** (`~/.claude/context/<prefix>/`): the `.claude/context/` bundle of another repo (e.g. a work repo), mounted
  as one directory symlink by `dot claude context <path> -p <prefix>`. `-f` repoints an existing symlink, a real
  directory is never replaced, `-c` removes the mount again, and the prefix `personal` is reserved[^dot-code].
- **Project** (`<project root>/.claude/context/`): lives in the project itself, not under `~/.claude/context/`.

All of them reach the session through `CLAUDE.md` `@` imports, not a hook, so no bundle needs to be listed by
hand[^dot-code]:

1. Every `dot link` and every `dot claude context` (mount or `-c`) regenerates the untracked
   `~/.claude/context/imports.md`, with one bare `@<bundle>/index.md` line per `~/.claude/context/*/index.md`. It is
   rewritten only when the set of bundles changes.
2. The global `CLAUDE.md` imports that file with `@~/.claude/context/imports.md`. Claude Code expands imports
   recursively at session start, so the index of every personal and mounted bundle is loaded in full.
3. Project bundles are not covered by `imports.md`; each project's `CLAUDE.md` imports its own index with
   `@.claude/context/index.md`[^global-claude-md].

Each bundle keeps a single `index.md` at its root listing every concept, subdirectories included, so no concept hides
behind a subdirectory summary[^global-claude-md]. Mounted bundles are symlinks, so searching them needs `grep -R` /
`find -L`; `grep -r` skips them.

## Claude Code configuration

My global Claude Code setup (`CLAUDE.md`, `settings.json`, hooks, skills, `mcp.json`) and this personal context bundle
are tracked under `files/dotfiles/.claude/` and linked into `~/.claude/`[^global-claude-md]. New personal concepts are
written into the repo and surfaced with `dot link`.

## Rules

- Commits to the repo are made only by me, never by an agent[^global-claude-md].

[^dot-claude-md]: `~/.dot/CLAUDE.md`

[^global-claude-md]: `~/.dot/files/dotfiles/.claude/CLAUDE.md`

[^dot-code]: `~/.dot/code/commands.sh`
