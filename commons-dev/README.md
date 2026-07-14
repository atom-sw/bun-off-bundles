# commons-dev bundle

The shared, language-agnostic baseline for AI-assisted development, deployable to Claude Code
and OpenCode with `bun-off`. Other bundles extend this one, so its rules and integrations reach
every stack built on top of it.

## What it deploys

Rules (concise, one concern each, drawn from the Claude Code and OpenCode best-practice guides):

- `verify-your-work`: close the loop with a runnable check and show the evidence.
- `writing-tests`: parametrize over near-duplicate tests, never repeat a literal, test behavior.
- `lint-exceptions`: suppress lint locally with a rationale, not by loosening global config.
- `explore-then-code`: read and reuse before writing; keep diffs minimal.
- `match-project-conventions`: defer to an existing project's toolchain and conventions over these defaults.
- `precise-context`: ground work in real files; ask only on genuine ambiguity.
- `vcs-etiquette`: use `gh`, branch before committing, commit only when asked.
- `commit-conventions`: write the commit summary in Conventional Commits format (types, scope, breaking-change marker).
- `security-basics`: no hard-coded secrets, validate input, least privilege.
- `documentation-style`: active voice, colons over dashes, disciplined arrows and emojis.
- `writing-docs`: document the non-obvious, keep docs in sync, lead with the point.
- `context-management`: keep the context window focused via subagents, `/clear`, and scoped `/compact`.

Skill (loaded on demand):

- `doc-check`: audit documentation against the implementation, fix drift, and tighten the prose.

MCP server:

- `context7`: up-to-date library and framework documentation (keyless HTTP endpoint).

## Context management

On OpenCode, this bundle enables the Dynamic Context Pruning plugin
(`@tarquinen/opencode-dcp`), which prunes redundant tool results from long conversations.
Claude Code has no equivalent plugin and needs none: it prunes stale tool results natively
via microcompaction. The `context-management` rule captures the habits that help on both.

The bundle also activates [rtk](https://github.com/rtk-ai/rtk), a CLI proxy that compresses
verbose command output (git, tests, build, lint) before it reaches the model, at the source
rather than after the fact. rtk truncates output but keeps full output on failure via its
`tee` mode, so error detail stays recoverable.

rtk's effective integrations are global, so a `post_install` hook activates it globally
regardless of deploy scope:

- **Claude** and **OpenCode**: the hook runs `rtk init -g` (with `--opencode` when OpenCode is
  targeted, which installs both the Claude hook and the OpenCode plugin). This wires in rtk's
  interception: a `PreToolUse` hook for Claude and a plugin for OpenCode. Only the global init
  installs these; a workspace-local init would write an inert instruction note and no hook.
  OpenCode loads a newly installed plugin only after a **restart**.
- **Antigravity**: `agy` has no rtk interception hook (rtk's `--agent antigravity` writes to
  `.agents/rules/`, which `agy` never loads), so the bundle ships an `rtk-usage` rule scoped to
  antigravity. boff inlines it into `GEMINI.md`, where `agy` reads it, and the agent applies rtk
  to its own commands.

You do not need to re-run `rtk init` periodically: the Claude hook and OpenCode plugin resolve
rtk on `PATH` and survive version bumps. Re-init only matters after a major rtk upgrade that
changes the hook or plugin contract.

## Toolchain

The bundle declares rtk in `mise/mise.toml` and installs it on deploy: a `mise-install`
`post_install` hook runs `mise trust` + `mise install`, and a `session_start` event hook
refreshes it each session (both no-ops once the tool is present). These drop-ins land under
`.config/mise/conf.d/` and are dedicated to the bundle's tooling: they are independent of any
`mise.toml` the edited project uses for its own runtime. If mise itself is not installed, the
hook skips gracefully and prints a one-time install hint instead of failing the deploy.

## Usage

Deploy into the current workspace for one or both platforms:

```
boff deploy path/to/bun-off-bundles/commons-dev --platform claude
boff deploy path/to/bun-off-bundles/commons-dev --platform opencode
```

Most users deploy a bundle that extends this one instead. `general-dev` adds the `llm-tldr`
code-intelligence server, and language-specific stacks (such as `python` and `python-scripts`)
build on top, so deploying any of them pulls in these rules and integrations automatically.
