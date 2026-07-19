# 🚉 Bun Off Bundles

Ready-to-deploy AI coding-assistant stacks for [Bun Off](https://github.com/atom-sw/bun-off), a
tool that installs rules, MCP servers, skills, slash commands, and hooks from a single
`boff.yaml` manifest into each platform's native config locations.

Each directory here is a manifest folder you can deploy as-is, or extend with your own.

## 📦 The bundles

| Bundle | What it deploys |
|---|---|
| [`commons-dev`](commons-dev/README.md) | The shared language-agnostic baseline: workflow rules, the `context7` docs server, `rtk` command-output compression, and a `doc-check` skill. |
| [`general-dev`](general-dev/README.md) | `commons-dev` plus the `tldr` (tldr-code) MCP server for project-wide code intelligence. |
| [`python`](python/README.md) | A Python stack: `uv`, `ruff`, type-checking and `pytest` rules, the `serena` MCP server, a ruff format-on-edit hook, and a packaging skill. |
| [`python-scripts`](python-scripts/README.md) | A lightweight stack for standalone scripts: stdlib-first rules, `unittest` testing, a ruff format-on-edit hook, and a `new-script` scaffolding skill. |

The bundles form an extension tree, so deploying one installs everything it builds on:

```
commons-dev
├── general-dev ── python
└── python-scripts
```

`general-dev` extends `commons-dev`; `python` extends `general-dev`; `python-scripts` extends
`commons-dev` directly (a leaner base, without the project-wide `tldr` code-intelligence server).

## 🚀 Usage

Clone this repo, then deploy a bundle into your project's workspace:

```bash
git clone https://github.com/atom-sw/bun-off-bundles.git
cd path/to/your/project
boff deploy path/to/bun-off-bundles/python --platform claude
```

Pass `--platform` once per target. The bundles support `claude` and `opencode`; `antigravity`
works too, minus the artifacts that platform has no workspace target for.

## 🧬 Extending a bundle

A manifest can name a bundle from this repo directly, without cloning it. Bun Off fetches the
subtree when deploying:

```yaml
meta:
  name: my-stack
  description: Our team's Python stack.

extends: https://github.com/atom-sw/bun-off-bundles.git/python

rules:
  - house-style
```

The `.git` segment splits the repo URL from the in-repo subdirectory,
and the trailing optional `@<ref>` pins a tag, branch, or commit. Your
own manifest wins on any name it redefines. See [Extending
manifests](https://github.com/atom-sw/bun-off#-extending-manifests)
for the merge semantics.

> ⚠️ Resolving a remote `extends:` runs `git` against the referenced URL. Only extend manifests
> you trust.
