# Commit message conventions

Write the commit summary (the first line) in Conventional Commits format. The detailed body
below it stays free-form prose, exactly as before.

Summary shape: `<type>(<optional scope>): <description>`

- `type` is one of: `feat` (a new feature), `fix` (a bug fix), `docs`, `style` (formatting, no
  code change), `refactor`, `perf`, `test`, `build`, `ci`, `chore` (maintenance), `revert`.
- `scope` is optional and names the affected area in parentheses, for example `fix(parser):`.
- `description` is a concise, imperative, lowercase summary with no trailing period, aiming for
  under about 50 characters.
- Mark a breaking change with `!` before the colon (`feat!:` or `feat(api)!:`), and explain it
  in a `BREAKING CHANGE: <detail>` footer in the body.

Examples:

```
feat(auth): add token refresh endpoint
fix: prevent crash on empty input
docs(readme): clarify the install steps
refactor(core)!: drop the legacy config loader
```

Only the summary uses this format. Keep the body as before: a blank line after the summary,
then the detailed explanation of why the change exists.
