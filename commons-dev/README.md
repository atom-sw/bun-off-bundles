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
- `context-management`: keep the context window focused via subagents, `/clear`, and scoped `/compact`.

Skill (loaded on demand):

- `doc-check`: audit documentation against the implementation, fix drift, and tighten the prose.

MCP server:

- `context7`: up-to-date library and framework documentation (keyless HTTP endpoint).

Command-output compression (see [Context management](#context-management)):

- an rtk `PreToolUse` hook on Claude, and the rtk plugin on OpenCode.

## Prose style moved out in 0.3.0

`documentation-style` and `writing-docs` are no longer here. They now live in the
[`writing`](../writing/README.md) bundle, together with an American-English rule and a
plain-technical-writing skill, because prose style is not specific to a project and is better
installed once per machine:

```bash
boff deploy path/to/bun-off-bundles/writing --platform claude --global
```

`commons-dev` keeps only coding discipline. If you deployed 0.2.0 and want the prose rules
back, deploy `writing` as well; a re-deploy of `commons-dev` removes the two rule files it no
longer produces.

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

Bundle versions up to 0.1.0 installed rtk globally instead. If you ran one of those, see
[Upgrading to 0.2.0](#upgrading-to-020-removing-a-global-rtk-install).

## Upgrading to 0.2.0: removing a global rtk install

Bundle versions up to 0.1.0 activated rtk by running `rtk init -g`, which writes to your
**global** config. Since the rtk binary comes from the bundle's per-project mise drop-in, that
left a global hook pointing at a binary only some projects have. The result: in every project
that does not deploy this bundle, each Bash tool call fired the hook, got `rtk: not found`, and
failed with exit 127.

Version 0.2.0 wires rtk up workspace-locally instead and never touches your global config. The
old artifacts are not removed automatically, so a deploy detects them and prints an advisory
naming each one. Clear them once, on each machine.

**1. Preview what will be removed.**

```bash
rtk init -g --uninstall --dry-run
```

```
[dry-run] would remove RTK.md: ~/.claude/RTK.md
[dry-run] would remove CLAUDE.md (empty after cleanup): ~/.claude/CLAUDE.md
[dry-run] would remove RTK hook entry from ~/.claude/settings.json
[dry-run] would remove OpenCode plugin: ~/.config/opencode/plugins/rtk.ts
```

Read that output before going further. `rtk init -g` had added an `@RTK.md` line to
`~/.claude/CLAUDE.md`, and the uninstall **deletes that whole file** when stripping the line
leaves it empty. If your `~/.claude/CLAUDE.md` holds anything else, skip step 2 and remove the
four artifacts by hand instead: the rtk entry under `hooks.PreToolUse` in
`~/.claude/settings.json`, the `@RTK.md` line in `~/.claude/CLAUDE.md`, the file
`~/.claude/RTK.md`, and the file `~/.config/opencode/plugins/rtk.ts`.

**2. Remove them.**

```bash
rtk init -g --uninstall
```

**3. Restart OpenCode**, so it drops the global plugin and loads the workspace-local one.

**4. Redeploy the bundle** in each project that should keep rtk:

```bash
boff deploy path/to/bun-off-bundles/commons-dev --platform claude --platform opencode
```

Projects you do not redeploy simply run without rtk, which is the point: no more errors in
workspaces that never asked for it.

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
