# general-dev bundle

A language-agnostic development baseline that adds project-wide code intelligence on top of
[`commons-dev`](../commons-dev/README.md). Deployable to Claude Code and OpenCode with `bun-off`.

It extends `commons-dev`, so deploying it also installs that bundle's baseline rules, the
`context7` documentation server, rtk command-output compression, and the `doc-check` skill.

## What it adds

MCP server:

- `tldr`: compressed code-intelligence context for exploring a codebase, from
  [`tldr-code`](https://github.com/parcadei/tldr-code). It reads the project source directly, so
  it needs no index or warm-up step: it answers queries (AST, call graph, data flow, security,
  and quality) on demand over MCP.

Toolchain:

- A `mise/mise.toml` declaring `cargo-binstall` and `cargo:tldr-cli`, which provide the server's
  `tldr-mcp` binary (plus the `tldr` CLI). mise's cargo backend uses `cargo-binstall` to fetch
  tldr-code's precompiled release binaries, so no Rust toolchain is needed to build from source.
  The prebuilt binaries ship default features, so the optional `semantic` natural-language search
  is not included. The drop-in merges under `.config/mise/conf.d/` with commons-dev's rtk drop-in
  and is installed by the inherited `mise-install` hook.

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
