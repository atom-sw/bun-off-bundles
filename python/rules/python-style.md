# Python style

Follow PEP 8, enforced by ruff. Ruff handles both linting and formatting.

- Format with `uv run ruff format` and lint with `uv run ruff check` (autofix via
  `uv run ruff check --fix`). Let ruff own layout: do not hand-format.
- Add type hints to every public function signature and public attribute.
- Give every public function, class, and module a brief docstring stating its purpose.
- Prefer clear, standard-library idioms over clever one-liners.
