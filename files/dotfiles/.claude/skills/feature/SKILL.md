---
name: feature
description:
    '[auto] Implement a scoped spec unattended from its worktree, or resume a stopped run: code, review, local checks
    and PRs.'
context: fork
agent: commit-agent
model: opus
disable-model-invocation: true
allowed-tools:
    - Bash(git push)
    - Bash(git push -u origin *)
    - Bash(git stash push *)
---

# Feature

Turn a spec that `/scope` has split into parts into reviewed, open pull requests, one per repository. The run
distributes the parts: it implements a part itself, or hands independent parts to `implement` subagents that work
at the same time, each in its repository's worktree. A good result is PRs that do what the parts ask, and a handback
that says what was done, what the review found and what was done about each finding.

The session runs inside the worktree `/scope` created for the spec, so every command, forked skill and subagent
starts there. This runs as a forked `commit-agent`, so no one can be asked during the run: resolve every open
question with the defaults under [Without a user](#without-a-user), and list each in the report.

## Target

The spec file the request names, by its absolute path: the spec and its part files stay in the main checkout and are
only read. The run covers every block of its `Parts` section, or only the repositories the request names. A run that
stopped part-way is continued by starting it again the same way.

`<feature>` is the name of the spec's directory (`.claude/features/<feature>/spec.md` gives `<feature>`). Each block's
review report goes to `<worktree>/.claude/features/<feature>/review.md`.

The `Parts` section, written by `/scope`, holds everything the run needs; use its values as written and don't work
any of them out again. It has one block per repository, in the order the PRs merge. Each block gives `Checkout`
(`<main>` below), `Base` (`<base>`), `Branch` (`<branch>`), `Worktree` (`<worktree>`), `Test suite` and `Parts`, each
part with its id (`<id>`), the path of its file, the parts it comes after, the files it changes and, when `/scope`
wrote Jira issues, its key. A part's file is its brief; the rest of the spec is background. The run never reads Jira:
a key is only passed on to commits.

Stop with the reason if no spec is named, if it has no `Parts` section or a block lacks one of these values (tell the
user to run `/scope`), if a named repository has no block, or if a part's file is missing. Then, for each block of the
run:

- The session's working directory (`git rev-parse --show-toplevel`) must be the `<worktree>` of one of the run's
  blocks; otherwise stop, and tell the user to start Claude in that worktree.
- Every `<worktree>` must exist with `<branch>` checked out (`git branch --show-current` in it); otherwise stop and
  tell the user to run `/scope`. A worktree other than the session's must also be writable: if an edit there is
  denied, stop that block and tell the user to add it with `/add-dir`.
- A block resumes when `<base>..HEAD` has commits or `git status --porcelain` isn't empty; otherwise it starts fresh.
- A part that comes after a part of a block outside this run: stop unless that part is done on its block's
  branch (a commit with its `Part: <id>` trailer in `<base>..<branch>`, read as in [Commits](#commits) in its
  `<main>`).
- A block outside this run that merges before one inside it, and has no open PR (`gh pr list --head <branch>` in its
  `<main>` finds none): continue, and report it as an ordering risk.

## Actions

### 1. Prepare

For each block that starts fresh. All work happens in the worktrees, never in a main checkout.

Run `uv sync --quiet` in the worktree if it has a `pyproject.toml`.

Then take the baseline: run the test suite command in the untouched worktree, and write the ids of the tests that fail
to the file `git rev-parse --git-path feature-baseline` names (it is never committed). These failures belong to the
base, not to this branch. With `none`, skip this.

### 2. Resume

For each block that resumes. Rebuild its branch's state from git and GitHub, then continue it from its first
unfinished phase.

**Worktree.** Run `uv sync --quiet` if there is a `pyproject.toml`.

**Progress**, from the commits of `<base>..HEAD`, read as in [Commits](#commits):

- A part is done when a commit has its `Part: <id>` trailer.
- A PR exists when `gh pr view --json url,state` succeeds. If it is closed or merged, stop that block and report.
- The review is done when a commit subject matches `fix: PR#<no> review`.
- The branch is pushed when `git status -sb` shows an upstream and nothing ahead of it.

**Leftovers.** If `git status --porcelain` isn't empty, ignoring the review report `.claude/features/<feature>/review.md`, the
interrupted run left partial work. Reconcile it before implementing anything:

1. Read `git diff`, `git diff --cached` and every untracked file in full.
2. Map each hunk and file to the requirement of an unfinished part of this block that it implements; usually that
   is the first unfinished one.
3. For that part, list the requirements the leftovers already meet, the ones still open, and the leftover changes
   that are wrong or outside its brief.
4. Changes that belong to a later unfinished part stay in the tree and become that part's leftovers when it comes
   up. Changes no unfinished part owns go to `git stash push -u -m "<branch>: unowned leftovers" -- <paths>`.
   Never discard or check out leftovers.

**Continue** each block at its first unfinished phase:

- A part isn't done: step 3, from that part.
- All parts are done, there is no PR: the test suite run at the end of step 3, then step 4.
- A PR exists, the review isn't done: step 5.
- The review is done, but the fixes aren't pushed: step 6.
- The fixes are pushed: only the cross-linking at the end of step 4 is left.

### 3. Implement

Work through the unfinished parts of every block as one plan. A part is ready when every part it comes after, in
any repository, is committed. Hand out the ready parts:

- In this run, the default when one part is ready, or only parts of one worktree that depend on each other and
  together stay small (about five files): call the Skill tool with `implement` for each in turn, naming the part's
  file as the brief and the worktree path.
- Delegated, when several parts are ready: start one `general-purpose` subagent per part with the Agent tool, all
  in one message, each told to read `~/.claude/skills/implement/SKILL.md` and follow it for that part's file in its
  worktree. Two parts of the same worktree run together only when their files don't overlap; otherwise the later one
  waits. Delegate a single part too when it is so large that reading its files would crowd out the context needed for
  step 6.

For a part with leftovers from step 2, add the list made there to the request: the work already in the tree, which
requirements are still open to finish, and which changes to correct; keep the rest instead of redoing it.

When a part finishes, read its diff in its worktree, run its verification yourself (checks marked `(manual)` go
to the report instead), and commit only its files as in [Commits](#commits). If the part asks for tests and
none were written, call the Skill tool with `test` first, naming the changed files and the worktree path. Then hand out
the parts it made ready, without waiting for the others still running.

When a block's last part is committed, run its test suite command and fix what its branch broke: a failing test that
is in the baseline file isn't the branch's, unless the branch changed that test or the code it covers. Without the
baseline file (a resumed run from before it existed), a failure is the branch's unless `git diff <base>..HEAD` touches
neither the test nor the code it covers. With `none`, the parts' verification stands in: say so in the report. The
review runs the linters and static checks, but not the tests. The block then goes on to step 4 while others may still
be implementing.

### 4. Open the PRs

For each block, in merge order: `git push -u origin <branch>` from its worktree, then call the Skill tool with `pr`,
naming the worktree path, `<base>`, and the URLs of the PRs already open for the spec's other blocks, as related. Wait
for its result. Once every block has its PR, call `pr` again for each earlier one, so that every PR names the others.

### 5. Review

For each block, call the Skill tool with `review`, naming the commit range `<base>..HEAD`, the worktree path to run in,
and the report path `<worktree>/.claude/features/<feature>/review.md`, and nothing else: the reviewer must judge the change
without this run's reasoning. Wait for its result.

### 6. Respond

Check every finding against the code, then fix it or contest it. Fix any finding that is right, whatever its
severity. Contest one that is unreasonable:

- the code, a test or the spec shows it is wrong;
- its fix would add what the parts don't ask for: an abstraction, defensive code or tests for cases that can't happen,
  or a change outside the brief;
- it asks for a style the project's own code doesn't follow.

A contested finding needs evidence (`path:line`, a test, the spec), not a preference. A `[MUST]` is contested only when
it is wrong, and a check this branch broke is always fixed.

Then run the block's final local checks: its test suite, and the repository's linters, static checks and format checks
(the ones the review ran, or those its Makefile, `pyproject.toml` or CI workflow define). Fix what the branch broke;
failures in the baseline or in files the branch doesn't touch are the base's, so leave them. Commit the fixes with the
PR number from step 4 (see [Commits](#commits)), then `git push` from the worktree. Don't request a second review.

The push of this step is the run's last verification. Don't watch, read or rerun CI after it; the run ends once every
block's fixes are pushed.

## Rules

- Edit files only inside the run's worktrees. Commit and push only their branches; never a base branch, never a
  force-push, never an amend or rebase of pushed commits. Never merge a PR.
- Never write to a repository or PR outside this run; list the PRs that should link to this run's in the report
  instead.
- Only the run commits, never its subagents. A commit holds one verified part or one block's review fixes, and only
  its own files. Leftovers reach a commit only as part of a verified part.
- Never write to Jira.
- If a part still fails after two attempts in this run, stop that block and every part that comes after it, finish
  the others, and report the state. Don't open a PR for a block with a failed part.
- When resuming, never pull, rebase or reset a branch; work from its current state.
- Leave the worktrees in place at the end.

### Commits

Commit by calling the Skill tool with `commit`, naming the worktree path, the files and the trailers. Its Conventional
Commits format leaves the subject to the change, so a resumed run reads its progress from the trailers
(`git log --format='%(trailers:key=Part,valueonly)' <range>`) and the subjects (`git log --format=%s <range>`):

- every commit: say that it may bypass hooks, so a lint or format complaint doesn't stop the run. `commit` bypasses
  only those, after trying to fix them; step 6's final checks still run the linters;
- a part: `Part: <id>`, and `Refs: <KEY>` when the part has a Jira key;
- review fixes: `Refs: <KEY>` with the key of the `Parts` section's `Jira` line, when it has one, and the subject
  `fix: PR#<no> review`, with `<no>` the number of the PR opened in step 4.

### Working directory

The session's worktree is the working directory of every command, so the commands of its block run as they are. The
permission rules match a command by how it starts, so how a command is written decides whether it goes through
unprompted.

- Never write `git -C <path> ...` or `VAR=... <command>`; a prefixed command matches no rule.
- Every command for a block outside the session's worktree is written as `cd <worktree> && <command>`. It never
  depends on an earlier `cd`: each command starts back in the session's worktree.
- Commit only through the `commit` skill, which writes the single `git commit -m` command the permission rules allow.
- Never delete files or directories with `rm` or `find -delete`; every form of it asks the user, whatever auto mode
  allows. Put scratch output in a new directory instead of clearing an old one; `pytest --basetemp <dir>` empties
  `<dir>` itself.
- A subagent or forked skill starts in the session's worktree and does not see this section. Give the worktree's
  absolute path in every Skill and Agent call (`implement`, `test`, `review`, `pr`, `commit`), name files by absolute
  path, and copy the rules of this section into the prompt.
- Check `git branch --show-current` before every commit and push; if it isn't that block's `<branch>`, stop and
  report.

### Without a user

Never ask. Where a question comes up, take the default and list it in the report:

- A detail the parts leave open: take the reading that changes least, and record it as an assumption.
- A leftover change that could belong to two parts: give it to the earlier one.
- Two ready parts whose files turn out to overlap: run them one after the other, in the order of `Parts`.
- A check that already fails on the base branch: leave it, report it, continue. Never disable, skip or loosen a check
  to get it green.
- A review finding that can be read two ways: contest it, and say which reading you rejected and why.
- A rejected push, or a pull that fails: stop that block and report the state. Never force.
- A denied command: stop and report it, as the global rules require.

## Report

For each block: the repository, the PR URL and its base, the worktree path with the `gwr <name>` that removes it, each
part with its file, its Jira URL when it has one, status and commit, the result of the final local checks (tests,
linters, static and format checks) with the base's failures left alone, the path of its review report (left uncommitted
in the worktree), and every review finding marked fixed (with the commit) or contested (with the reason). When a block was resumed, say from which phase, and how the leftovers were
handled: the part each was mapped to, and any stash.

Then say how the parts were handed out: which ran in this run, which in subagents, and which ran at the same time. End
with the assumptions made, every commit that bypassed a hook with what the hook reported, any ordering risk, the PRs
outside this run that should link to this run's, and what is left for the user to validate.
