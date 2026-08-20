# Python toolchain

This project uses `uv` for environment and dependency management. Always go through it.

- Run scripts and tools with `uv run` (for example `uv run pytest`, `uv run ruff check .`).
  Do not invoke a bare `python` or a globally installed tool.
- Add and remove dependencies with `uv add` and `uv remove` so the lockfile stays in sync.
  Never `pip install` into the environment.
- Sync the environment with `uv sync` after pulling changes to dependencies.
