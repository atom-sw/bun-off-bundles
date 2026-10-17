"""Post-install hook: install Claude Code's `pyright-lsp` plugin.

The bundle enables `pyright-lsp@claude-plugins-official` through `enabledPlugins`, which
turns the plugin on but does not install it. Claude Code declares LSP servers only through
plugins, so without this hook Claude reports the plugin as "enabled but not installed". The
plugin gives Claude Pyright's diagnostics after every edit, which Serena (on-demand checks
only) does not.

The install is best-effort: a missing `claude` or a failed install prints a note and never
fails the deploy. `boff clean` removes the `enabledPlugins` key but leaves the plugin's cache
under `~/.claude/plugins`.
"""

from __future__ import annotations

import shutil
import subprocess
import sys

from boff.hooks import HookContext
from boff.types import ScopeKind

PLUGIN = "pyright-lsp@claude-plugins-official"
_TIMEOUT = 120  # seconds; the first install may clone the official marketplace


def main() -> None:
    """Install the plugin at the scope that matches the deploy."""
    ctx = HookContext.from_stdin()

    if "claude" not in ctx.platforms:
        return
    if shutil.which("claude") is None:
        print(f"[pyright-lsp] claude not found on PATH: run `claude plugin install {PLUGIN}`.")
        return

    workspace = ctx.scope.kind is ScopeKind.WORKSPACE
    argv = ["claude", "plugin", "install", PLUGIN, "--scope", "project" if workspace else "user"]
    try:
        result = subprocess.run(
            argv,
            cwd=ctx.scope.workspace_root if workspace else None,
            stdin=subprocess.DEVNULL,
            check=False,
            timeout=_TIMEOUT,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"[pyright-lsp] skipped: {exc}", file=sys.stderr)
        return
    if result.returncode != 0:
        print(f"[pyright-lsp] install failed: run `{' '.join(argv)}` by hand.", file=sys.stderr)


if __name__ == "__main__":
    main()
