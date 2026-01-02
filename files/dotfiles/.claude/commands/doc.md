# Docstring Generator

Generate docstrings for code objects (functions/methods/classes).

## Mode of Operation

**Detect mode based on context:**

- If the user provides code in their message (selected text), work with that selection
- If user provides a file or multiple files, work with these full files
- If no code is provided in the message, use the current file/buffer
- Use the Edit tool to add/update the docstring in the file, triggering a diff view for the user to review

## Common Rules (All Variants)

- ALWAYS follow language-specific formatting rules below
- ALWAYS use imperative form for functions/methods ("Return the sum", "Calculate the result")
  - Header should use IMPERATIVE form
  - Body should use DESCRIPTIVE form
  - If they both are merged, IMPERATIVE form should be used
- ALWAYS use descriptive form for classes ("A container for...", "Represents a user account").
- ALWAYS wrap proper names or names of objects in backticks `` when writing a docstring
- NEVER add empty lines between the docstring and function content
- Maximum line width is 100 chars
- Skip listing class attributes / function parameters in the docstring if they are obvious or their description
  does now introduce any new information

## Language-Specific Formatting

### Python

- ALWAYS use Google-style docstrings
- ALWAYS Skip type hints in docstring if code is already type-hinted
- In case function is simple, Merge header with description into a single paragraph
- Docstring quotes MUST be defined on separate line (where applicable)
- Skip `__init__` docstrings if all they are generic and all they do is setup instance attributes
- **Example structure**:

  ```python
  """
  Brief description of function/class. Written in IMPERATIVE form for functions/methods.

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
