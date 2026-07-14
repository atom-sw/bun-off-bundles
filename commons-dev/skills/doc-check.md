---
name: doc-check
description: Audit documentation (README, docs/, CLI help, examples) against the implementation, fix drift, and tighten the prose. Use when docs may be stale, before a release, or when asked to review or update documentation.
---

# Documentation check

Bring documentation back in sync with the code, then tighten its language. Run the steps in
order and report what changed.

## 1. Scope

- Use the file the user names. Otherwise default to `README.md`, then `docs/` and top-level
  docs such as `CONTRIBUTING`.
- Note stale module or package docstrings you encounter, but focus on prose documentation.

## 2. Check against the implementation

Verify every documented claim against reality, not memory:

- Commands, flags, and subcommands: run the tool's `--help` (or read its argument parser).
- Config keys, environment variables, and file paths: confirm they exist in the code.
- API signatures, exported names, and types: read the referenced source.
- Install and setup steps: confirm they match the current build and dependency setup.
- Examples and code blocks: run them where it is safe to do so.

## 3. Classify each discrepancy

- **Reference drift** (a renamed flag, moved path, changed signature, or removed or added
  feature): fix it in the documentation to match the code.
- **Behavioral contradiction** (the doc says behavior X should happen, but the code does Y):
  do not rewrite the doc to match the code. Flag it as a possible bug and ask the user which
  side is authoritative. Rewriting silently would codify a bug into the docs.

## 4. Update the documentation

- Make minimal, accurate edits that correct the drift.
- Document user-facing behavior that exists but is undocumented.
- Remove documentation for features that no longer exist.
- Never document a feature that does not exist.

## 5. Improve the prose

Tighten the language where it has drifted or reads unclearly, preserving the meaning:

- Prefer the active voice and lead with the point.
- Prefer a concrete example or command over a paragraph of prose.
- Follow the project's documentation conventions: colons over dashes, arrows only for
  sequences, emojis sparingly and only in a README.
- Do not churn prose that is already clear and correct.

## 6. Verify and report

- Re-read the updated documentation and re-run the documented examples.
- Confirm every remaining claim matches the code.
- Summarize what you changed and why, and list any behavioral contradictions you flagged.

## Guardrails

- Keep changes to the documentation unless the user approves changing the code.
- For a root `README.md`, follow the project's emoji policy.
