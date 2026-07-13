# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal cross-platform dotfiles manager. The `dot` shell program symlinks
configuration into `$HOME` and installs a curated tool set declaratively.
macOS + Linux.

## Commands

Invoke via `./dot.sh <cmd>` or the `dot` alias
(`files/dotfiles/.zshrc_aliases:42` → `zsh $DOT/dot.sh`). `dot --help` lists
every subcommand; the ones with non-obvious behavior:

- `dot link` — symlink dotfiles into `$HOME`. **Required after adding any
  new file under `files/dotfiles/`**; existing tracked files update in place
  through the symlink and need no re-link.
- `dot setup` — full bootstrap (link + font + package mgr + all tools).
  Accepts `--only <tools>`, `--exclude <tools>`, `--force`, `--skip-pkg-mgr`.
- `dot export [patch.zip]` / `dot import [patch.zip]` — package/apply
  `origin/master..master` as a git-format-patch bundle. Used to move commits
  across machines with no shared remote.

## Architecture

### Tool installation contract

Each `tools/<name>.sh` script exposes three functions:

- `deps_<name>()` — echo space-separated tool names this tool depends on.
  Drives install ordering.
- `is_installed_<name>()` — return 0 if already installed. Skipped unless
  `--force`.
- `install_<name>()` — perform the install. Should call `fail`/`finish`/
  `warn` (from `code/tool.sh`) to report status; those write to
  `$CURR_TOOL_STATUS` so the parent renders the framed box UI.

`list_tools` discovers the tool set from filenames in `tools/` — adding a
new tool means dropping a file that follows the contract, no central
registration. `code/commands.sh:install_tools` topologically orders by deps
and forks each install into a subshell whose stdout/stderr is captured and
framed.

### symlink_dotfiles behavior

Walks `files/dotfiles/**/*` and symlinks every **file** into the matching
path under `$HOME` (directories are traversed but not linked, so the target
tree structure is preserved verbatim). Existing correct symlinks are
skipped; broken symlinks pointing back at this repo are cleaned up.
`--force` overwrites regular files and stale symlinks. Editing an existing
tracked file needs no re-link — the symlink already points here.

### Layout

- `dot.sh` — CLI dispatch only; sources `code/*.sh` and delegates.
- `code/` — implementation of the `dot` program. Platform-specific
  package-manager init lives in `code/darwin.sh` / `code/linux.sh`; sourced
  by `load_platform` based on `uname`.
- `tools/` — one file per installable tool (see contract above).
- `files/dotfiles/` — the tree mirrored into `$HOME`. Includes non-trivial
  tmux workspace scripts under `.config/tmux/` (project picker, cross-session
  window overlay, three-pane layout) — bindings are in `tmux.conf`, scripts
  are plain shell (not tpm plugins).

## Repository conventions

- Never commit to git — user does that (from
  `files/dotfiles/.claude/CLAUDE.md`).
- New files under `files/dotfiles/` require `dot link` before they surface
  in `$HOME`.

## Neovim: adding a formatter/linter

Central config lives in `files/dotfiles/.config/nvim/lua/config.lua` and is
consumed by three plugin bootstraps:

- `plugins/format.lua` reads `formatters.ft` / `formatters.config` into
  `conform.nvim`.
- `plugins/lint.lua` reads `linters.ft` / `linters.custom` into
  `nvim-lint`.
- `plugins/mason.lua` walks the same tables to build
  `mason-tool-installer`'s `ensure_installed` list.

Three name spaces are in play and often disagree — do not assume they
match:

- **filetype key** in `ft` tables must be Neovim's filetype (`terraform`,
  not `tf`; `dockerfile`, not `docker`). Check with `:set ft?` on a real
  buffer if unsure.
- **tool name** (values in `ft` lists) must be the exact name registered
  by conform.nvim (`conform/formatters/*.lua`) or nvim-lint
  (`nvim-lint/lua/lint/linters/*.lua`). Examples: `terraform_fmt` (not
  `terraform`), `terraform_validate` (not `terraform`), `ruff_format`
  (not `ruff`).
- **mason package name** — mason-tool-installer takes the tool name
  verbatim unless `formatters.config[<name>].mason_name` overrides it.
  When the conform/lint name differs from mason's package (`terraform_fmt`
  → mason `terraform`, `ruff_format` → mason `ruff`), the override is
  mandatory or startup will error with `Cannot find package "<name>"`.

Both formatters and linters support a `mason_name` override in their
`config.<name>` entry (`formatters.config` / `linters.config`) —
mason-tool-installer resolves through it before adding to
`ensure_installed`.

`plugins/format.lua` guards on `fmt_conf.conf_files ~= nil` before
building the config-path arg injector — formatters that take no
`--config` flag (e.g. `terraform_fmt`) should have a `config` entry with
only `mason_name` set, or no `config` entry at all.
