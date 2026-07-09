# python bundle

A Python development stack for Claude Code and OpenCode, deployable with `bun-off`. It
extends the `general-dev` bundle, so deploying it also installs that bundle's baseline
rules and MCP servers.

## What it deploys

Rules (scoped to Python files):

- `python-toolchain`: always work through `uv`; never bare `pip`.
- `python-style`: PEP 8 via ruff; type hints and docstrings on public API.
- `python-typing`: run the type checker before "done"; fix, don't suppress.
- `python-testing`: pytest through uv; targeted runs; `parametrize` and fixtures.
- `docstrings`: PEP 257 docstrings; imperative summary; document what types can't say.

Skill (manual-only):

- `python-packaging`: a uv-based release workflow (version bump, `uv build`, `uv publish`, tag).
  Marked `disable-model-invocation`, so the agent won't auto-trigger a release: invoke it
  explicitly with `/python-packaging`. On OpenCode, a same-named slash command provides that
  explicit entry point (OpenCode does not yet honor `disable-model-invocation`, so the skill
  also stays agent-invocable there).

MCP server:

- `serena`: LSP-backed semantic code navigation and editing (keyless, via `uvx`). Launched with
  `--open-web-dashboard false`, so it does not pop open the browser on startup; the dashboard
  stays reachable at serena's dashboard URL if you want it.

It also inherits general-dev's context management: the OpenCode Dynamic Context Pruning
plugin, the `context-management` rule, and rtk command-output compression (activated by a
`post_install` hook).

Tooling:

- A ruff format-on-edit hook (Claude) and an equivalent native ruff formatter (OpenCode).
  Both are guarded: they format an edited Python file only when the project opts into ruff (a
  ruff config or a `[tool.ruff]` table), so the bundle never reformats a non-ruff project.
- A `mise.toml` declaring the dev tools `uv`, `ruff`, and `pyright`. These combine with
  general-dev's tools (rtk, llm-tldr) into one mise drop-in, installed by the inherited
  `mise-install` hook. It does not pin the project's Python version: the project (or uv) owns that.

## Existing projects

The bundle is opinionated for greenfield work but safe to deploy on an existing project: it
installs dev tools rather than a Python runtime, format-on-edit stays dormant until the project
adopts ruff, and the inherited `match-project-conventions` rule tells the agent to follow the
project's established toolchain over these defaults.

## Usage

```
boff deploy path/to/bun-off-bundles/python --platform claude
boff deploy path/to/bun-off-bundles/python --platform opencode
```

## Notes

- `serena` and the inherited `llm-tldr` server both provide code intelligence. Running
  both is within the recommended MCP budget, but if you want a leaner setup, drop one.
- The ruff hook and formatter assume a `uv`-managed project (they call `uv run ruff`).
