"""Post-install hook: activate rtk for the deployed platforms.

rtk (rtk-ai/rtk) compresses verbose command output before it reaches the model.
Its activation is a one-time `rtk init`, analogous to llm-tldr's `tldr warm`.

rtk's effective integrations are global-only, so this hook always initializes
globally regardless of deploy scope:

- Claude: the interception is a `PreToolUse` hook (`rtk hook claude`) in
  `settings.json` plus `RTK.md`. Only `rtk init -g` installs it; a local init
  writes an inert `CLAUDE.md` note and no hook.
- OpenCode: the plugin (`~/.config/opencode/plugins/rtk.ts`) is global-only, and
  `--opencode` also installs the Claude hook, so a single `rtk init -g --opencode`
  covers both platforms.

Antigravity is not handled here: rtk's `--agent antigravity` writes to
`.agents/rules/`, which `agy` never loads. The bundle instead ships an rtk-usage
rule scoped `available_on: [antigravity]`, which boff inlines into `GEMINI.md`.

Re-init is not needed periodically: the Claude hook (PATH-resolved) and the
OpenCode plugin (a thin delegator to `rtk rewrite`) survive rtk version bumps.
Only a major rtk upgrade that changes the hook/plugin contract warrants it.

Activation is best-effort: if the rtk binary is absent the hook prints an install
hint and exits cleanly, so it never fails the deploy.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from boff.hooks import HookContext
from boff.types import ScopeKind

_INSTALL_HINT = (
    "rtk not found: skipping activation. "
    "Install it once with `brew install rtk`, the curl installer from its README, "
    "or via mise (`rtk`), then re-run the deploy."
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
    """Run `rtk init` once for the deployed platforms, degrading gracefully."""
    ctx = HookContext.from_stdin()

    platforms = {p for p in ctx.platforms if p in {"claude", "opencode"}}
    if not platforms:
        return

    cwd = None if ctx.scope.kind is ScopeKind.GLOBAL else ctx.scope.workspace_root
    rtk = _resolve("rtk", cwd)
    if rtk is None:
        print(f"[rtk-init] {_INSTALL_HINT}")
        return

    if "opencode" in platforms:
        # rtk's OpenCode plugin is global-only, and --opencode also installs the
        # Claude Code hook: one global invocation covers both platforms.
        argv = [rtk, "init", "-g", "--opencode", "--auto-patch"]
        label = "claude+opencode (global)"
    else:
        # Claude only: init globally, since only `rtk init -g` installs the
        # PreToolUse hook. A local init would write an inert CLAUDE.md note.
        argv = [rtk, "init", "-g", "--auto-patch"]
        label = "claude (global)"

    try:
        # rtk's Claude hook and OpenCode plugin are global: run from the process
        # cwd so the deploy scope never scatters project-local rtk artifacts.
        subprocess.run(argv, cwd=None, check=True)
        print(f"[rtk-init] activated for {label}")
        if "opencode" in platforms:
            print("[rtk-init] restart OpenCode to load the newly installed plugin")
    except (subprocess.CalledProcessError, OSError) as exc:
        print(f"[rtk-init] skipped: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()
