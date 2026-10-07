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

## Actions

### 1. Stage

Stage the named paths with `git add <paths>`; never `git add -A` or `git add .`. Read `git diff --cached` in full. If it
holds changes the request doesn't cover, unstage them with `git restore --staged <paths>` and say so in the report.

### 2. Write the message

Follow [Format](#format), with the scope from [Scopes](#scopes). Use a subject or type from the request verbatim.

### 3. Commit

One command, with one `-m` per paragraph, never a heredoc or `$(...)`:

```bash
git commit -m "<subject>" -m "<body>" -m "Refs: <KEY>"
```

Leave out the `-m` of a missing body or key. The command asks the user unless the caller's permissions allow it.

## Rules

- Never `--amend`, `--no-verify` or `--allow-empty`.
- If a hook rejects the commit, report its output; fix only what the request covers, never bypass it.

## Format

```text
<type>(<scope>)!: <summary>

<body>

Refs: <KEY>
```

- **Type**: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `style` or `revert`.
- **Scope**: optional; leave out the parentheses with it.
- **`!`**: only for a breaking change, which also gets a `BREAKING CHANGE: <what breaks>` trailer after the body.
- **Summary**: imperative, lowercase, no period; the whole subject at most 72 characters.
- **Body**: optional; why the change was made, as a `-` list of concise, verbless sentences, wrapped at 72 characters.
  Never restate the diff.
- **Refs**: one `Refs: <KEY>` trailer per ticket, last. Ticket keys never go in the subject.

## Scopes

The first source that exists decides:

1. a `scope-enum` rule in the repo's commitlint config (`commitlint.config.*`, `.commitlintrc*`, `commitlint` in
   `package.json`);
2. a `Commit scopes` list in the project's `CLAUDE.md`;
3. free-form: one short lowercase name of the module or area the change is in, preferring scopes already used in
   `git log --format=%s -50`.

With a defined list, use only its scopes; leave the scope out when none fits or the change spans the whole repo.

## Report

The commit hash and the full message, or the reason nothing was committed.
