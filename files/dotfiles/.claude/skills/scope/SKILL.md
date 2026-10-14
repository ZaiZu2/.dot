---
name: scope
description:
    '[hitl] Split a spec into self-contained part files (briefs), record them in the spec and create the worktree
    `/feature` runs in; on request, mirror them as Jira issues.'
disable-model-invocation: true
allowed-tools:
    - Bash(gh auth status*)
    - Bash(git pull --ff-only*)
    - Bash(git rev-parse *)
    - mcp__atlassian__atlassianUserInfo
    - mcp__atlassian__createJiraIssue
    - mcp__atlassian__editJiraIssue
    - mcp__atlassian__executeWrite
---

# Scope

Turn a finished spec into parts, files that can each be implemented on their own, make the spec the single input of
`/feature`, and create the worktree its run starts in. A good result is a spec that lists its parts, a worktree ready
for the run, and nothing left to fail in an unattended run that could be checked now, while the user is here.

The part files carry all the context `/feature` and `implement` get; Jira is an optional copy for people. Never edit
the spec's content beyond its `Parts` section, and never implement or commit.

## Target

A spec file written by `/spec`, `<repo root>/.claude/spec/<feature>/spec.md`: the path given, the `spec.md` of the
feature directory given, or the only `spec.md` under `<repo root>/.claude/spec/*/`. Its parts go into the same
directory, beside it.

The spec's `Repositories` section lists each repository with its base branch and test suite command. Without the
section, the work is in the repository holding the spec.

Every repository needs an explicit base branch: the one the request names, else the one in `Repositories`. With
neither, take the repository's default branch
(`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`) only when it is the obvious base: the checkout is on
it, and nothing in the spec or the request points to another branch. Otherwise ask with `AskUserQuestion`, the default
branch first. Never take the base from the branch that happens to be checked out.

Jira is used only when the request asks for Jira issues or names one, or `Repositories` has a `Jira` line; see
[Jira](#jira). Otherwise skip everything marked "with Jira", and don't ask about it.

Stop with the reason if no spec is found (tell the user to run `/spec`), or if several match and none is named. A spec
that already has a `Parts` section, or part files beside it, is a [rerun](#rerun).

## Actions

### 1. Read

Read the spec and the code it names, enough to size the work against real files and symbols.

If the spec leaves something open that an implementer would have to ask about, stop and list the gaps, and tell the user
to update the spec with `/spec`. Don't fill them in here.

### 2. Plan

Split the spec into parts, each with its outcome, the files it touches, the parts it comes after and how it is
verified. A part never spans repositories: work in two repositories is at least two parts. Split one repository's
work only along its natural seams (schema, API, CLI), never per step or per file; a single part is right for most
features, even one that takes several commits.

Whether parts run at the same time is decided here: a part comes after another only when it needs that part's
code to be written or tested, as the spec's `Parallel` and `Sequential` lines and the code say. `/feature` builds the
rest at the same time, so two parts that can run together must not change the same file. Ask about a split only when
the spec and the code don't settle it, using `AskUserQuestion` with your recommended option first.

Number the parts `01`, `02`, ... across the whole spec, in an order that respects their dependencies and the merge
order of `Repositories`.

Pick a short, kebab-case slug for the branch and worktree names: 2-3 words that let a human recognize the change at a
glance (e.g. `cache-ttl-fix`), not the spec's file name, which can be longer and more descriptive. One slug per
repository block; reuse it everywhere `<slug>` appears below.

With Jira, also plan the issues, as [Jira](#jira) says.

### 3. Preflight

If the spec covers more than one repository, this run and the `/feature` run both work in checkouts outside the
session's directory. Before any check, name each checkout other than the session's (`git rev-parse --show-toplevel`),
ask the user to run `/add-dir <checkout>` for it, and wait until they say it is done. Never edit a settings file
yourself.

Check what would otherwise fail in the `/feature` run. Stop with the reason on any failure:

- `gh auth status` succeeds.
- With Jira: `mcp__atlassian__*` tools are available and `atlassianUserInfo` succeeds; otherwise tell the user to run
  `dot claude mcp`, then `/mcp` to sign in. An existing issue to update or extend is assigned to the signed-in account;
  otherwise stop and name the assignee.

Then in each repository, after a `cd` to its path as a command of its own (if `git rev-parse --show-toplevel` then
doesn't print that path, the directory wasn't added: ask again):

- `gh repo view --json viewerPermission -q .viewerPermission` is `WRITE`, `MAINTAIN` or `ADMIN`.
- `git fetch origin` succeeds, the base exists on the remote (`git ls-remote --exit-code --heads origin <base>`), and no
  branch matches `git branch -a --list '*<slug>'`, using the slug picked in step 2.
- The local base has no unpushed commits (`git rev-list --count origin/<base>..<base>` is `0`, when it exists locally);
  `/feature` stops on them, so tell the user to push.
- No directory of `<checkout>` is named `<slug>` or ends in `-<slug>`: the worktree goes to `<checkout>/<branch>`.
- The test suite command is known: from `Repositories`, else the project's `CLAUDE.md`, else its CI workflow, else its
  `Makefile`. With none, record `none`; the parts' `Verification` stands in, even when it is only `(manual)`. Say in
  step 4 which parts the run can't check itself; don't stop for it.

`cd` back to the spec's repository at the end.

### 4. Confirm

Show the full text of every part file with its path, which parts run at the same time and which wait for another,
the `Parts` section that will be added to the spec, each repository with its base (saying where it came from: the
request, the spec, or the default branch), test suite command, and the branch and worktree that will be created, and
any split or sizing choice that was close.

With Jira, also show the issue tree with the parts each issue covers, the full text of every new issue, the current
and the new text of every field an update changes, and the parent issue the spec file will be attached to.

Wait for approval, and apply requested changes before continuing.

### 5. Write the parts

Write each part file exactly as approved, in the layout of `${CLAUDE_SKILL_DIR}/../spec/brief.md` and under the name
it gives. Cut the text from the spec's sections instead of rewording them: a part carries all that someone with no
other context needs to implement it.

### 6. Write the issues

With Jira only. Update existing issues first, then create the new ones, parent before children, exactly as approved.
Keep the key of each. If a write fails part-way, stop and report what was written; don't retry into duplicates.

### 7. Update the spec

Add the `Parts` section of `${CLAUDE_SKILL_DIR}/../spec/brief.md` to the spec, with one block per repository holding
its checkout, base, branch, worktree, test suite and parts, each part with its id, its file, the parts it comes
after, the files it changes and, with Jira, the key of the issue that covers it. Write every value out in full
(absolute paths, the real key), so `/feature` reads it instead of working anything out.

### 8. Attach the spec

With Jira only. Attach the now-finished spec file to the parent issue, as a copy for anyone working from Jira. Use
`mcp__atlassian__executeWrite` with operation `uploadAttachmentToJiraIssue`: call it with `filePath` set to the spec's
path to get `uploadCommand`, run that command, then call it again with the returned `fileId` to attach the file to the
parent's key. If the upload fails, report it; it doesn't undo the earlier steps.

### 9. Create the worktrees

For each repository block, with the values of its `Parts` block, after a `cd` to its checkout as a command of its own:

```bash
git worktree list                                   # shows where <base> is checked out, if anywhere
git pull --ff-only                                  # in the worktree that has <base> checked out
git rev-parse <base> origin/<base>                  # must print the same commit twice
git worktree add <worktree> -b <branch> <base>
```

This is what the `gwa` alias does. If no worktree has `<base>` checked out, run `git fetch origin <base>:<base>` in
place of the pull. If the pull fails, or the local `<base>` differs from `origin/<base>`, stop and report it; don't
cut the branch from a stale or remote base instead. `cd` back to the spec's repository at the end.

## Rules

- The part files are the source `/feature` builds from; Jira is never read back. A later change to a brief goes into
  its file.
- Write to Jira only in steps 6 and 8, and only what was approved in step 4. Never change an existing issue's status,
  assignee or fields other than those its mode allows.

## Rerun

The spec changed after it was split, and the parts must follow it. Read the existing part files and the `Parts` section,
plan again from the current spec, and change only what the spec's change requires:

- A part that stays keeps its number, file, branch, worktree and Jira key. A new part takes the next free number; a
  removed part's number is never reused.
- In step 3, a block's own branch and worktree may exist; step 9 leaves such a worktree as it is, and creates only
  those of new blocks. In each such checkout, read which parts are already built
  (`git log --format='%(trailers:key=Part,valueonly)' <base>..<branch>`).
- In step 4, show each changed part file as a diff, the parts added and removed, and the changed lines of `Parts`. Name
  every changed or removed part that is already built: `/feature` won't build it again, so the user decides what to do
  with that work.
- In steps 5 and 7, rewrite only what was approved. Remove the file of a removed part with the user's approval.
- With Jira, propose the matching issue updates in step 4 and write them in step 6. Never close or delete an issue;
  list the ones a removed part leaves without work.

If nothing differs, say so and stop.

## Jira

Read `${CLAUDE_SKILL_DIR}/../ticket/SKILL.md`. Its rules, project tags, labels and defaults apply to the issues; its
description format doesn't.

Propose the issues from the plan and from what the request says about them (the feature's issue, a project, a shape).
Every part is covered by exactly one issue, and an issue may cover several parts. Pick the smallest shape that
fits:

- **Single Task**: the default, covering every part.
- **Task with Sub-tasks**: only when the parts are worth tracking apart. One Sub-task per
  part, or per group of parts.
- **Story with Tasks**: only for a fully fledged new feature with a longer development pipeline. Check the project's
  issue types and hierarchy with the MCP server first; if a Task can't be the child of a Story, link them instead.

An issue that covers one part takes that part file's text as its description. An issue that covers several, or a
parent, holds only Summary, Scope, the spec's path and the list of its parts or children. The parent is the issue
holding the context for the whole change: the Story, the parent Task, or the single Task.

An existing issue comes from the request, else from the spec's `Jira` line, with what to do with it; the request may
also narrow it (e.g. "keep the description, only add sub-tasks"). If neither says what to do, ask with
`AskUserQuestion`, recommending the mode that fits the issue's current type, description and children:

- **Implement under it**: no field writes for it in step 6 (step 8 still attaches the spec to it). It is the parent,
  and covers every part.
- **Update it**: rewrite its description (and its summary, if the request says so) as above. It covers every part,
  or is the parent when the plan gives it children, which are created under it.
- **Extend it**: keep it as the parent and create the planned children under it: Sub-tasks under a Task, Tasks under a
  Story. Don't change its own fields. A Sub-task can't have children: stop and say so.

Its project, tag and labels apply to the new children. If its project differs from the one the spec implies, keep its
project.

## Report

Give the part files with their ids (on a rerun: which were changed, added, removed or left alone), the spec's path and,
with Jira, the issues with their keys and URLs, marked created, updated or unchanged, and whether the spec attached to
the parent, with the reason when it didn't.

Then say how to start the run: open a Claude session in the first block's worktree (`cd <worktree>`, then `claude`,
with one `--add-dir <worktree>` for each further block) and type `/feature <absolute spec path>` there. Starting it
again the same way continues a run that stopped part-way.
