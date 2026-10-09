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
- The nine Lean FRO skills from [leanprover/skills], fetched at deploy time and pinned to one
  commit: `lean-proof`, `lean-mwe`, `lean-bisect`, `lean-setup`, `lean-pr`, `mathlib-build`,
  `mathlib-pr`, `mathlib-review`, and `nightly-testing`. They deploy to all three platforms.

Permissions:

- Allows `lake build`, `lake query`, `lake env lean`, `lake lint`, the `--version` probes,
  and (Claude Code) every `lean-lsp` tool.

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
  rule, and the skills, but not the permissions.
- Deploying needs network access to GitHub, to fetch the Lean FRO skills. Bun Off caches the
  clone, and fetches it once per run.
- Upstream's `lean-setup` declares `name: lean4-setup` in its frontmatter, so each deploy warns
  that it deploys under the folder name, `lean-setup`.
- Earlier versions of this bundle linked the Lean FRO marketplace plugin on Claude Code instead.
  Redeploying removes those settings; if you installed the plugin, uninstall it with
  `claude plugin uninstall lean@leanprover` so the skills do not load twice.
- Of the Lean FRO skills, `lean-proof` and `lean-mwe` matter most for everyday work; the rest
  target Lean and Mathlib contributors.
- There is no check-on-edit hook: the `lean-lsp` diagnostics already cover it, linter
  warnings included.
- The bundle ships no linter configuration of its own: linters are set in the project's
  lakefile, which `lean-lint` proposes changes to but never edits unasked.

[lean-lsp-mcp]: https://github.com/oOo0oOo/lean-lsp-mcp
[leanprover/skills]: https://github.com/leanprover/skills
[Verso]: https://verso.lean-lang.org/
