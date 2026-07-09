# Python type checking

Static types are part of "done". Run the type checker before declaring a change complete.

- Run the project's type checker (pyright or basedpyright) over the code you changed and
  resolve every error it reports.
- Fix the underlying type problem. Do not paper over it with `# type: ignore`, an
  unjustified `Any`, or a blanket `cast`. If an ignore is genuinely required, scope it to
  the specific rule and add a one-line reason.
- Keep public APIs precisely typed: prefer concrete types and protocols over `Any`.
