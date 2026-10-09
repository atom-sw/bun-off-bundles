# lean-base bundle

A Lean 4 development stack for Claude Code, OpenCode, and Antigravity CLI, deployable with
`bun-off`. It puts the Lean checker, not the assistant's reading of the code, in charge of
deciding whether a file is correct. It extends [`general-dev`](../general-dev/README.md), so
deploying it also installs that bundle's workflow rules, the `context7` and `tldr` servers, and
rtk command-output compression.

## What it deploys

MCP server:

- `lean-lsp`: [lean-lsp-mcp], run through `uvx`. It exposes diagnostics, goal states, hover
  information, and the LeanSearch and Loogle name searches.

Rule (always on):

- `lean`: check after every edit, read the goal before choosing a tactic, report every
  `sorry`, fix linter warnings or suppress them at the declaration with a reason, look names
  up instead of recalling them, and never change the pinned toolchain without asking.

Skills (loaded on demand):

- `lean-lint`: set up and run the project's linters. It proposes `[leanOptions]` entries
  (`linter.missingDocs`, and `weak.linter.mathlibStandardSet` for a Mathlib project) and a
  `lintDriver` for Batteries' environment linter, edits the lakefile only once you agree, then
  reports the warnings from `lake build` and `lake lint` grouped by linter.
- `lean-weave`: build the project and weave its [Verso] literate HTML site with
  `lake query :literateHtml`. It reports errors and every `sorry`, and edits nothing.

Permissions:

- Allows `lake build`, `lake query`, `lake env lean`, `lake lint`, the `--version` probes,
  and (Claude Code) every `lean-lsp` tool.

Settings (Claude Code only):

- Links the Lean FRO skills marketplace ([leanprover/skills]) and enables its `lean` plugin.
  The skills stay in their own repository: Claude Code offers to install the plugin when you
  trust the workspace, and updates it from the source.

## Usage

```bash
boff deploy path/to/bun-off-bundles/lean-base --platform claude
```

## Prerequisites

- `uv`, for `uvx` to launch `lean-lsp-mcp`.
- `rg` (ripgrep), which `lean-lsp-mcp` uses for its `lean_local_search` tool.
- Batteries (directly or through Mathlib) for `lake lint`; the syntax linters need nothing.

## Notes

- Antigravity CLI has no workspace settings or permissions file, so it gets the server, the
  rule, and the skills, but neither the permissions nor the Lean FRO plugin.
- Of the Lean FRO skills, `lean-proof` and `lean-mwe` matter most for everyday work; the rest
  target Lean and Mathlib contributors.
- There is no check-on-edit hook: the `lean-lsp` diagnostics already cover it, linter
  warnings included.
- The bundle ships no linter configuration of its own: linters are set in the project's
  lakefile, which `lean-lint` proposes changes to but never edits unasked.

[lean-lsp-mcp]: https://github.com/oOo0oOo/lean-lsp-mcp
[leanprover/skills]: https://github.com/leanprover/skills
[Verso]: https://verso.lean-lang.org/
