---
title: GitHub PR Manager
description: Automatically create or update a GitHub PR for the current branch with an AI-generated description
permissions:
  - bash
---

# GitHub PR Manager

This skill enables Claude to analyze all changes on the current branch and automatically create or update a GitHub Pull Request with a structured, informative description.

## Capabilities

- **Smart Create or Update**: Detects if a PR already exists for the branch and updates it, otherwise creates a new one
- **JIRA Integration**: Extracts ticket ID from branch name, renders it as a header link at the top of the description
- **AI-Generated Summary**: High-level overview of what the PR achieves
- **Implementation Section**: Technical description of how the change was implemented

## Usage Examples

### Basic — auto-generate everything
`/pr`

### With a title hint
`/pr FAPE-1319: add FX trade reconciliation for ABSA`

### After pushing new commits — refresh the PR description
`/pr`

## Implementation

Uses `gh` CLI and `git` — no additional dependencies required.

```bash
# Get current branch
git branch --show-current

# Find divergence from master
git log --oneline master..HEAD

# Full diff for analysis
git diff master...HEAD

# Check for existing PR
gh pr view --json number,title,url 2>/dev/null

# Create PR
gh pr create --base master --title "..." --body "..."

# Update existing PR body
gh pr edit --body "..."
```

## Instructions for Claude

When this skill is invoked with `/pr [optional title hint]`:

### 1. Gather branch context

Run these commands and capture their output:
```bash
git branch --show-current
git log --oneline master..HEAD
git diff master...HEAD
```

### 2. Extract JIRA ticket

- Scan the branch name for a pattern matching `[A-Z]+-[0-9]+` (e.g. `FAPE-1319`, `JIRA-42`)
- If found, construct the link: `https://absa.atlassian.net/browse/<TICKET>`
- If not found, omit the JIRA section from the description silently

### 3. Check for existing PR

```bash
gh pr view --json number,title,url 2>/dev/null
```

- If the command succeeds (exit code 0), a PR exists — you will **update** it
- If it fails (no PR), you will **create** a new one

### 4. Analyze changes and generate PR description

Read through the git log and diff output and write:

```markdown
### [TICKET](https://absa.atlassian.net/browse/TICKET)

## Summary

[1-3 sentences describing what the PR achieves at a high level. Focus on the outcome, not the implementation details. Do not use generic filler phrases.]

## Implementation

[2-4 sentences describing the technical approach: key new functions/classes, data structures, or patterns introduced, and how they fit together. Be specific about what changed and why.]
```

**Rules:**
- Omit the `### [TICKET]` header entirely if no ticket was found
- Summary = what it achieves (user-facing / business outcome)
- Implementation = how it was built (technical, specific)
- Keep both sections concise — no padding
- Do not include a "Generated with Claude Code" footer

### 5. Determine PR title

Priority order:
1. If user passed a title hint after `/pr`, use it verbatim
2. Otherwise: `<TICKET>: <short description>` where description is derived from the most meaningful commit or a one-line summary of the changes
3. If no ticket: just a short descriptive title from the changes

### 6. Create or update the PR

**If creating:**
```bash
gh pr create \
  --base master \
  --title "<title>" \
  --body "$(cat <<'PRBODY'
<generated description>
PRBODY
)"
```

**If updating:**
```bash
gh pr edit \
  --title "<title>" \
  --body "$(cat <<'PRBODY'
<generated description>
PRBODY
)"
```

### 7. Confirm to user

- Print whether the PR was **created** or **updated**
- Print the PR URL
- Show a short preview of the summary section
