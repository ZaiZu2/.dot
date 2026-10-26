---
name: copilot-review
description:
    "[auto] Review a specified PR, commits or changes with GitHub Copilot CLI on a non-Claude model, following the
    review skill, and fall back to the review skill when Copilot is unavailable or fails."
context: fork
model: sonnet
allowed-tools:
    - Bash(copilot -p *)
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

### 1. Run Copilot

If `command -v copilot` finds nothing, go to [Fallback](#fallback). Otherwise run, with a Bash timeout of 600000 ms:

```sh
copilot -p "Use the review skill to review <target>. Work in <dir>. Write the report to <report path>." \
  -C <dir> -s --no-ask-user --allow-all --model gpt-6.1-sol --reasoning-effort high
```

Write `<target>` as the request gives it. The command starts with `copilot -p`, which the skill's `allowed-tools`
allows; don't prefix it with `cd` or variables.

### 2. Check

Copilot worked when it exited with 0, its output is a review in the layout of `review` (`## Code Review` through
`### Verdict`) and the report file holds it. Otherwise go to [Fallback](#fallback).

### Fallback

Call the Skill tool with `review`, naming the same target, `<dir>` to run in and the same report path. Return its
review as this skill's result.

## Report

The complete review, as the report file holds it, not a summary. Above it, one line naming the reviewer: `Copilot
(gpt-6.1-sol)`, or `review (fallback: <reason>)` with what failed (Copilot missing, its exit code and the last lines
of its output, a timeout, output that isn't a review). End with the path of the report file.
