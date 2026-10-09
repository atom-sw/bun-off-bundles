# Working with Lean 4

Treat the Lean checker, not your own reading, as the judge of whether code is correct.

- After every edit to a `.lean` file, check it: `lean_diagnostic_messages` from the lean-lsp
  MCP server, or `lake build` when the server is unavailable.
- Read the goal state (`lean_goal`) before you choose the next tactic; do not guess it.
- Never leave a `sorry` silently: report each one you add or find, with its location.
- Treat a linter warning as a finding to fix, not noise. When a warning is deliberate,
  suppress it at the declaration with a comment saying why: `set_option linter.<name> false in`
  for a syntax linter, `@[nolint <linter>]` for a Batteries environment linter. Never turn a
  linter off in `[leanOptions]` to silence one case.
- Look up names before you use them (`lean_hover_info`, LeanSearch, Loogle, context7). Lean 4
  core and Mathlib names change between versions; do not rely on memory.
- Respect the pinned toolchain in `lean-toolchain`; never upgrade Lean or a dependency
  without asking.
- Prefer `lakefile.toml` over `lakefile.lean` for new projects.
