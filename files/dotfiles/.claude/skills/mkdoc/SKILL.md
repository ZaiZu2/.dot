---
name: mkdoc
title: Project Documentation Generator
description: Generate markdown documentation for projects, matching the established writing style and formatting conventions
permissions:
  - bash
---

# Project Documentation Generator

This skill enables Claude to write documentation pages for a project by exploring its codebase and producing markdown that matches the established style conventions.

## Capabilities

- **Generate new docs**: Write documentation for a module, CLI tool, config system, or workflow from scratch
- **Extend existing docs**: Add or update sections in existing documentation files
- **Consistent style**: Produce output that mirrors the project's own tone, formatting, and structure

## Usage Examples

### Document a new tool or module
"Document the ABN reporting module"

"Write docs for the SFTP integration"

### With a target file
"/doc the exposure config system, save it to docs/exposure.md"

### Update existing documentation
"/doc update the CLI section of docs/abn.md with the new --dry-run flag"

## Instructions for Claude

When this skill is invoked:

### Step 1 — Discover existing documentation and infer style

Before writing anything, search the project for existing documentation files. Look for:
- Any `.md` or `.rst` files anywhere in the project tree
- Common locations: project root, `docs/`, `doc/`, `wiki/`, `.github/`

Read 2-3 of the most representative files and infer the following from what you observe:
- **Tone**: formal vs. casual, use of parenthetical asides, humour
- **Tense and voice**: present/past, first/third person, imperative for instructions
- **Header style**: casing (title case vs. sentence case), depth used, numbering
- **Inline formatting**: what gets backticked, what gets bolded, what is left plain
- **Code block conventions**: language tags used (` ```sh `, ` ```bash `, ` ```python `, none, etc.)
- **List style**: bullet marker used (`-`, `*`, `+`), numbered vs. unordered
- **Warning/note patterns**: blockquotes, bold prefixes, plain prose
- **Section patterns**: what sections recur across files and in what order

Use this inferred style for all generated output. Do not impose a default style on top of one that already exists.

If no documentation files are found, fall back to sensible generic conventions: present tense, title-case headers, backticks for code, `-` for bullets, prose-embedded warnings.

### Step 2 — Understand the target

Read the relevant source files, config examples, and CLI entry points. Identify:
- What the module or tool does and its role in the system
- Configuration surface (env vars, config files, defaults)
- CLI interface (commands, flags, arguments) inferred from source
- How it runs in production (cron, daemon, manual, etc.)

While reading source files, scan all inline comments for any remarks related to docstrings or documentation — not just TODOs. Specifically:
- If a comment says anything like `# add to docstring`, `# TODO: document this`, `# mention in docs`, `# note: document X`, or any similar indication that something should be reflected in the docstring/documentation — incorporate that information into the generated output, then remove the comment from the source file.
- If a comment references a documentation update or improvement — treat its content as a signal about what should be reflected in the documentation you generate.
- Only remove inline comments that have been fully addressed by what you've written. Do not remove unrelated comments.

Do not invent behaviour — only document what is observable in the code.

### Step 3 — Determine the output location

- If the user specifies a path, use it.
- Otherwise, look for where existing docs live (a `docs/` directory, the root, etc.) and place the new file there.
- If no documentation directory exists and no path is specified, default to `README.md` in the project root.

### Step 4 — Write the file

- Use the Write tool to create a new file, or the Edit tool to update an existing one.
- If the target file already exists and the user did not explicitly name it as the target, confirm before overwriting.
- Structure the document to match what you observed in Step 1 — section names, ordering, depth, and formatting should feel native to the project.

### Step 5 — Confirm to user

State what was written and where, and briefly describe the sections included.

**Important:**
- Match the project's tone — do not default to generic, corporate-sounding documentation.
- Do not add YAML frontmatter unless the project's existing docs already use it.
- Keep sentences informative but readable; avoid bullet-point-only sections where prose flows better.
- Do not document hypothetical features — only what exists in the code.
