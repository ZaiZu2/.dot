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

## Actions

### 1. Gather changes

Get the diff: `gh pr diff` and `gh pr view` for a PR (diff against the PR's base branch), `git diff` or `git show`
otherwise.

### 2. Analyze

Work out what the change is trying to achieve, then read every changed file and enough surrounding code to judge it.

- Read surrounding code before flagging something; it may be intentional.
- If a finding depends on how a called function behaves (raises, returns `None`), read that function first.
- Be proportionate: when there are blocking issues, skip nits.

### 3. Write the review

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

### Verdict

<one-sentence justification>
```

Section scope:

- **Correctness**: logic bugs, wrong assumptions, off-by-one errors, races, broken edge cases
- **Security**: injection, authn/authz, secrets in code, unsafe deserialization, unvalidated input at boundaries
- **Code Quality**: needless complexity, duplication, misleading names, broken abstractions, dead code
- **Type Safety**: missing or wrong hints, unsafe casts, ignored type errors, `Any` where a type is known
- **Documentation**: missing or misleading docstrings and comments, undocumented public APIs
- **Language-Specific**: the checks below

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
