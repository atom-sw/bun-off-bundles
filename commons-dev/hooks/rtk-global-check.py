"""Post-install hook: warn about a leftover global rtk installation.

Migration aid, detection only: this hook reads files and never writes.

Bundle versions up to 0.1.0 activated rtk by running `rtk init -g`, which patches the
user's *global* Claude and OpenCode config. Since the rtk binary itself is installed per
project (via the bundle's mise drop-in), that global Claude hook fails with exit 127 in
every project that does not deploy this bundle, breaking each Bash tool call there.

The bundle now wires rtk up workspace-locally, so those global artifacts are both
obsolete and harmful. Nothing in a deploy would otherwise tell an existing user they are
still there, hence this advisory.

Remove this hook a release after the local wiring ships, once existing installs have
migrated.
"""

from __future__ import annotations

import json
from collections.abc import Callable
from pathlib import Path

from boff.hooks import HookContext
from boff.jsonutil import as_json_object

_UNINSTALL_HINT = (
    "Remove them with `rtk init -g --uninstall`. Dry-run it first: that command also "
    "deletes\n  ~/.claude/CLAUDE.md when stripping its @RTK.md line leaves the file "
    "empty. Otherwise edit each file by hand."
)


def _claude_settings_has_rtk_hook(path: Path) -> bool:
    """Report whether the global Claude settings still carry an rtk hook command."""
    try:
        # as_json_object is boff's narrowing boundary for a decoded payload: isinstance
        # alone would leave an unparameterized dict behind.
        data = as_json_object(json.loads(path.read_text(encoding="utf-8")))
    except (OSError, json.JSONDecodeError):
        return False
    return data is not None and "rtk hook" in json.dumps(data.get("hooks", {}))


def _claude_md_includes_rtk(path: Path) -> bool:
    """Report whether the global Claude instructions still `@`-include RTK.md."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return False
    return any(line.strip() == "@RTK.md" for line in lines)


def _stale_global_artifacts(platforms: tuple[str, ...]) -> list[Path]:
    """List the global rtk artifacts an earlier version of this bundle installed.

    Only artifacts belonging to a platform in this deploy are reported: a
    `--platform claude` deploy has no business commenting on OpenCode's config.
    """
    home = Path.home()
    checks: list[tuple[str, Path, Callable[[Path], bool]]] = [
        ("claude", home / ".claude" / "RTK.md", Path.is_file),
        ("claude", home / ".claude" / "CLAUDE.md", _claude_md_includes_rtk),
        ("claude", home / ".claude" / "settings.json", _claude_settings_has_rtk_hook),
        ("opencode", home / ".config" / "opencode" / "plugins" / "rtk.ts", Path.is_file),
    ]
    return [path for platform, path, is_stale in checks if platform in platforms and is_stale(path)]


def main() -> None:
    """Print an advisory when a global rtk installation is still in place."""
    ctx = HookContext.from_stdin()

    stale = _stale_global_artifacts(ctx.platforms)
    if not stale:
        return

    print("[rtk-global-check] rtk is now wired up per project, but a global install remains:")
    for path in stale:
        print(f"  - {path}")
    print("  It makes every Bash call fail in projects that do not deploy this bundle.")
    print(f"  {_UNINSTALL_HINT}")


if __name__ == "__main__":
    main()
