---
name: commit
description:
    '[auto] Commit staged or named changes with a Conventional Commits message. Use when the user asks to commit, or a
    finished change should be committed.'
model: sonnet
---

# Commit

Commit one logical change with a Conventional Commits message. A good message tells a reader of `git log --oneline` what
changed and where, and its body says why when the diff doesn't.

## Target

The paths the request names, else what is staged. Stop and reply only with the reason if nothing is named or staged, or
the named paths have no changes.

If the request names a directory, work there: `cd` into it first, as a command of its own.

The ticket keys: those the request names, else one `[A-Z][A-Z0-9]+-[0-9]+` in the branch name (`FAPE-1319`), else none.
A `Part:` trailer only when the request names its value (`/feature` does, to mark a finished part of a spec).

## Actions

### 1. Stage

Stage the named paths with `git add <paths>`; never `git add -A` or `git add .`. Read `git diff --cached` in full. If it
holds changes the request doesn't cover, unstage them with `git restore --staged <paths>` and say so in the report.

### 2. Write the message

Follow [Format](#format), with the scope from [Scopes](#scopes). Use a subject or type from the request verbatim.

### 3. Commit

One command, with one `-m` per paragraph and one `--trailer` per trailer, never a heredoc or `$(...)`:

```bash
git commit -m "<subject>" -m "<body>" --trailer "Part: <id>" --trailer "Refs: <KEY>"
```

Leave out the `-m` of a missing body and the `--trailer` of a missing part or key. The command asks the user unless the
caller's permissions allow it.

### 4. Handle a rejecting hook

Only when a hook rejects the commit. Read its output, then take the first that applies:

1. The hook rewrote files (a formatter): stage those of the commit's paths again and commit again.
2. It rejects the message (commitlint): fix the message and commit again.
3. It reports a problem in the commit's own paths that takes a line or two to fix: fix it, stage and commit again.
4. Only lint, format or style complaints are left, and the request says hooks may be bypassed: commit once more with
   `--no-verify` as the last argument.

Otherwise stop and report the output. Try each of 1-3 once. "May bypass" covers lint, format and style only: never a
failing test, a type or build error, a secret or credential scanner, a merge-conflict or large-file check, or a hook
that guards the branch.

## Rules

- Never `--allow-empty`.
- `--no-verify` when the request asks to skip the hooks: add it as the last argument of the first attempt, whatever the
  hooks check. Otherwise only as step 4 says.
- `--amend` only when the request asks for it and no remote branch holds `HEAD` (`git branch -r --contains HEAD` prints
  nothing). Keep the message with `--no-edit` unless the request changes it, and keep its trailers when it does. If
  `HEAD` is pushed, make a new commit instead and say so.

## Format

```text
<type>(<scope>)!: <summary>

<body>

Part: <id>
Refs: <KEY>
```

- **Type**: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style` or `revert`.
- **Scope**: optional; leave out the parentheses with it.
- **`!`**: only for a breaking change, which also gets a `BREAKING CHANGE: <what breaks>` trailer after the body.
- **Summary**: imperative, lowercase, no period; the whole subject at most 72 characters.
- **Body**: omit it when the subject plus diff already says why; add it only when the why is non-obvious. When present,
  at most 2 short `-` bullets, each a terse verbless phrase (not a sentence), wrapped at 72 characters. Never restate
  the diff or repeat the subject.
- **Trailers**: `Part: <id>` when named, then one `Refs: <KEY>` per ticket, together as the last paragraph. Ticket keys
  never go in the subject.

## Scopes

The first source that exists decides:

1. a `scope-enum` rule in the repo's commitlint config (`commitlint.config.*`, `.commitlintrc*`, `commitlint` in
   `package.json`);
2. a `Commit scopes` list in the project's `AGENTS.md`, else its `CLAUDE.md`;
3. free-form: one short lowercase name of the module or area the change is in, preferring scopes already used in
   `git log --format=%s -50`.

With a defined list, use only its scopes; leave the scope out when none fits or the change spans the whole repo.

## Report

The commit hash and the full message, or the reason nothing was committed. If a hook rejected it, say what the hook
reported and what was done about it, and name a `--no-verify` or `--amend` explicitly.
