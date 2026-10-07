---
name: scope
description:
    '[hitl] Split a spec into self-contained Jira tickets, record their keys in the spec and check it is ready for
    `/feature`.'
disable-model-invocation: true
allowed-tools:
    - Bash(gh auth status*)
    - mcp__atlassian__atlassianUserInfo
    - mcp__atlassian__createJiraIssue
    - mcp__atlassian__editJiraIssue
    - mcp__atlassian__executeWrite
---

# Scope

Turn a finished spec into Jira tickets that can each be implemented on their own, and make the spec the single input of
`/feature`. A good result is a spec that lists its tickets, and nothing left to fail in an unattended run that could be
checked now, while the user is here.

Never edit the spec's content beyond its `Tickets` section, and never implement, branch or commit.

## Target

A spec file written by `/spec`: the path given, or the only file in `<repo root>/.claude/spec/`.

The spec's `Repositories` section lists each repository with its base branch and test suite command, and may name an
existing Jira issue with what to do with it (see [Existing issue](#existing-issue)). Without the section, the work is in
the repository holding the spec, against its default branch. The request may name the issue instead, or override the
spec's; if neither says what to do with it, ask with `AskUserQuestion`, recommending the mode that fits the issue's
current type, description and children.

Stop with the reason if no spec is found (tell the user to run `/spec`), if several match and none is named, or if the
spec already has a `Tickets` section (report its keys, so no duplicates are created).

## Actions

### 1. Read

Read the spec and the code it names, enough to size the work against real files and symbols.

If the spec leaves something open that an implementer would have to ask about, stop and list the gaps, and tell the user
to update the spec with `/spec`. Don't fill them in here.

### 2. Plan

Split the spec into chunks, each with its outcome, the files it touches, the chunks it depends on and how it is
verified. A chunk never spans repositories: work in two repositories is at least two leaves. A chunk depends on
another only when the spec's `Parallel` and `Sequential` lines say it needs that chunk's code; `/feature` builds the
rest at the same time. Then pick the smallest ticket shape that fits:

- **Single Task**: the default, right for almost every feature, even one that takes several commits.
- **Task with Sub-tasks**: only when the work splits into characteristic parts (schema, API, CLI). One Sub-task per
  part, never per step or per file.
- **Story with Tasks**: only for a fully fledged new feature with a longer development pipeline. Check the project's
  issue types and hierarchy with the MCP server first; if a Task can't be the child of a Story, link them instead.

When two shapes fit, take the smaller one. Ask about a split or shape only when the spec and the code don't settle it,
using `AskUserQuestion` with your recommended option first. With an existing issue, its mode fixes part of the shape.

### 3. Preflight

Check what would otherwise fail in the `/feature` run. Stop with the reason on any failure:

- `mcp__atlassian__*` tools are available and `atlassianUserInfo` succeeds; otherwise tell the user to run
  `dot claude mcp`, then `/mcp` to sign in.
- `gh auth status` succeeds.
- An existing issue to update or extend is assigned to the signed-in account; otherwise stop and name the assignee.

Then in each repository, after a `cd` to its path as a command of its own:

- `gh repo view --json viewerPermission -q .viewerPermission` is `WRITE`, `MAINTAIN` or `ADMIN`.
- `git fetch origin` succeeds, the base exists on the remote (`git ls-remote --exit-code --heads origin <base>`), and no
  branch matches `git branch -a --list '*-<slug>'`, where `<slug>` is the spec's file name without `.md`.
- The local base has no unpushed commits (`git rev-list --count origin/<base>..<base>` is `0`, when it exists locally);
  `/feature` stops on them, so tell the user to push.
- The worktree path `<checkout>/<PARENT-KEY>-<slug>` doesn't exist. Before the tickets exist, check that no directory of
  `<checkout>` ends in `-<slug>`.
- The test suite command is known: from `Repositories`, else the project's `CLAUDE.md`, else its CI workflow, else its
  `Makefile`. With none, record `none`; the leaves' `Verification` stands in, even when it is only `(manual)`. Say in
  step 4 which leaves the run can't check itself; don't stop for it.

`cd` back to the spec's repository at the end.

Last, the edit access of each `/feature` run. A run edits only under its `Checkout`, and it can do that unprompted only
when the checkout is inside the session's working directory (`git rev-parse --show-toplevel` here) or listed under
`permissions.additionalDirectories` in `~/.claude/settings.json`, `.claude/settings.json` or
`.claude/settings.local.json` of this repository (read each with `jq -r '.permissions.additionalDirectories[]?'`; expand
a leading `~`). For every checkout that is neither, ask with `AskUserQuestion`:

- **Add the directory** (recommended): the user adds `"additionalDirectories": ["<checkout>"]` under `permissions` in
  one of those files, or runs `/add-dir <checkout>` for this session only. Check again once they say it's done.
- **Run that repository on its own**: the user will start `/feature <spec> <repository>` for it from a session opened
  in the checkout, and the main run without it. Record it, and name it in the report.

Never edit a settings file yourself.

### 4. Confirm

Read `${CLAUDE_SKILL_DIR}/../ticket/SKILL.md`. Its rules, project tags, labels and defaults apply to the tickets; its
description format doesn't, since these follow [Ticket brief](#ticket-brief).

Show the ticket tree with the full text of every new ticket, the current and the new text of every field an update
changes, the `Tickets` section that will be added to the spec, each repository with its base and test suite command,
the parent ticket the spec file will be attached to, and any shape or sizing choice that was close. Wait for approval,
and apply requested changes before continuing.

### 5. Write tickets

Update existing issues first, then create the new ones, parent before children, exactly as approved. Keep the key of
each. If a write fails part-way, stop and report what was written; don't retry into duplicates.

### 6. Update the spec

Add the `Tickets` section of `${CLAUDE_SKILL_DIR}/../spec/brief.md` to the spec, with the keys of step 5 and one block
per repository holding its checkout, base, branch, worktree, test suite and leaves, each leaf with the leaves it comes
after and the files it changes. Write every value out in full (absolute paths, the real key), so `/feature` reads it
instead of working anything out.

### 7. Attach the spec

Attach the now-finished spec file (with its new `Tickets` section) to the parent ticket — the one holding the context
for the whole change: the Story, the parent Task, or the single leaf when there is no split; the existing issue itself
under [Implement under it](#existing-issue) or [Extend it](#existing-issue). The spec stays the single file `/feature`
reads from the repository; the Jira attachment is a synced copy for anyone working from the ticket.

Use `mcp__atlassian__executeWrite` with operation `uploadAttachmentToJiraIssue`: call it with `filePath` set to the
spec's path to get `uploadCommand`, run that command, then call it again with the returned `fileId` to attach the file
to the parent's key. If the upload fails, report it; it doesn't undo steps 5 or 6.

## Rules

- Write to Jira only in steps 5 and 7, and only what was approved in step 4. Never change an existing issue's status,
  assignee or fields other than those its mode allows.

## Existing issue

The request says which mode applies; it may also narrow it (e.g. "keep the description, only add sub-tasks"):

- **Implement under it**: no field writes for it in step 5 (step 7 still attaches the spec to it). It is the single
  leaf, and the parent, of the `Tickets` section, marked `(brief: spec)`, since its own description isn't a brief.
- **Update it**: rewrite its description (and its summary, if the request says so) as a brief. It becomes the leaf, or
  the parent when the plan splits the work, and its children are created under it.
- **Extend it**: keep it as the parent and create the planned children under it: Sub-tasks under a Task, Tasks under a
  Story. Don't change its own fields. A Sub-task can't have children: stop and say so.

Its project, tag and labels apply to the new children. If its project differs from the one the spec implies, keep its
project.

## Ticket brief

Every leaf ticket (a lone Task, a Sub-task, a Task under a Story) carries all that someone with no other context needs
to implement it. Cut each leaf's description from the spec's sections, in the layout of
`${CLAUDE_SKILL_DIR}/../spec/brief.md`, instead of rewording them. `Verification` is required, and the tickets a leaf
depends on go under `Notes`.

A parent holds only Summary, Scope, the spec's path and the list of its children.

## Report

Give the tickets with their keys and URLs, marked created, updated or unchanged, the spec's path, and whether the spec
attached to the parent ticket, with the reason when it didn't. Then give the `/feature <spec path>` that implements
every repository in one run, and say to add `resume` if it stops part-way. For a repository recorded to run on its own,
give its `/feature <spec path> <repository>` and the checkout to start it in, and name the repositories the main run
gets instead.
