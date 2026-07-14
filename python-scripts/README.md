# python-scripts bundle

A lightweight Python stack for **standalone scripts**: single-file programs with few or no
dependencies. Deployable to Claude Code and OpenCode with `bun-off`. It extends
[`commons-dev`](../commons-dev/README.md), so deploying it also installs that bundle's baseline
rules, the `context7` docs server, and rtk command-output compression.

It is the lighter sibling of the [`python`](../python/README.md) bundle. Where `python` targets
packaged, uv-managed projects with pytest and a semantic-code server, `python-scripts` targets
scripts you run directly.

## The guarantee

A script with no external dependencies runs with a bare `python script.py`: no virtual
environment, no `pip install`, no build step. The bundle's rules and tooling exist to keep that
true while still holding the code to sensible standards.

## What it deploys

Rules (scoped to Python files):

- `python-script-structure`: shebang, a `main()` guarded by `if __name__ == "__main__":`,
  `argparse` for the CLI, single-file until size warrants splitting.
- `python-script-style`: PEP 8 via ruff, type hints on signatures, brief docstrings, stdlib-first.
- `python-script-dependencies`: default to zero dependencies; when needed, declare them inline
  with PEP 723 (`uv run` / `pipx run`) or a minimal `requirements.txt`; never require a build to run.
- `python-script-testing`: test with the standard library's `unittest` (no pytest), run
  `python -m unittest`, keep the tests light.

Skill (manual-only):

- `new-script`: scaffold a runnable standalone script (shebang, `main()`, `argparse`, optional
  PEP 723 block) plus a matching `test_<name>.py`. Marked `disable-model-invocation`, so the
  agent will not auto-trigger it: invoke it explicitly. On OpenCode, a same-named `/new-script`
  slash command provides that entry point (OpenCode does not yet honor `disable-model-invocation`,
  so the skill also stays agent-invocable there).

Tooling:

- A ruff format-on-edit hook (Claude) and an equivalent native ruff formatter (OpenCode). Both are
  guarded: they format an edited Python file only when the project opts into ruff (a ruff config
  or a `[tool.ruff]` table), so the bundle never reformats a non-ruff project.
- A `mise.toml` declaring the dev tools `ruff` and `pyright`. It pins no Python runtime and
  requires no uv: those dev tools help you write the script, but the script itself runs on plain
  Python. These merge with commons-dev's rtk into one mise drop-in, installed by the inherited
  `mise-install` hook.

## What it deliberately omits

- **No packaging**: no wheels, no `uv publish`, no console entry points. A script is not a package.
- **No uv mandate**: uv (or pipx) is a convenient way to run a script that uses PEP 723 inline
  dependencies, but it is never required to run a dependency-free script.
- **No project-wide code intelligence**: it extends `commons-dev`, not `general-dev`, so it skips
  the `llm-tldr` server (whose project index adds little for a lone script) and the `serena`
  server that the `python` bundle adds.

## Usage

```
boff deploy path/to/bun-off-bundles/python-scripts --platform claude
boff deploy path/to/bun-off-bundles/python-scripts --platform opencode
```

## Existing projects

The bundle is safe to deploy on an existing project: it installs dev tools rather than a Python
runtime, format-on-edit stays dormant until the project adopts ruff, and the inherited
`match-project-conventions` rule tells the agent to follow the project's established toolchain
over these defaults.
