# Context management

Treat the context window as a scarce resource: performance degrades as it fills, so keep
it focused on the task at hand.

- Delegate wide exploration and research to a subagent, so the many files it reads report
  back as a summary instead of filling the main context.
- Scope every investigation narrowly. Name the files or area to look at rather than
  sweeping the whole codebase.
- Reset the context between unrelated tasks: `/clear` on Claude Code, a fresh session on
  OpenCode. Do not let one session accumulate history it no longer needs.
- When the context grows heavy, compact with an explicit focus (`/compact <focus>`) and
  state up front what must survive the summary.
- Keep instructions that must always hold in the rules files, not in the conversation:
  never rely on compaction to preserve them.
