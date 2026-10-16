---
type: reference
title: Commit gate and CLAUDE_ALLOW_COMMIT
description: >-
    The `commit-gate.sh` hook that asks before every `git commit`, and the two ways past it: the `commit-agent` agent
    for forked skills, and the `CLAUDE_ALLOW_COMMIT` env var set when launching `claude`.
tags: [claude-code, permissions, hooks, git, skills]
status: stable
generated: { by: claude-code/claude-opus-5-5, at: 2026-10-16T17:49:29Z }
sources:
    - id: hook
      resource: ~/.dot/files/dotfiles/.claude/hooks/commit-gate.sh
      title: commit-gate.sh, the PreToolUse hook and its header comment
      author: human:jakub
    - id: probes
      resource: Claude Code conversation in ~/.dot on 2026-10-16, headless `claude -p` permission probes
      author: human:jakub
---

# Commit gate and CLAUDE_ALLOW_COMMIT

Every commit asks me, except where I let an unattended run commit on its own. The values and matching rules are in the
hook's header comment[^hook].

## How it fits together

- `settings.json` allows `Bash(git commit -m *)` and has no `ask` rule for `git commit`; the `PreToolUse` hook
  `~/.claude/hooks/commit-gate.sh` puts the ask back for every `git commit` (also behind `cd ... &&` or `git -C`).
- The hook stays silent, so the allow rule applies, when the caller is the `commit-agent` subagent, or when
  `CLAUDE_ALLOW_COMMIT` allows it: `1` for the whole session, or a comma list of extra agent types.
- `commit-agent` (`~/.claude/agents/commit-agent.md`) only carries the name the hook checks: no `model`, no `tools`.
  A forked skill that should commit unattended sets `context: fork` and `agent: commit-agent`, and picks its own
  `model`. `/feature` does.
- Unattended session: `CLAUDE_ALLOW_COMMIT=1 claude ...`. The zsh function `gC` (`.zshrc_aliases`) runs `/commit`
  headless this way.

## Why it is built this way

Found with headless probes[^probes]:

- An `ask` rule beats every `allow`, whatever its source: a skill's `allowed-tools`, an agent, a `--settings` file. So
  the ask has to live in a hook to be lifted per caller.
- `--setting-sources` without `user` drops user-level skills and agents too, so it can't replace the user settings.
- An env var can't be set for one subagent: the whole session shares the process env. The hook input carries
  `agent_type` for subagents (absent in the main session), which is how one agent is told apart.
- An `env` value in `settings.json` overrides the same var set at launch. `CLAUDE_ALLOW_COMMIT` must stay out of
  `settings.json`, which is why `commit-agent` is built into the hook instead.
- Testing it: a model often refuses a hand-written `git commit` because of my CLAUDE.md rule, and its own "ran /
  denied" answer is unreliable. Read `permission_denials` from `claude -p --output-format json` instead.

[^hook]: `~/.dot/files/dotfiles/.claude/hooks/commit-gate.sh`

[^probes]: Claude Code conversation in `~/.dot` on 2026-10-16
