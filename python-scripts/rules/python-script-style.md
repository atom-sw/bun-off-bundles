# Script style

Keep scripts clear and conventional. These are lighter than a full application's standards, but
they still earn the next reader's time.

- Follow PEP 8, enforced by ruff. Format with `ruff format` and lint with `ruff check`
  (autofix via `ruff check --fix`). Let ruff own layout: do not hand-format. Neither command
  needs uv: run `ruff` directly if it is on `PATH`.
- Add type hints to function signatures. They document intent and let pyright catch mistakes,
  and they cost nothing at runtime.
- Give the module and each non-trivial function a one-line docstring stating its purpose. Skip
  the docstring on a function whose name and signature already say everything.
- Prefer the standard library and clear, idiomatic code over clever one-liners. Reach for a
  third-party package only when the standard library genuinely falls short (see
  `python-script-dependencies`).
- A `pyproject.toml`, `ruff.toml`, or `[tool.ruff]` table configures these dev tools, but it is
  for development only: the script itself must never need it to run.
