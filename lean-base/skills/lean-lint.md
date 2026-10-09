---
name: lean-lint
description: "Set up and run the linters of a Lean 4 project: the syntax linters enabled through `[leanOptions]` in the lakefile, and the Batteries environment linter behind `lake lint`. Use when the user asks to lint a Lean project, enable or configure its linters, or review its linter warnings."
---

# Set up and run Lean linters

Lean has two kinds of linter. **Syntax linters** run while a file elaborates and report
warnings through `lake build` and the language server; options turn them on. The
**environment linter** from Batteries (`#lint`, `lake lint`) inspects finished declarations:
missing docstrings, unused arguments, `simp` lemmas in the wrong normal form.

## Procedure

1. **Read the configuration.** Open `lakefile.toml` (or `lakefile.lean`) and note the
   `[leanOptions]` table, the `lintDriver` field, and whether the project requires Mathlib or
   Batteries (Mathlib brings Batteries with it).
2. **Propose what to enable, and ask before editing the lakefile.** It is project
   configuration, and every option below can surface many warnings at once. Suggest only what
   fits the project:

   ```toml
   lintDriver = "batteries/runLinter"     # `lake lint` runs the Batteries environment linter

   [leanOptions]
   linter.missingDocs = true              # core: every public declaration needs a docstring
   weak.linter.mathlibStandardSet = true  # Mathlib projects: Mathlib's standard syntax linters
   ```

   `lintDriver` is a package-level field: put it above the first table. `lake new <name> math`
   sets `weak.linter.mathlibStandardSet` itself; the `weak.` prefix makes Lean ignore the
   option in files that do not import Mathlib, which would otherwise fail on an unknown option.
   `lintDriver` and `weak.linter.mathlibStandardSet` need Batteries and Mathlib respectively:
   do not add a dependency to get them without asking.
3. **Run the syntax linters** with `lake build`, and collect the linter warnings: the
   message names the option that controls it (`linter.<name>`).
4. **Run the environment linter** with `lake lint` when a `lintDriver` is set. With no
   arguments, `runLinter` lints the root modules of the default targets. For a single file,
   add `#lint` at its end, read the output with `lean_diagnostic_messages`, then remove it.
5. **Report** the warnings grouped by linter, with file and line, and propose a fix for each.
   Fix only what the user agrees to.

## Guardrails

- Fix the code, not the linter. A deliberate exception is suppressed at its declaration with
  a reason (`set_option linter.<name> false in`, `@[nolint <linter>]`), never by turning the
  linter off in `[leanOptions]`.
- Do not run `lake lint -- --update`: it rewrites `nolints.json` to accept every current
  failure.
- Do not change `lean-toolchain` or dependency versions to get a linter.
