# Match the project's conventions

These rules describe a preferred default for new work. An existing project's own conventions
and toolchain take precedence.

- Detect what the project already uses before you act: its `pyproject.toml`, lockfiles, CI
  config, `Makefile`, and formatter, linter, and test configuration. Follow the established
  choice, even when it differs from these rules.
- Do not introduce a new tool, framework, or convention into an existing project without a
  reason and the user's agreement. Apply the opinionated defaults here for greenfield work, or
  when the user asks for them.
- When a project convention conflicts with a rule, follow the project and say so.
