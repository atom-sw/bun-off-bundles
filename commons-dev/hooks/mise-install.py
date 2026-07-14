"""Post-install hook: install the bundle's toolchain with mise.

boff writes the tool declarations into `.config/mise/conf.d/boff.toml` but does
not run mise itself. This hook installs them right after the deploy, so the
bundle leaves a working toolchain without a manual pre-install step. `mise
install` is idempotent (it skips already-installed versions), so repeat deploys
are near-instant. Installation is best-effort: a missing mise or an install
hiccup prints a warning and never fails the deploy.
"""

from __future__ import annotations

import shutil
import subprocess
import sys

from boff.hooks import HookContext
from boff.types import ScopeKind


def main() -> None:
    """Run `mise trust` + `mise install` for the deployed workspace."""
    ctx = HookContext.from_stdin()

    if shutil.which("mise") is None:
        print("[mise-install] mise not found on PATH: skipping toolchain install.")
        return

    cwd = ctx.scope.workspace_root if ctx.scope.kind is ScopeKind.WORKSPACE else None
    try:
        subprocess.run(["mise", "trust"], cwd=cwd, check=False)
        subprocess.run(["mise", "install"], cwd=cwd, check=False)
        print("[mise-install] toolchain installed")
    except OSError as exc:
        print(f"[mise-install] skipped: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()
