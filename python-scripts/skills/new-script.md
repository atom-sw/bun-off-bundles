---
name: new-script
description: Scaffold a new standalone Python script and its unittest test file. Use when starting a fresh single-file script, a CLI utility, or an automation script, or when the user asks to create a new script from a template.
disable-model-invocation: true
---

# Scaffold a standalone script

Create a new single-file Python script that runs with `python script.py` and a matching
`unittest` test file. Follow these steps.

## 1. Settle the basics

- Pick a filename in `snake_case` ending in `.py` (for example `resize_images.py`). Ask the user
  if it is not clear from the request.
- Confirm what the script does and its command-line interface: positional arguments, options, and
  defaults.
- Decide whether it needs any third-party dependency. Prefer zero (see the
  `python-script-dependencies` rule). Add one only if the standard library genuinely falls short.

## 2. Write the script

Generate `<name>.py` from this template, filling in the argument parsing and the real work:

```python
#!/usr/bin/env python3
"""One line describing what this script does."""

import argparse


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    # parser.add_argument("input", help="...")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    """Run the script. Return the process exit code."""
    args = parse_args(argv)
    # ... do the work ...
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

Only if the script needs a dependency, add a PEP 723 metadata block directly under the docstring,
so the file stays runnable with `uv run <name>.py` or `pipx run <name>.py`:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["<package>"]
# ///
```

## 3. Write the test

Generate `test_<name>.py` beside the script, importing its functions and covering the core logic
plus the key edge cases:

```python
import unittest

import <name>


class TestMain(unittest.TestCase):
    def test_runs_with_no_arguments(self) -> None:
        self.assertEqual(<name>.main([]), 0)


if __name__ == "__main__":
    unittest.main()
```

## 4. Verify

- Run `python <name>.py --help` and confirm the usage text reads well.
- Run `python -m unittest` and confirm the tests pass.
- If the project uses ruff, run `ruff format <name>.py` and `ruff check --fix <name>.py`.
