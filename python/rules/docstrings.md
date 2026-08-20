# Python docstrings

Document public modules, classes, and functions with docstrings that follow PEP 257.

- Open with a one-line summary in the imperative mood ("Return the parsed config"), on the
  same line as the opening triple double-quotes. For a longer docstring, follow the summary
  with a blank line and then the details.
- Describe the parameters, return value, and raised exceptions that a caller cannot infer
  from the signature. Do not repeat the type hints in prose: the annotations already state
  the types.
- Pick one convention for the project (Google, NumPy, or reStructuredText) and apply it
  consistently. Follow the convention the surrounding code already uses.
- Explain intent and edge cases, not the obvious. Skip a docstring that would only echo the
  function's name.
- Keep docstrings current: revise them whenever the behavior or signature changes.
