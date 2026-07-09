# Lint exceptions

Suppress a lint warning at the line where it fires, not by loosening the global
configuration. A local suppression is visible in review and scoped to the one case that
needs it, so it never silences the same warning elsewhere by accident.

- Suppress at the site with the linter's inline directive: ruff or flake8 `# noqa: <code>`,
  pylint `# pylint: disable=<name>`, eslint `// eslint-disable-next-line <rule>`, TypeScript
  `// @ts-expect-error`.
- Name the specific rule or code, never a blanket suppression: silence only the one warning,
  so unrelated issues still surface.
- State a brief rationale on the same line or just above, explaining why relaxing the rule is
  safe here. A suppression without a reason is not acceptable.
- Prefer fixing the code over suppressing the warning when the fix is reasonable. Reach for a
  suppression when the lint is a false positive or the flagged pattern is deliberate.
- Change the global lint configuration only when the same exception recurs across many places.
  One justified project-wide relaxation beats scattering the identical suppression everywhere.
