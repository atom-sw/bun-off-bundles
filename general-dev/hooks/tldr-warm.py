"""Post-install hook: build the llm-tldr semantic index for the project.

general-dev deploys the llm-tldr MCP server, which answers queries from a
semantic index. That index is built by a one-time `llm-tldr warm .`, after which
edits patch it incrementally. This hook runs that warm step for the deployed
project so the server is ready on first use. It uses the unambiguous `llm-tldr`
entry point (the `tldr` alias collides with the tldr-pages client). Warming is
best-effort: if the binary is absent the hook prints an install hint and exits
cleanly, so it never fails the deploy.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from boff.hooks import HookContext
from boff.types import ScopeKind

_INSTALL_HINT = (
    "llm-tldr not found: skipping index warm. "
    "Install it once with `uv tool install llm-tldr` (or via mise: `pipx:llm-tldr`), "
    "then run `llm-tldr warm .` in the project."
)


def _resolve(tool: str, cwd: Path | None) -> str | None:
    """Find a tool on PATH, falling back to a mise-managed install."""
    found = shutil.which(tool)
    if found is not None:
        return found
    if shutil.which("mise") is None:
        return None
    try:
        result = subprocess.run(
            ["mise", "which", tool], cwd=cwd, capture_output=True, text=True, check=False
        )
    except OSError:
        return None
    path = result.stdout.strip()
    return path if result.returncode == 0 and path else None


def main() -> None:
    """Warm the llm-tldr index in the deployed project, degrading gracefully."""
    ctx = HookContext.from_stdin()

    # llm-tldr indexes a project directory. Warm the workspace for a workspace
    # deploy; fall back to the current directory for a global deploy.
    cwd = ctx.scope.workspace_root if ctx.scope.kind is ScopeKind.WORKSPACE else None

    tldr = _resolve("llm-tldr", cwd)
    if tldr is None:
        print(f"[tldr-warm] {_INSTALL_HINT}")
        return

    try:
        subprocess.run([tldr, "warm", "."], cwd=cwd, check=True)
        print("[tldr-warm] index built")
    except (subprocess.CalledProcessError, OSError) as exc:
        print(f"[tldr-warm] skipped: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()
