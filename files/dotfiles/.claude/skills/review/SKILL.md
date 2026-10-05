---
name: review
description:
    "[auto] Review a specified PR, commits or changes and give structured feedback. Use when the user asks to review a
    specific PR, commits or changes."
context: fork
model: opus
---

# Code Review

Review code changes and give specific, actionable feedback. This runs as a separate agent so the review isn't biased by
the conversation that produced the change: judge it only by the diff, the surrounding code, commit messages and the PR
description. Read-only: don't modify files.

## Target

What the request names: a PR, commits or a commit range, or files or uncommitted changes. If the request names nothing,
stop and reply only that a PR, commits or changes must be specified.

If the request names a directory, work there: `cd` into it first, as a command of its own.

## Actions

### 1. Gather changes

Get the diff: `gh pr diff` and `gh pr view` for a PR (diff against the PR's base branch), `git diff` or `git show`
otherwise.

### 2. Run checks

Find the formatters, linters and static checkers the repo requires: `.pre-commit-config.yaml`, `pyproject.toml`,
`package.json` scripts, `Makefile`, CI workflows. Run each in check-only mode, on the changed files where the tool
takes paths.

- Never let a tool write: use `ruff format --check`, `prettier --check`, `terraform fmt -check` and the like, and no
  `--fix`. Don't run `pre-commit run`, since its hooks rewrite files; run the tools it configures instead.
- Run them only when the checked-out tree holds the change. Never check out, stash or install anything to get there.
  For a PR that isn't checked out, take the results from `gh pr checks` instead.
- Report only failures the change causes, not ones already on the base branch.

### 3. Analyze

Work out what the change is trying to achieve, then read every changed file and enough surrounding code to judge it.

- Read surrounding code before flagging something; it may be intentional.
- If a finding depends on how a called function behaves (raises, returns `None`), read that function first.
- Before judging documentation, read `${CLAUDE_SKILL_DIR}/../doc/SKILL.md` and `${CLAUDE_SKILL_DIR}/../mkdoc/SKILL.md`.
  They are the standard for docstrings, comments and markdown docs, not a task: write nothing. What they tell the
  author to leave out (an `Args:` block on a simple function, a trivial `__init__` docstring) is not a finding.
- Search docstrings, comments and the project's docs (`.md`/`.rst` in the root, `docs/`, `doc/`, `wiki/`, `.github/`)
  for whatever the change renames, removes or makes behave differently: signatures, return values, exceptions, CLI
  flags, env vars, defaults, config. Text the change makes untrue is a finding, also in a file the diff doesn't touch.
- Be proportionate: when there are blocking issues, skip nits.

### 4. Write the review

Include only sections with findings. Each finding is one bullet: a severity tag, `path:line`, and the issue.

- `[MUST]`: bugs, security issues, broken contracts
- `[SHOULD]`: clearly better, not critical
- `[NIT]`: style or low-impact

```markdown
## Code Review

### Summary

<1-2 sentences: what the change does and overall assessment>

### Correctness

- [MUST] `path/to/file.py:42`: <issue>

### Security

### Code Quality

### Type Safety

### Documentation

### Language-Specific

### Checks

### Verdict

<one-sentence justification>
```

Section scope:

- **Correctness**: logic bugs, wrong assumptions, off-by-one errors, races, broken edge cases
- **Security**: injection, authn/authz, secrets in code, unsafe deserialization, unvalidated input at boundaries
- **Code Quality**: needless complexity, duplication, misleading names, broken abstractions, dead code
- **Type Safety**: missing or wrong hints, unsafe casts, ignored type errors, `Any` where a type is known
- **Documentation**: docstrings, comments and project docs the change leaves stale or missing, or writes against the
  `doc` and `mkdoc` rules; docs describing behavior the code doesn't have; non-obvious config lines without a comment;
  leftover comments asking for documentation (`# document this`)
- **Language-Specific**: the checks below
- **Checks**: failures from step 2, each with the command that produced it; `[MUST]` when CI or pre-commit enforces
  the check, `[SHOULD]` otherwise. Name every required check that wasn't run, and why. Unlike the other sections,
  include this one whenever a check was skipped.

## Language checks

Python:

- Mutable default arguments
- Bare `except:` or `except Exception:` that silences errors
- `type(x) == Foo` instead of `isinstance`
- Missing `__all__` in public modules
- Blocking I/O in async functions
- f-strings in logging calls (use `%s` or `extra=`)
- `.format()` or interpolation into SQL

TypeScript / JavaScript:

- `any` where a type is known
- `console.log` left in production code
- Missing `await`
- String interpolation into SQL or shell commands
- `==` instead of `===`

## Report

Your final message must be the complete review, not a summary of it.
