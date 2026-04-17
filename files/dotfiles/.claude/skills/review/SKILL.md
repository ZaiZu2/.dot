---
title: PR Review
description: Review code changes and provide structured feedback. Use when the user invokes /review or asks to review changes, review a diff, or review the current branch.
permissions:
  - bash
---

# PR Review

Analyze code changes and provide structured, actionable feedback organized by category.

## Usage Examples

### Review current branch against master
`/review`

### Review against a specific base
`/review main`
`/review origin/develop`

### Review a specific diff range
`/review HEAD~3 HEAD`
`/review abc123 def456`

## Instructions for Claude

When this skill is invoked with `/review [base] [head]`:

### 1. Determine diff range

- **No arguments**: `git diff master...HEAD`
- **One argument** (base branch/ref): `git diff <base>...HEAD`
- **Two arguments** (base and head): `git diff <base>...<head>`

Run the diff and also gather context:

```bash
# Get the diff
git diff master...HEAD

# Get list of changed files for orientation
git diff master...HEAD --name-status

# Get recent commits on this branch
git log master..HEAD --oneline
```

### 2. Analyze the changes

Read and understand:
- What the change is trying to achieve (from commit messages and code intent)
- All modified, added, and deleted files
- The broader context around changed lines (read full files if needed using the Read tool)

### 3. Produce the review

Output a structured markdown review directly to the terminal. Use the following section structure, **only including sections where you have findings** — omit empty sections entirely.

---

```
## Code Review

### Summary
[1-2 sentences: what the change does and overall assessment]

---

### Correctness
[Logic bugs, incorrect assumptions, off-by-one errors, race conditions, broken edge cases]

Findings use this format:
**`path/to/file.py:42`** — Description of the issue.

---

### Security
[Injection risks, authentication/authorization issues, secrets or credentials in code,
 unsafe deserialization, unvalidated input at system boundaries]

---

### Code Quality
[Unnecessary complexity, duplication, misleading naming, broken abstractions,
 dead code, over-engineering, violation of single responsibility]

---

### Type Safety
[Missing or incorrect type hints, unsafe casts, ignored type errors, `Any` used where
 a specific type is known]

---

### Documentation
[Missing or misleading docstrings, outdated comments, undocumented public APIs,
 complex logic with no explanation]

---

### Language-Specific
[Issues specific to the language(s) used in the diff — see rules below]

---

### Verdict
[One of: ✅ Looks good | ⚠️ Minor issues | ❌ Needs changes]
[One sentence justification]
```

---

### 4. Severity labelling

Prefix each finding with a severity tag:

- `[MUST]` — Must be fixed: bugs, security issues, broken contracts
- `[SHOULD]` — Strong suggestion: non-critical but clearly better
- `[NIT]` — Minor: style, preference, low-impact improvements

### 5. Language-Specific Rules

Apply these rules in the **Language-Specific** section when the relevant language is detected in the diff.

#### Python

- Mutable default arguments (e.g. `def f(x=[])`) are a bug
- Bare `except:` or `except Exception:` that silences errors
- Using `type(x) == Foo` instead of `isinstance(x, Foo)`
- Missing `__all__` in public modules
- Blocking I/O inside async functions
- f-strings used for logging (use `%s` or `extra=` for lazy evaluation)
- Direct `.format()` on SQL strings (SQL injection risk)

#### TypeScript / JavaScript

- `any` type used where a specific type is known
- `console.log` left in production code
- Missing `await` on async calls
- Direct string interpolation into SQL or shell commands
- `==` instead of `===`

---

### General rules

- **Be specific**: always cite file and line number when possible
- **Be concise**: one finding per bullet, no padding
- **Be proportionate**: don't flag nits if there are blocking issues — focus attention on what matters
- **Skip empty sections**: if there are no findings for a category, omit it
- **Context matters**: read surrounding code before flagging something — it may be intentional
- **Verify before flagging**: if a finding depends on the behavior of a called function (e.g. whether it raises or returns None), read that function's source before including the finding. Do not assume behavior — trace through to the implementation
