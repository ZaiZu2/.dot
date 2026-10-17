---
okf_version: '0.2'
---

# Reference

- [Commit gate and CLAUDE_ALLOW_COMMIT](claude-allow-commit.md) - The `commit-gate.sh` hook that asks before every
  `git commit`, and the two ways past it: the `commit-agent` agent for forked skills, and the `CLAUDE_ALLOW_COMMIT` env
  var set when launching `claude`.
- [Dotfiles managed by the dot repo](dotfiles-managed-by-dot-repo.md) - The ~/.dot repo and its `dot` CLI: deployment of
  my dotfiles, tools and Claude Code config into $HOME, plus the mounting and loading of my personal, mounted and
  project OKF knowledge bundles.
- [My tmux setup](tmux-setup.md) - High-level map of my tmux setup in the dot repo: the session and project window
  model, the Claude Code integration through `claude agents --json` and per-session state files, and where to look for
  the details.
- [Open Knowledge Format (OKF) 0.2 specification](references/okf-spec-0-2.md) - Verbatim local copy of the OKF 0.2 spec,
  the authority for writing concepts, indexes and logs in my context bundles.
