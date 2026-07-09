# Version-control etiquette

Treat the repository history as a shared, permanent record.

- Use the `gh` CLI for GitHub operations (issues, pull requests, reviews): it is the most
  context-efficient path and avoids unauthenticated rate limits.
- Commit or push only when the user asks. Never commit automatically after a change.
- Never commit directly to the default branch: create a topic branch first.
- Write descriptive commit messages: a Conventional Commits summary line (see
  `commit-conventions`) plus a body explaining why the change exists, not just what changed.
- Keep secrets, build artifacts, and local scratch files out of commits.
