---
name: lean-weave
description: "Check a Lean project and weave its literate HTML site with Verso (`lake query :literateHtml`). Use when the user asks to build, render, weave, preview, or publish the HTML of a Lean project that depends on Verso."
---

# Weave a Verso literate site

1. Confirm the project depends on Verso: `lakefile.toml` (or `lakefile.lean`) requires
   `verso`. If not, stop and tell the user; do not add the dependency without asking.
2. Run `lake build`. On errors, report them with file and line and stop: a site built from
   broken sources is misleading.
3. Search the sources for `sorry` (`grep -rn "sorry" --include="*.lean"` outside `.lake/`)
   and list each occurrence; the site still builds, but the user must know.
4. Run `lake query :literateHtml`. The last line of the output is the site directory. The
   first run compiles Verso and can take several minutes: tell the user before you start.
5. Report the path to `index.html` in that directory, and any warnings Verso printed.

Site options (module order, landing page, hidden commands) live in `literate.toml` at the
workspace root. See https://verso.lean-lang.org/doc/latest/Literate-Programming/.

## Guardrails

- Do not edit `.lean` sources in this skill: it builds and reports only.
- Do not run `lake update` or change the Verso version: it must match `lean-toolchain`.
