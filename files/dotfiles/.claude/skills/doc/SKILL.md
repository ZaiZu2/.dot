---
name: doc
description:
    "[auto] Add or update docstrings for specified files or code objects (functions, methods, classes). Use when the user
    invokes /doc or asks for docstrings."
context: fork
model: sonnet
---

# Docstrings

Add or update docstrings in place with the Edit tool.

## Scope

Default target is source code (functions, methods, classes), but the skill applies to **any file where inline
documentation is conventional and load-bearing** — not just Python. Broaden the scope opportunistically:

- **Config files** (`Dockerfile`, `*.ini`, `*.toml`, `*.yaml`, shell scripts, `~/.aws/config`, etc.) where a bare
  value or directive is silently doing something non-obvious (e.g. `AWS_PROFILE=crossaccount` selecting a
  cross-account assume-role flow, a magic UID/GID, a load-bearing env var). Add a comment right above the line
  in whatever comment syntax the file uses.
- Skip files where added comments would clutter without informing — e.g. `.env.example` (values are placeholders,
  meaning belongs in README) or fully self-explanatory config.

Rule of thumb: if a reader would have to grep the repo or read another file to understand why a line exists,
document it in place.

## Mode of Operation

Document only what the request names: files, or specific functions, classes or methods in them. If the request names
no target, stop and reply only that files or code objects must be specified.

## Rules

- Functions and methods: imperative summary line ("Return the sum"), descriptive body. If the docstring is a single
  merged paragraph, use the imperative.
- Classes: descriptive form ("Represents a user account").
- Wrap names of objects and proper names in backticks.
- No blank line between the docstring and the code that follows.
- Maximum line width is 100 characters.
- Omit parameters and attributes whose description would add nothing beyond the name and type.
- Put information that applies to several parameters or the whole function in a `Note:` block instead of repeating it.

- ALWAYS follow language-specific formatting rules below
- ALWAYS use imperative form for functions/methods ("Return the sum", "Calculate the result")
    - Header should use IMPERATIVE form
    - Body should use DESCRIPTIVE form
    - If they both are merged, IMPERATIVE form should be used
- ALWAYS use descriptive form for classes ("A container for...", "Represents a user account").
- ALWAYS wrap proper names or names of objects in backticks `` when writing a docstring
- NEVER add empty lines between the docstring and function content
- Maximum line width is 100 chars
- ALWAYS document every function/method parameter in an `Args:` block. Only skip a parameter when the user has
  explicitly instructed you to omit it (e.g. "skip args", "no args section", "leave params out") — a parameter's
  description being "obvious from the name and type" is NOT sufficient justification. If a parameter is truly
  trivial (e.g. `self`, `cls`), omit it per language convention; everything else gets a line.
- Use a `Note:` block for cross-cutting information that applies to multiple parameters or the function as a whole, rather
  than duplicating it across individual parameter descriptions

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
