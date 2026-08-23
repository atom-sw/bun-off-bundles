# Read narrowly

Locate first, then read the smallest slice that answers the question.

- Search for the symbol before opening anything, and read only the region the search
  points at. Read a file whole when it is short or you are about to rewrite most of it.
- Prefer a symbol lookup to grep-then-read-candidates wherever a language server or a
  code-intelligence server is available. One definition jump replaces several guesses.
- Cap anything that can produce unbounded output: `rg -l`, `rg -c`, `head -n`,
  `git log -n`, `--max-count`. When a search truncates, narrow the pattern instead of
  running it again wider.
- Prefer a CLI to an MCP server for the same job, `gh` over a GitHub server for example.
  A CLI adds no per-tool listing to the session.
