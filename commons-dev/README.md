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

Command-output compression (see [Context management](#context-management)):

- an rtk `PreToolUse` hook on Claude, and the rtk plugin on OpenCode.

## Context management

On OpenCode, this bundle enables the Dynamic Context Pruning plugin
(`@tarquinen/opencode-dcp`), which prunes redundant tool results from long conversations.
Claude Code has no equivalent plugin and needs none: it prunes stale tool results natively
via microcompaction. The `context-management` rule captures the habits that help on both.

The bundle also activates [rtk](https://github.com/rtk-ai/rtk), a CLI proxy that compresses
verbose command output (git, tests, build, lint) before it reaches the model, at the source
rather than after the fact. rtk truncates output but keeps full output on failure via its
`tee` mode, so error detail stays recoverable.

The integration is **workspace-local on every platform**. The bundle wires it up itself rather
than running `rtk init`, whose effective modes all write to your global config:

- **Claude**: a `PreToolUse` hook on `Bash`, deployed into the workspace's
  `.claude/settings.json` through the manifest's `settings:` block. It rewrites each command
  through `rtk hook claude` before the tool runs.
- **OpenCode**: the rtk plugin, deployed to `.opencode/plugins/rtk.js`. `rtk init --opencode`
  refuses a workspace-local install ("OpenCode plugin is global-only"), so the bundle vendors
  the file under `plugins/rtk-opencode/`. It is a thin delegator to `rtk rewrite`, which holds
  all the rewrite logic, so it survives rtk version bumps. OpenCode loads a newly installed
  plugin only after a **restart**.
- **Antigravity**: `agy` has no rtk interception point (rtk's `--agent antigravity` writes to
  `.agents/rules/`, which `agy` never loads), so the bundle ships an `rtk-usage` rule scoped to
  antigravity. boff inlines it into `GEMINI.md`, where `agy` reads it, and the agent applies rtk
  to its own commands.

Keeping all of this in the workspace matters because the rtk **binary** is workspace-local too:
it comes from the bundle's mise drop-in (see [Toolchain](#toolchain)). A global hook paired with
a per-project binary fails in every project that does not deploy this bundle. Two consequences:

- Other projects are untouched. rtk stays opt-in, one deploy at a time.
- `boff clean` removes the integration completely, since every piece is a tracked boff artifact.

The Claude hook is guarded with `command -v rtk` and fails open, so a workspace whose toolchain
is not installed yet runs its commands unwrapped instead of erroring. The OpenCode plugin
disables itself the same way.

> **Upgrading from an earlier version of this bundle?** It ran `rtk init -g`, which patched
> `~/.claude/settings.json`, `~/.claude/RTK.md`, `~/.claude/CLAUDE.md`, and
> `~/.config/opencode/plugins/rtk.ts`. A deploy now detects those leftovers and prints how to
> remove them: `rtk init -g --uninstall`. Dry-run it first, because it also deletes
> `~/.claude/CLAUDE.md` when stripping the `@RTK.md` line leaves that file empty.

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

Most users deploy a bundle that extends this one instead. `general-dev` adds the `tldr`
(tldr-code) code-intelligence server, and language-specific stacks (such as `python` and `python-scripts`)
build on top, so deploying any of them pulls in these rules and integrations automatically.
