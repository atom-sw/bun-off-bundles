# Script dependencies

The goal is a script that is trivial to run. Default to zero external dependencies so a user can
run it with a bare `python script.py`: no virtual environment, no `pip install`, no build step.

- Reach for the standard library first. It already covers argument parsing (`argparse`), HTTP
  (`urllib.request`), JSON (`json`), paths (`pathlib`), subprocesses (`subprocess`), and more.
  A dependency-free script is the lightest thing to share and the least likely to break.
- Add a third-party package only when the standard library genuinely falls short, and keep the
  set small. Every dependency is one more thing a user must install before the script runs.
- When a script does need dependencies, declare them inline with PEP 723 script metadata, so the
  file stays self-describing and stays runnable through a tool that reads it:

  ```python
  # /// script
  # requires-python = ">=3.12"
  # dependencies = ["requests"]
  # ///
  ```

  A user then runs it with `uv run script.py` or `pipx run script.py`, which provisions the
  dependencies automatically. As an alternative, ship a minimal `requirements.txt` and document
  `pip install -r requirements.txt`.
- Never require a packaging or build step to *run* a script: no wheel, no `pip install .`, no
  entry-point console script. Those belong to a library or application, not a standalone script.
- Keep tests out of what a user installs to run the script. The test file lives beside the
  script for development, but running the script must never pull in the tests or a test runner.
