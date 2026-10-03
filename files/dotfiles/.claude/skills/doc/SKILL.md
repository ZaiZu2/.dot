---
name: doc
description: "[auto] Add or update docstrings for specified files or code objects (functions, methods, classes)."
context: fork
model: sonnet
---

# Docstrings

Add or update docstrings in place with the Edit tool. A good result tells the reader what they can't see from the
signature, in the project's existing docstring style.

## Target

Document only what the request names: files, or specific functions, classes or methods in them. If the request names
no target, stop and reply only that files or code objects must be specified.

Within the named files, also comment config lines (`Dockerfile`, `*.ini`, `*.toml`, `*.yaml`, shell scripts) whose
value or directive does something non-obvious, e.g. `AWS_PROFILE=crossaccount` selecting a cross-account assume-role
flow, or a magic UID. Put the comment right above the line, in the file's comment syntax. The test: a reader would
have to look elsewhere to understand why the line exists. Skip self-explanatory config and placeholder files like
`.env.example`.

## Actions

Read each target and the code it calls or configures, plus nearby docstrings for the project's style. Then add or
update the docstrings with Edit, following the rules below. Change nothing but docstrings and comments.

## Rules

- Functions and methods: imperative summary line ("Return the sum"), descriptive body. If the docstring is a single
  merged paragraph, use the imperative.
- Classes: descriptive form ("Represents a user account").
- Wrap names of objects and proper names in backticks.
- No blank line between the docstring and the code that follows.
- Maximum line width is 100 characters.
- Document parameters in an `Args:` block. Skip it for simple or conventional functions (getters, dunder methods,
  one-line helpers) where names and types say it all; never list `self` or `cls`.
- Put information that applies to several parameters or the whole function in a `Note:` block instead of repeating it.

## Python

- Google style. Opening and closing quotes on their own lines.
- Leave out types already given by type hints.
- For simple functions, merge the summary and description into one paragraph, still in Google style.
- Skip `__init__` docstrings that would only say the attributes get set.
- For type aliases and complex type assignments (`RootModel[...]`, `TypedDict`, `dict[...]` aliases), add an inline `#`
  comment explaining the structure and meaning; put it on the line above if it would exceed the line width.

```python
"""
Brief summary, imperative for functions and methods.

Args:
    param: Description
    longer_param: Long description which is longer than 100 characters and will wrap into
                  a new line which is indented deep enough to match the description in
                  the first line

Returns:
    Description of return value

Raises:
    ExceptionType: When this exception occurs
"""
```

## Report

List the files and the objects documented in each.
