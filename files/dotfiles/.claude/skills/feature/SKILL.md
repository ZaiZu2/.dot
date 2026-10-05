---
name: feature
description: '[hitl] Execute a feature end to end: plan, Jira tickets, implementation, PR and independent review.'
disable-model-invocation: true
---

# Feature

Take a feature from its input to a reviewed pull request and hand it back for validation. A good result is a PR that
does what the input asked, tickets that explain the work on their own, and a handback that says what was done, what the
reviewer found and what was done about each finding.

The user is involved only at the start: questions while investigating and planning, then one approval at `Confirm`.
After that, run to the end without asking.

## Target

One of, as the request names it:

- a spec file written by `/spec`: the path given, or the only file in `<repo root>/.claude/spec/`;
- a skill: read `~/.claude/skills/<name>/SKILL.md` and take its instructions as the task, without running it;
- a task described in the request.

Tickets are created unless the request says to skip them.

Stop with the reason if nothing is given, if several specs match and none is named, if the worktree path or branch of
step 5 already exists, or if tickets are wanted and no `mcp__atlassian__*` tools are available (tell the user to run
`dot claude mcp`, then `/mcp` to sign in).

## Actions

### 1. Investigate

Read the input and the code it affects, enough to plan against real files and symbols.

Ask about everything the input leaves unclear (scope, behavior, edge cases, how it is verified) now, since nothing can
be asked after `Confirm`. Use `AskUserQuestion`, with your recommended option first and the code evidence behind it.
Don't ask what the code or the input already answers; state the assumption instead. If the input needs a design
interview rather than a few questions, stop and tell the user to run `/spec`.

### 2. Plan

Split the work into chunks, each with its outcome, the files it touches, the chunks it depends on and how it is
verified. Then pick the smallest ticket shape that fits:

- **Single Task**: the default, right for almost every feature, even one that takes several commits.
- **Task with Sub-tasks**: only when the work splits into characteristic parts (schema, API, CLI). One Sub-task per
  part, never per step or per file.
- **Story with Tasks**: only for a fully fledged new feature with a longer development pipeline. Check the project's
  issue types and hierarchy with the MCP server first; if a Task can't be the child of a Story, link them instead.

When two shapes fit, take the smaller one.

For each leaf ticket, decide where it is implemented:

- **Main session**, the default: a single leaf ticket, or tickets that depend on each other and together stay small
  (about five files, in code already read in step 1).
- **Delegated**: several independent leaf tickets, or one so large that reading its files would crowd out the context
  needed for step 8.

Ask any question the planning raised before moving on. A brief may reach `Confirm` only when it can be implemented
without a further question.

### 3. Confirm

Read `${CLAUDE_SKILL_DIR}/../ticket/SKILL.md`. Its rules, project tags, labels and defaults apply to the tickets; its
description format doesn't, since these follow [Ticket brief](#ticket-brief).

Show the ticket tree with the full text of every ticket, where each leaf is implemented, the branch name, and any shape
or sizing choice that was close. Wait for approval, and apply requested changes before continuing.

### 4. Create tickets

Create the parent first, then its children, exactly as approved. Keep the key of each.

### 5. Create the worktree

All work happens in a new worktree, never in the main checkout:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD   # origin/master: <base> is the part after `origin/`
git worktree list                                   # first line is <main>; shows where <base> is checked out
git pull --ff-only                                  # in the worktree that has <base> checked out
git worktree add <main>/<branch with / replaced by -> -b <branch> <base>
cd <main>/<branch with / replaced by ->
```

This is what the `gwa` alias does. If no worktree has `<base>` checked out, run `git fetch origin <base>:<base>` in
place of the pull. If the pull fails, stop and report it; don't cut the branch from a stale or remote base instead.

The branch is `<PARENT-KEY>-<slug>`, or `feature/<slug>` without tickets. Run `uv sync --quiet` in the worktree if it
has a `pyproject.toml`.

### 6. Implement

Work through the leaf tickets in dependency order, naming the ticket key and the worktree path each time (without
tickets, the brief itself):

- Main session: call the Skill tool with `implement`.
- Delegated: start a `general-purpose` subagent with the Agent tool, told to read `~/.claude/skills/implement/SKILL.md`
  and follow it for that ticket in that worktree. Start several together only when their file sets are disjoint and none
  depends on another.

After each ticket, read the resulting diff, run its verification yourself, and commit it as `<KEY>: <summary>`, using
the Sub-task's key where there is one. If the brief asks for tests and none were written, call the Skill tool with
`test`, naming the changed files and the worktree path.

After the last ticket, run the project's whole test suite and fix what this branch broke; the review runs the linters
and static checks, but not the tests.

### 7. Review

Call the Skill tool with `review`, naming the commit range `<base>..HEAD`, the worktree path to run in, and nothing
else: the reviewer must judge the change without this run's reasoning. Wait for its result.

### 8. Respond

Check every finding against the code, then fix it or contest it:

- `[MUST]`: fix, unless the code shows the finding is wrong. A check this branch broke is always fixed.
- `[SHOULD]` and `[NIT]`: fix when correct and cheap, otherwise contest.
- A contested finding needs evidence (`path:line`, a test, the spec), not a preference.

Rerun the test suite and the checks the review reported, then commit the fixes. Don't request a second review.

### 9. Open the PR

`git push -u origin <branch>`, call the Skill tool with `pr`, naming the worktree path, and wait for its result.

### 10. Fix CI

Wait for the PR's checks to finish with `gh pr checks --watch`, run in the background so a long pipeline doesn't time
out. There is no limit on how long they take to finish. Only if no check has even started a minute after the push does
the repo have no CI: skip this step and say so in the report.

For each failed check, read its log with `gh run view <run id> --log-failed` and fix the cause in the worktree. Rerun
locally what the fix touches, commit, push, and wait for the checks again. At most two rounds of fixes.

Call the Skill tool with `pr` again, naming the worktree path, if the fixes made the description inaccurate.

## Rules

- Edit files only inside the worktree of step 5. Commit and push only its branch; never the default branch, never a
  force-push, never an amend or rebase of pushed commits. Never merge the PR.
- Only this skill commits. A commit holds one verified ticket, one round of review fixes or one round of CI fixes.
- Write to Jira only in step 4, and only what was approved in step 3.
- If a ticket still fails after two attempts, stop and report the state. Don't open a PR for a feature with a failed
  ticket.
- Leave the worktree in place at the end.

### Working directory

The session starts in the main checkout, and the permission rules match a command by how it starts, so where and how
a command runs decides whether it goes through unprompted.

- Run each command of step 5 on its own. Once the worktree exists, stay in it: the shell keeps its directory between
  commands, so after the `cd` every later command runs there.
- Never write `cd <path> && <command>`, `git -C <path> ...` or `VAR=... <command>`; a compound or prefixed command
  matches no rule. To run something elsewhere, `cd` there as a command of its own, then `cd` back the same way.
- A subagent or forked skill starts in the main checkout, not in the worktree. Give the worktree's absolute path in
  every Skill and Agent call (`implement`, `test`, `review`, `pr`), and name files by absolute path.
- Check `git branch --show-current` before the first commit and before each push; if it isn't the feature branch,
  stop and report.

### After Confirm

Never ask. Where a question comes up, take the default and list it in the report:

- A detail the brief leaves open: take the reading that changes least, and record it as an assumption.
- A check that already fails on the default branch, locally or in CI: leave it, report it, continue.
- A CI check that fails for a reason outside the change (runner, network, a flaky test): rerun it once with
  `gh run rerun <run id> --failed`, then report it and continue.
- CI still failing after two rounds of fixes: stop fixing and report the failing checks with their logs' cause. Never
  disable, skip or loosen a check to get it green.
- A review finding that can be read two ways: contest it, and say which reading you rejected and why.
- A rejected push, or a pull that fails: stop and report the state. Never force.
- Ticket creation that fails part-way: stop and report which tickets exist. Don't retry into duplicates.
- A denied command: stop and report it, as the global rules require.

## Ticket brief

Every leaf ticket (a lone Task, a Sub-task, a Task under a Story) carries all that someone with no other context needs
to implement it. Read `${CLAUDE_SKILL_DIR}/../spec/brief.md` and write each leaf's description in that layout, following
its rules. `Verification` is required, and the tickets a leaf depends on go under `Notes`.

A parent holds only Summary, Scope and the list of its children. When the input is a spec, it is already in this layout:
cut each leaf from its sections instead of rewording them, and give the spec's path in the parent.

## Report

Give the PR URL, the worktree path with the `gwr <name>` that removes it, and the tickets with their URLs. Then list
each ticket's status and commit, the result of the final local checks, the state of every CI check with the fixes made
for it, every review finding marked fixed (with the commit) or contested (with the reason), the assumptions made, and
what is left for the user to validate.
