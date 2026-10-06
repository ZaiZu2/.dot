---
name: feature
description:
    '[auto] Implement a scoped spec unattended in each of its repositories, or resume a stopped run: code, review, PRs
    and CI fixes.'
context: fork
agent: feature-runner
disable-model-invocation: true
allowed-tools:
    - Bash(git pull --ff-only*)
    - Bash(git commit -m *)
    - Bash(git push)
    - Bash(git push -u origin *)
    - Bash(git stash push *)
    - Bash(sleep *)
---

# Feature

Turn the tickets of a spec that `/scope` has split into reviewed, open pull requests, one per repository. The run
distributes the tickets: it implements a ticket itself, or hands independent tickets to `implement` subagents that work
at the same time, each in its repository's worktree. A good result is PRs that do what the tickets ask, and a handback
that says what was done, what the review found and what was done about each finding.

This runs as a forked `feature-runner` agent, so no one can be asked during the run: resolve every open question with
the defaults under [Without a user](#without-a-user), and list each in the report.

## Target

The spec file the request names. The run covers every block of its `Tickets` section, or only the repositories the
request names. The request may add "resume", to continue a run that stopped part-way.

The `Tickets` section, written by `/scope`, holds everything the run needs; use its values as written and don't work
any of them out again. It has one block per repository, in the order the PRs merge. Each block gives `Checkout`
(`<main>` below), `Base` (`<base>`), `Branch` (`<branch>`), `Worktree` (`<worktree>`), `Test suite` and `Leaves`, each
leaf with the leaves it comes after and the files it changes. The tickets are the brief; the rest of the spec is
background.

Stop with the reason if no spec is named, if it has no `Tickets` section or a block lacks one of these values (tell the
user to run `/scope`), if a named repository has no block, or if a ticket can't be read. Then, for each block of the
run:

- Without "resume": stop if `<branch>` or `<worktree>` already exists, and tell the user to rerun with "resume".
- With "resume": a block whose `<branch>` exists resumes; one whose branch doesn't starts fresh.
- A leaf that comes after a leaf of a block outside this run: stop unless that leaf is done on its block's branch (a
  subject starting with `<KEY>:` in `git log --format=%s <base>..<branch>`, run in its `<main>`).
- A block outside this run that merges before one inside it, and has no open PR (`gh pr list --head <branch>` in its
  `<main>` finds none): continue, and report it as an ordering risk.

## Actions

### 1. Create the worktrees

For each block that doesn't resume. All work happens in new worktrees, never in a main checkout:

```bash
cd <main>
git worktree list                                   # shows where <base> is checked out, if anywhere
git pull --ff-only                                  # in the worktree that has <base> checked out
git worktree add <worktree> -b <branch> <base>
cd <worktree>
```

This is what the `gwa` alias does. If no worktree has `<base>` checked out, run `git fetch origin <base>:<base>` in
place of the pull. If the pull fails, stop and report it; don't cut the branch from a stale or remote base instead.
Before `git worktree add`, `git rev-parse <base>` must equal `git rev-parse origin/<base>`: if the local `<base>` has
commits that aren't pushed, they would land in the PR, so stop and report.

Run `uv sync --quiet` in the worktree if it has a `pyproject.toml`.

Then take the baseline: run the test suite command in the untouched worktree, and write the ids of the tests that fail
to the file `git rev-parse --git-path feature-baseline` names (it is never committed). These failures belong to the
base, not to this branch. With `none`, skip this.

### 2. Resume

For each block that resumes. Rebuild its branch's state from git and GitHub, then continue it from its first
unfinished phase.

**Worktree.** If `<worktree>` exists, `cd` into it. If only the branch exists, `cd <main>`, then
`git worktree add <worktree> <branch>`, then `cd` into it. Run `uv sync --quiet` if there is a `pyproject.toml`.

**Progress**, from `git log --format=%s <base>..HEAD` and the subjects of [Commits](#commits):

- A leaf ticket is done when a commit subject starts with `<KEY>:`.
- The review is done when an `address review` commit exists, or a PR exists.
- The CI rounds used are the number of `fix CI` commits.
- A PR exists when `gh pr view --json url,state` succeeds. If it is closed or merged, stop that block and report.
- The branch is pushed when `git status -sb` shows an upstream and nothing ahead of it.

**Leftovers.** If `git status --porcelain` isn't empty, the interrupted run left partial work. Reconcile it before
implementing anything:

1. Read `git diff`, `git diff --cached` and every untracked file in full.
2. Map each hunk and file to the requirement of an unfinished ticket of this block that it implements; usually that
   is the first unfinished one.
3. For that ticket, list the requirements the leftovers already meet, the ones still open, and the leftover changes
   that are wrong or outside its brief.
4. Changes that belong to a later unfinished ticket stay in the tree and become that ticket's leftovers when it comes
   up. Changes no unfinished ticket owns go to `git stash push -u -m "<PARENT-KEY>: unowned leftovers" -- <paths>`.
   Never discard or check out leftovers.

**Continue** each block at its first unfinished phase:

- A ticket isn't done: step 3, from that ticket.
- All tickets are done, the review isn't: the test suite run at the end of step 3, then step 4.
- The review is done, but the branch isn't pushed or has no PR: step 6.
- A PR exists: step 7, counting the CI rounds already used against its limit.

### 3. Implement

Work through the unfinished leaves of every block as one plan. A leaf is ready when every leaf it comes after, in any
repository, is committed. Hand out the ready leaves:

- In this run, the default when one leaf is ready, or only leaves of one worktree that depend on each other and
  together stay small (about five files): call the Skill tool with `implement` for each in turn, naming the key and the
  worktree path.
- Delegated, when several leaves are ready: start one `general-purpose` subagent per leaf with the Agent tool, all in
  one message, each told to read `~/.claude/skills/implement/SKILL.md` and follow it for that leaf in its worktree. Two
  leaves of the same worktree run together only when their files don't overlap; otherwise the later one waits.
  Delegate a single leaf too when it is so large that reading its files would crowd out the context needed for step 5.

For a leaf marked `(brief: spec)`, name the spec's path as the brief instead of the key, and the repository it is for;
the key is only for the commit subject.

For a ticket with leftovers from step 2, add the list made there to the request: the work already in the tree, which
requirements are still open to finish, and which changes to correct; keep the rest instead of redoing it.

When a leaf finishes, `cd` to its worktree, read its diff, run its verification yourself (checks marked `(manual)` go
to the report instead), stage only its files with `git add <paths>`, and commit it. If the ticket asks for tests and
none were written, call the Skill tool with `test` first, naming the changed files and the worktree path. Then hand out
the leaves it made ready, without waiting for the others still running.

When a block's last leaf is committed, run its test suite command and fix what its branch broke: a failing test that is
in the baseline file isn't the branch's, unless the branch changed that test or the code it covers. Without the
baseline file (a resumed run from before it existed), a failure is the branch's unless `git diff <base>..HEAD` touches
neither the test nor the code it covers. With `none`, the tickets' verification stands in: say so in the report. The
review runs the linters and static checks, but not the tests. The block then goes on to step 4 while others may still
be implementing.

### 4. Review

For each block, call the Skill tool with `review`, naming the commit range `<base>..HEAD`, the worktree path to run in,
and nothing else: the reviewer must judge the change without this run's reasoning. Wait for its result.

### 5. Respond

Check every finding against the code, then fix it or contest it:

- `[MUST]`: fix, unless the code shows the finding is wrong. A check this branch broke is always fixed.
- `[SHOULD]` and `[NIT]`: fix when correct and cheap, otherwise contest.
- A contested finding needs evidence (`path:line`, a test, the spec), not a preference.

Rerun the block's test suite and the checks the review reported, then commit the fixes. Don't request a second review.

### 6. Open the PRs

For each block, in merge order: `git push -u origin <branch>` from its worktree, then call the Skill tool with `pr`,
naming the worktree path, `<base>`, and the URLs of the PRs already open for the spec's other blocks, as related. Wait
for its result. Once every block has its PR, call `pr` again for each earlier one, so that every PR names the others.

### 7. Fix CI

Wait for the checks of every PR to finish with `gh pr checks --watch`, one per PR, run in the background so a long
pipeline doesn't time out. There is no limit on how long they take to finish. Only if no check of a PR has even started
a minute after its push does that repository have no CI: skip this step for it and say so in the report.

For each failed check, read its log with `gh run view <run id> --log-failed` and fix the cause in that worktree. Rerun
locally what the fix touches, commit, push, and wait for the checks again. At most two rounds of fixes per PR.

Call the Skill tool with `pr` again, naming the worktree path and `<base>`, if the fixes made the description
inaccurate.

## Rules

- Edit files only inside the run's worktrees. Commit and push only their branches; never a base branch, never a
  force-push, never an amend or rebase of pushed commits. Never merge a PR.
- Never write to a repository or PR outside this run; list the PRs that should link to this run's in the report
  instead.
- Only this skill commits. A commit holds one verified ticket, one block's round of review fixes or one round of CI
  fixes, and only its own files. Leftovers reach a commit only as part of a verified ticket.
- Never write to Jira.
- If a ticket still fails after two attempts in this run, stop that block and every leaf that comes after it, finish
  the others, and report the state. Don't open a PR for a block with a failed ticket.
- When resuming, never pull, rebase or reset a branch; work from its current state.
- Leave the worktrees in place at the end.

### Commits

Each kind of commit has a fixed subject, so a resumed run can read its progress back:

- a ticket: `<KEY>: <summary>`, with the Sub-task's key where there is one;
- review fixes: `<PARENT-KEY>: address review`;
- CI fixes: `<PARENT-KEY>: fix CI (round <n>)`.

### Working directory

The run starts in the session's working directory, which may be another repository's checkout, and the permission
rules match a command by how it starts, so where and how a command runs decides whether it goes through unprompted.

- Run each command of step 1 or 2 on its own. Before any command for a block, `cd` to its worktree as a command of its
  own; the shell keeps its directory between commands.
- Never write `cd <path> && <command>`, `git -C <path> ...` or `VAR=... <command>`; a compound or prefixed command
  matches no rule.
- Commit with a single `git commit -m "<subject>"`, never a heredoc or `$(...)`.
- A subagent or forked skill starts in the session's working directory, not in a worktree. Give the worktree's absolute
  path in every Skill and Agent call (`implement`, `test`, `review`, `pr`), and name files by absolute path.
- Check `git branch --show-current` before every commit and push; if it isn't that block's `<branch>`, stop and
  report.

### Without a user

Never ask. Where a question comes up, take the default and list it in the report:

- A detail the tickets leave open: take the reading that changes least, and record it as an assumption.
- A leftover change that could belong to two tickets: give it to the earlier one.
- Two ready leaves whose files turn out to overlap: run them one after the other, in the order of `Leaves`.
- A check that already fails on the base branch, locally or in CI: leave it, report it, continue.
- A CI check that fails for a reason outside the change (runner, network, a flaky test): rerun it once with
  `gh run rerun <run id> --failed`, then report it and continue.
- CI still failing after two rounds of fixes: stop fixing and report the failing checks with their logs' cause. Never
  disable, skip or loosen a check to get it green.
- A review finding that can be read two ways: contest it, and say which reading you rejected and why.
- A rejected push, or a pull that fails: stop that block and report the state. Never force.
- A denied command: stop and report it, as the global rules require.

## Report

For each block: the repository, the PR URL and its base, the worktree path with the `gwr <name>` that removes it, each
ticket with its URL, status and commit, the result of the final local checks with the baseline failures left alone,
the state of every CI check with the fixes made for it, and every review finding marked fixed (with the commit) or
contested (with the reason). When a block was resumed, say from which phase, and how the leftovers were handled: the
ticket each was mapped to, and any stash.

Then say how the leaves were handed out: which ran in this run, which in subagents, and which ran at the same time. End
with the assumptions made, any ordering risk, the PRs outside this run that should link to this run's, and what is left
for the user to validate.
