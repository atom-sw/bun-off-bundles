# bun-off-bundle bundle

A single skill that teaches the assistant to author Bun Off bundles. Deploy it in the
repository where you keep your own bundles, then describe the stack you want and let the
assistant build the manifest folder.

It stands alone: unlike the other bundles here, it extends nothing, because a workspace for
authoring manifests has no reason to inherit a general coding baseline. Deploy it alongside
another bundle if you want both:

```
boff deploy path/to/bun-off-bundles/commons-dev path/to/bun-off-bundles/bun-off-bundle --platform claude
```

## What it deploys

Skill:

- `bun-off-bundle`: the whole authoring reference in one file. How to interview the user before
  writing anything; which artifact type fits which intent (a standing constraint is a rule, a
  procedure is a skill); the folder layout, including both forms a skill takes on disk and what
  a skill folder ships; an annotated `boff.yaml` reference; per-artifact detail with the on-disk
  target for each of Claude Code, OpenCode, and Antigravity CLI; the
  platform capability matrix, marking what a platform drops with a warning and what is a hard
  error; `available_on:`, `extends:`, and the merge rules; house style for writing rules,
  skills, and slash commands; a validation pass; and a common-mistakes checklist.

Slash command:

- `/bun-off-bundle` (OpenCode only): an explicit entry point that loads the skill and passes
  along your description of the bundle. Claude Code invokes the skill directly, so it needs no
  command of its own.

The skill is self-contained. An assistant using it needs no access to the `bun-off` source, and
the public [README](https://github.com/atom-sw/bun-off) stays available for any detail the
skill omits.

## What it deliberately omits

- **No rules.** Bundle authoring is an occasional task, and a rule would load into every
  session whether or not you are writing a manifest. The skill costs nothing until it triggers.
- **No MCP server, no toolchain, no `mise.toml`.** Nothing to install: `boff` itself is the
  only prerequisite, and the skill works without it (it falls back to a manual checklist).
- **No language or domain assumptions.** The examples use neutral placeholders, so the skill
  applies equally to a bundle for Rust, for technical writing, or for a data pipeline.

## Usage

```
boff deploy path/to/bun-off-bundles/bun-off-bundle --platform claude
boff deploy path/to/bun-off-bundles/bun-off-bundle --platform opencode
boff deploy path/to/bun-off-bundles/bun-off-bundle --platform antigravity
```

On Antigravity CLI the slash command is skipped with a warning, as that platform has no
workspace target for one; the skill deploys normally.

## Keeping it current

The skill documents `bun-off` 0.3.1 and names that version in its opening lines. When `boff`
grows an artifact type, a platform, or an event, update `skills/bun-off-bundle.md`: the
`boff.yaml` reference, the per-artifact section, the platform capability matrix, and the
common-mistakes checklist.
