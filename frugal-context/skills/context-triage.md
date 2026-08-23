---
name: context-triage
description: Decide what to save and whether to clear, compact, or rewind when a session's context window is filling up. Use when context is running low, at a natural break in a long task, or when repeated attempts keep failing.
---

# Context triage

Reclaim a session's context without losing the work. Choose the move first, then save what
the move would destroy.

## 1. Choose the move

Pick the first case that applies:

- **You are abandoning a path you just explored.** Rewind. On Claude Code, `/rewind`
  truncates back to a prefix that is already cached, which makes it the cheapest option.
- **The next task is unrelated to this one.** Clear. `/clear` on Claude Code, a new session
  on OpenCode. Clearing costs nothing, whereas compaction is itself a large request that
  reads the whole conversation before summarizing it.
- **The same task has to continue.** Compact with an explicit focus,
  `/compact <what must survive>`, and only at a natural break, never mid-edit.

Save first (step 3) before you clear or compact. When none of the three cases is obviously
right, measure before choosing.

## 2. Measure what is actually in context

- Claude Code: `/context` for a breakdown with optimization hints, and `/usage` for token
  totals attributed to skills, subagents, plugins, and individual MCP servers.
- OpenCode: the session footer reports context use, and the `compaction` block in
  `opencode.json` controls when it triggers.
- Any platform: `npx ccusage@latest` reads the local session logs and reports token use by
  day and by session.

## 3. Save what cannot be recovered

Write a short note to a file in the repository. Do not trust a summary to carry it:

- The files you changed and the exact commands that verify them.
- Decisions taken and rejected, with the reason. Nothing on disk records those.
- The open question and the next step.

Record a path rather than the contents whenever a file already holds the information. Rule
and memory files reload from disk by themselves, so never copy them into the note.

## 4. Restart clean

- Clear, compact, or rewind, then read the note back and carry on.
- After two failed corrections on the same problem, stop and do this instead of adding a
  third attempt to a context already holding the first two.

## Guardrails

- Never compact mid-edit. Finish or revert the change first.
- Never treat a compaction summary as the record. If it matters, it is in the file.
- Do not clear to escape a failing test. Fix or revert it, then clear.
- Do not delete the note when the session ends. The next session starts from it.
