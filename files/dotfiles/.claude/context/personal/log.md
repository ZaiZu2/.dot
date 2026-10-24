# Directory Update Log

## 2026-10-24

- Updated [My tmux setup](tmux-setup.md): the Claude state moved from `$TMPDIR/claude-cache/` to
  `$DOT_STATE_DIR/claude/`, one subfolder per kind of state, and the Claude pins are added to the state table and the
  Claude Code integration.

- Updated [Caller-scoped permission gates](caller-scoped-permission-gate.md), formerly `claude-allow-commit.md`: now a
  note on the design for gating any sensitive action, with the commit gate as its example; the file is renamed to
  match.

## 2026-10-19

- Updated [Dotfiles managed by the dot repo](dotfiles-managed-by-dot-repo.md): the rules for writing concepts moved
  from the global `CLAUDE.md` into the `remember` skill, and the commit rule now names the commit gate's exceptions
  instead of saying agents never commit.

## 2026-10-16

- Created [Commit gate and CLAUDE_ALLOW_COMMIT](claude-allow-commit.md), covering the `commit-gate.sh` hook, the
  `commit-agent` agent and the `CLAUDE_ALLOW_COMMIT` launch env var, with the probe findings that shaped them, and
  the `gC` zsh function that uses it.

## 2026-10-14

- Updated [Dotfiles managed by the dot repo](dotfiles-managed-by-dot-repo.md): the repo's instructions moved from
  `CLAUDE.md` to `AGENTS.md`, and project bundles are now imported from a project's `AGENTS.md`.

## 2026-10-12

- Updated [My tmux setup](tmux-setup.md): the Claude integration now lists sessions from `claude agents --json` and
  keys its state files by session id instead of tmux pane, so sessions moved to the background are tracked too.
- Updated [My tmux setup](tmux-setup.md): a client pane is now merged with the background session it shows when its
  title and cwd match that session uniquely.

## 2026-10-10

- Created [My tmux setup](tmux-setup.md), a high-level map of the session and project window model and the Claude
  Code integration, pointing at the files that hold the details.
- Updated [Dotfiles managed by the dot repo](dotfiles-managed-by-dot-repo.md): its `description` was an unquoted
  multi-line scalar containing `: `, which is not parseable YAML; it is now a folded block scalar with the same text.

## 2026-10-05

- Created [Open Knowledge Format (OKF) 0.2 specification](references/okf-spec-0-2.md), a verbatim local copy of the spec.
- Created [Dotfiles managed by the dot repo](dotfiles-managed-by-dot-repo.md), covering the dot repo, the `dot` CLI and
  how multiple knowledge bases (personal, mounted, project) are mounted and loaded through the generated `imports.md`.
