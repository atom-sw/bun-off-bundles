#!/usr/bin/env sh
# Format and autofix an edited Python file with ruff, but only when the project
# opts into ruff. BOFF_FILE is the path of the edited file (boff event-hook contract).
case "$BOFF_FILE" in
  *.py) ;;
  *) exit 0 ;;
esac

# Only touch projects that use ruff: a ruff config, or a [tool.ruff] table.
{ [ -f ruff.toml ] || [ -f .ruff.toml ] || grep -q '^\[tool\.ruff' pyproject.toml 2>/dev/null; } || exit 0

# Prefer ruff on PATH; fall back to uv-managed ruff. No-op if neither is available.
if command -v ruff >/dev/null 2>&1; then
  ruff format "$BOFF_FILE"
  ruff check --fix "$BOFF_FILE"
elif command -v uv >/dev/null 2>&1; then
  uv run ruff format "$BOFF_FILE"
  uv run ruff check --fix "$BOFF_FILE"
fi
