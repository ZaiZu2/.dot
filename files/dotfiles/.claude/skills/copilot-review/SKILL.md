---
name: copilot-review
description:
    "[auto] Review a specified PR, commits or changes with GitHub Copilot CLI on a non-Claude model, following the
    review skill, and fall back to the review skill when Copilot is unavailable or fails."
context: fork
model: sonnet
allowed-tools:
    - Bash(copilot -p *)
    - Bash(realpath *)
    - Bash(command -v copilot)
---

# Copilot Review

Get the review of the `review` skill from a model of another provider, so the change is judged by a different model
than the one that wrote it. Copilot CLI runs the review itself, following `~/.claude/skills/review/SKILL.md`; this
skill only starts it and returns its report. Don't review the change yourself.

## Target

As in `review`: a PR, commits or a commit range, or files or uncommitted changes; stop if the request names none. The
directory to run in is the one the request names (a worktree), else the current one; `<dir>` is its absolute path.
The report path is the one the request names, else `review`'s default with `-copilot` before `.md`
(`.claude/review/pr-12-copilot.md`).

## Actions

### 1. Find the context directories

`review` runs with the context Claude Code loads: `~/.claude/CLAUDE.md`, the repository's `AGENTS.md` and the context
bundles both import with `@`. Copilot loads `~/.claude/CLAUDE.md` (as `~/.copilot/copilot-instructions.md`) and the
repository's `AGENTS.md`, but doesn't expand `@` imports, so it is told to read them, and needs access to them. Most of
them are symlinks into other repositories, which Copilot refuses to follow unless it can reach the target. Resolve
them:

```sh
realpath ~/.claude/skills/README.md ~/.claude/context/*/index.md
```

The directory of each printed path is a `<link dir>` for step 2.

### 2. Run Copilot

If `command -v copilot` finds nothing, go to [Fallback](#fallback). Otherwise run, with a Bash timeout of 600000 ms:

```sh
copilot -p "Use the review skill to review <target>. You are the reviewer already: skip its 'Where it runs' section and delegate to no one. Before reviewing, read every file your instructions and the AGENTS.md in <dir> import with @, and the concepts of the imported context indexes that bear on the change. Work in <dir>. Write the report to <report path>." \
  -C <dir> -s --no-ask-user --model gpt-6.1-sol --reasoning-effort high \
  --add-dir <report dir> --add-dir ~/.claude --add-dir <link dir> ... \
  --deny-tool 'read(~/.claude/projects/**)' 'read(~/.claude/settings*.json)' 'read(~/.claude/.credentials.json)' \
    'read(~/.claude/history.jsonl)' \
  --allow-tool 'write(<report path>)' \
  --allow-tool 'shell(git diff)' 'shell(git log)' 'shell(git show)' 'shell(git status)' 'shell(git blame)' \
    'shell(git rev-parse)' 'shell(git merge-base)' 'shell(git worktree list)' 'shell(git ls-files)' 'shell(git grep)' \
  --allow-tool 'shell(gh pr view)' 'shell(gh pr diff)' 'shell(gh pr checks)' 'shell(gh pr list)' \
  --allow-tool 'shell(mypy)' 'shell(pyright)' 'shell(shellcheck)'
```

Write `<target>` as the request gives it; `<report dir>` is the directory of `<report path>`, absolute; repeat
`--add-dir` for each `<link dir>`. `~/.claude` is added whole for its context, so the `--deny-tool` rules keep the
transcripts, settings and credentials in it unread. Never `--allow-all`, `--yolo` or `--allow-all-tools`: the review
reads the change, runs check-only linters and writes one file, and `--no-ask-user` makes Copilot refuse anything
outside this list. A `shell(...)` rule matches the command name, not its arguments, so allow only linters without a
mode that edits files: `ruff`, `prettier`, `eslint`, `tsc` and `terraform fmt` would also allow `--fix`, `--write` or a
build. The command starts with `copilot -p`, which the skill's `allowed-tools` allows; don't prefix it with `cd` or
variables.

If the permission system denies the command, don't ask, stop or retry it in any variant: go to
[Fallback](#fallback) with the denial message as the reason. Falling back is this skill's design, so it doesn't count
as the silent retry the global rules forbid.

### 3. Check

Copilot worked when it exited with 0, its output is a review in the layout of `review` (`## Code Review` through
`### Verdict`) and the report file holds it. Otherwise go to [Fallback](#fallback).

### Fallback

Call the Skill tool with `review`, naming the same target, `<dir>` to run in and the same report path. Return its
review as this skill's result.

## Report

The complete review, as the report file holds it, not a summary. Above it, one line naming the reviewer: `Copilot
(gpt-6.1-sol)`, or `review (fallback: <reason>)` with what failed (Copilot missing, its exit code and the last lines
of its output, a timeout, a permission denial with its message, output that isn't a review). End with the path of the
report file.
