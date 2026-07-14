# general-dev bundle

A language-agnostic development baseline that adds project-wide code intelligence on top of
[`commons-dev`](../commons-dev/README.md). Deployable to Claude Code and OpenCode with `bun-off`.

It extends `commons-dev`, so deploying it also installs that bundle's baseline rules, the
`context7` documentation server, rtk command-output compression, and the `doc-check` skill.

## What it adds

MCP server:

- `llm-tldr`: compressed code-intelligence context for exploring a codebase. A `post_install`
  hook runs `llm-tldr warm .` to build its semantic index for the project (skipped with a hint
  if the binary is absent).

Toolchain:

- A `mise/mise.toml` declaring `pipx:llm-tldr`, which provides the server's binaries. It merges
  under `.config/mise/conf.d/` with commons-dev's rtk drop-in and is installed by the inherited
  `mise-install` hook (which runs before `tldr-warm`).

## Usage

Deploy into the current workspace for one or both platforms:

```
boff deploy path/to/bun-off-bundles/general-dev --platform claude
boff deploy path/to/bun-off-bundles/general-dev --platform opencode
```

Language-specific bundles (such as `python`) extend this one, so deploying them pulls in
these servers and the inherited commons-dev baseline automatically. For a leaner stack without
project-wide indexing (for example when working on standalone scripts), deploy `commons-dev`
directly, or a bundle that extends it (such as `python-scripts`).
