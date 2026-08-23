# frugal-context bundle

Scope discipline for an agentic coding platform, deployable to Claude Code, OpenCode, and
Antigravity CLI with `bun-off`. It focuses context to where the user request pointed
instead of reading the repository to find out.

Not only does this package reduce costs: overflowing the context window with irrelevant details
can worsen a model's performance.

## What it deploys

Rules (always on):

- `scope-ratchet`: start at the files the request names, widen one notch at a time, and say
  which question the current scope could not answer before widening.
- `read-narrowly`: search to locate, then read the slice; prefer a symbol lookup to
  grep-then-read-candidates; cap anything that can produce unbounded output.
- `report-conclusions`: cite `path:line` instead of pasting code, never re-read a file you
  just edited, and preserve the changed-file list and verification commands across a compaction.
- `delegate-deliberately`: delegate a fan-out search, not a targeted change. A subagent that
  has to rediscover what you already know costs more than it saves.

Skill (loaded on demand):

- `context-triage`: what to do when a session is already full. Choose between rewinding,
  clearing, and a focused compaction, measure what is actually in context, and write the part
  that cannot be recovered from disk to a file first.

Output style (Claude Code, defined but not selected):

- `frugal`: No preamble, no recap, no echoed file contents, answers
  measured in sentences. It carries `keep-coding-instructions: true`,
  so it appends to Claude's coding instructions rather than replacing
  them. Select the output style with `/config` for the current session.

Settings (capping only):

- Claude Code: `MAX_MCP_OUTPUT_TOKENS=10000`, the threshold Claude Code itself warns above;
  `CLAUDE_CODE_GLOB_NO_IGNORE=false`, so `Glob` honors `.gitignore`;
  `CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0`, so an idle session stops resending its whole context
  to ask whether you are still there.
- OpenCode: `tool_output.max_lines` and `max_bytes` lowered, so oversized tool output is
  truncated to disk and returned as a preview; `compaction.prune` switched on, which drops
  superseded tool output from long conversations and ships off by default.

## What it deliberately omits

- **No Claude `PreToolUse` hook.** `commons-dev` already sets
  `settings.claude.hooks.PreToolUse` to use `rtk`'s command-output
  filter; duplicating it here would interfere with `commons-dev`'s
  setup. Install the two bundles alongside instead.
- **No settings that could change behavior.** These are worth setting per
  project, by hand, once you know the project:
  - `CLAUDE_CODE_SUBAGENT_MODEL=haiku` puts every subagent on a cheap model, but it overrides
    the model any other bundle's agents declare.
  - `BASH_MAX_OUTPUT_LENGTH` is already at its frugal value; raising it costs context.
  - `MAX_THINKING_TOKENS` has no effect on current models, which use adaptive reasoning. Use
    `/effort` instead.
  - On OpenCode, `small_model` and `subagent_depth` are install-specific or already frugal.
  - Leave `ENABLE_TOOL_SEARCH` on. Deferred MCP tool definitions are the frugal default.
- **No `globs:` on any rule.** Only Claude Code can scope a rule, and a path-scoped rule drops
  out of context after a compaction until a matching file is read again.
- **No auto-selected output style.** Selecting one is a per-session choice, not a project one.

## How it relates to commons-dev

The two are complementary and combine without conflict. `commons-dev` compresses what tool calls
*return*: `rtk` on the command line, the Dynamic Context Pruning plugin on OpenCode, and a broad
`context-management` rule. This bundle governs what the assistant *reads and writes* in the
first place, which is upstream of any compression.

Every rule name here is distinct from `context-management`, `precise-context`, and
`explore-then-code`, so stacking the two prints no shadow warning and drops nothing.

## Measuring the difference

- Claude Code: `/context` for a breakdown of what is in the window, `/usage` for token totals
  attributed to skills, subagents, plugins, and individual MCP servers.
- Any platform: `npx ccusage@latest` reads the local session logs and reports token use by day
  and by session.

## Usage

```
boff deploy path/to/bun-off-bundles/frugal-context --platform claude
boff deploy path/to/bun-off-bundles/frugal-context --platform opencode
boff deploy path/to/bun-off-bundles/frugal-context --platform antigravity
```

Combine it with whatever else you deploy:

```
boff deploy path/to/bun-off-bundles/commons-dev path/to/bun-off-bundles/frugal-context \
    --platform claude
```

On Antigravity CLI the four rules are inlined into `GEMINI.md` and the skill deploys as usual.
The slash command and the output style are scoped away from it, and the settings block names
only Claude Code and OpenCode, so an Antigravity deploy is warning-free rather than noisy.
