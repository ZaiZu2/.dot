---
name: test
description:
    '[auto] Write or update unit tests for specified files, code objects or changes. Use when the user asks to write,
    add or update tests for specific code.'
context: fork
model: opus
---

# Unit Tests

Write or update unit tests for the named code, then run them until they pass. A good result reads like the project's
existing tests and covers the happy path, edge cases and error conditions. Change only test code (tests, fixtures, test
data), never the code under test.

## Target

What the request names: files or modules, specific functions or classes, or changes (a diff, commits, a PR). For
changes, test the code they add or modify. If the request names nothing, stop and reply only that files, code objects or
changes must be specified.

## Actions

### 1. Learn the conventions

Read the test config, the shared fixtures and helpers, and the existing tests closest to the target. Note the layout and
file naming, classes or plain functions, how test data is kept and what gets mocked. Where these differ from the rules
below, the project wins.

### 2. Read the target

Read the target and the code it calls: behavior, edge cases, side effects and the errors it raises. For a library whose
API you aren't sure of, look up its docs with the `mcp__context7__*` tools when they are available.

### 3. Write the tests

Extend the target's existing test file if there is one; otherwise create it where the project's layout puts it. Reuse
existing fixtures and helpers before adding new ones.

### 4. Run and fix

Run only the tests you wrote, with the project's runner. Fix failures caused by the test (imports, fixtures, patch
paths, wrong assertions) and rerun, for at most 3 rounds. Never change what a test checks just to make it pass. If a
failure shows the target not doing what its name, docs or types promise, keep the assertion, mark the test as an
expected failure with the reason, and report it.

### 5. Document

Once the tests pass, call the Skill tool with `doc`, naming the test files you created or changed, so their docstrings
follow the project's style. If the Skill tool is unavailable, read `${CLAUDE_SKILL_DIR}/../doc/SKILL.md` and apply its
rules yourself. Rerun the tests afterwards.

## Rules

- Cover the happy path, edge cases (empty, `None`, boundaries) and error conditions, plus side effects where the target
  has them.
- One behavior per test. Parametrize cases that differ only in their input.
- Mock only at boundaries (network, database, filesystem, time, external services), never the unit under test or pure
  helpers.
- Name each test after its scenario and expected outcome.
- No header-like comments to separate sections.
- Constants: declare a value used by two or more tests at the top of the file, after the imports; keep single-use values
  inline. No leading underscore. Derive related constants from one another, and keep unrelated ones independent.

### Python

- pytest. Methods are `test_<scenario>_<expected_outcome>`, classes `Test<Name>`.
- Type hints on every test and fixture (`-> None` for tests).
- Prefer built-in fixtures (`tmp_path`, `monkeypatch`, `caplog`, `capsys`) over hand-rolled ones.
- Patch a name where it is looked up, not where it is defined.
- Freeze time with the library the project already uses.
- Run through the project's runner if it has one (`uv run`, `poetry run`, `tox`), e.g. `pytest <file> -v`.
- Expected failure: `@pytest.mark.xfail(strict=True, reason="...")`.

## Report

List the test files created or changed with the tests in each, the result of the final run, every expected-failure test
with the suspected bug in the target, and the assumptions made.
