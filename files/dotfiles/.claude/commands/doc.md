# Docstring Generator

Generate docstrings for code objects (functions/methods/classes).

## Mode of Operation

**Detect mode based on context:**

- If the user provides code in their message (selected text), work with that selection
  - If selection spans multiple objects, choose the outermost one (or first if multiple outermost)
- If no code is provided in the message, use the current file/buffer

## Common Rules (All Variants)

- Follow language-specific formatting rules below
- Always wrap proper names or names of objects in backticks `` when writing a docstring

## Language-Specific Formatting

### Python

- **Style**: Google-style docstrings
- **Type hints**: Skip type hints in docstring if code is already type-hinted
- **Format**: Merge header with description into one block. Docstring quotes MUST be defined on separate lines
  (where applicable)
- **Example structure**:

  ```python
  """
  Brief description of function/class.

  Args:
      param1: Description
      param2: Description

  Returns:
      Description of return value

  Raises:
      ExceptionType: When this exception occurs
  """
  ```

## Default: Full Docstring

Generate a comprehensive docstring for the selected object.

**Instructions:**

1. Provide full list of object properties (attributes, methods, arguments, returns, raises, etc.)
2. Use the Edit tool to add/update the docstring in the file, triggering a diff view for the user to review

## Variant 2: All Objects

To generate docstrings for ALL objects in selection, use: `/doc --all`

**Instructions:**

1. Each docstring MUST be a single short paragraph
2. Use the Edit tool to add/update docstrings for each object in the file, triggering a diff view for the user to
   review
