# 🚉 Bun Off Bundles

Ready-to-deploy AI coding-assistant stacks for [Bun Off](https://github.com/atom-sw/bun-off), a
tool that installs rules, MCP servers, skills, slash commands, and hooks from a single
`boff.yaml` manifest into each platform's native config locations.

Each directory here is a manifest folder you can deploy as-is, or extend with your own.

## 📦 The bundles

| Bundle | What it deploys |
|---|---|
| [`general-dev`](general-dev/README.md) | A language-agnostic baseline: workflow rules, the `context7` and `llm-tldr` MCP servers, `rtk` command-output compression, and a `doc-check` skill. |
| [`python`](python/README.md) | A Python stack: `uv`, `ruff`, type-checking and `pytest` rules, the `serena` MCP server, a ruff format-on-edit hook, and a packaging skill. |

`python` extends `general-dev`, so deploying it installs the baseline rules and servers too.

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
subtree and caches it:

```yaml
meta:
  name: my-stack
  description: Our team's Python stack.

extends: https://github.com/atom-sw/bun-off-bundles.git/python@v0.1.0

rules:
  - house-style
```

The `.git` segment splits the repo URL from the in-repo subdirectory, and the trailing `@<ref>`
pins a tag, branch, or commit. Your own manifest wins on any name it redefines. See
[Extending manifests](https://github.com/atom-sw/bun-off#-extending-manifests) for the merge
semantics.

> ⚠️ Resolving a remote `extends:` runs `git` against the referenced URL. Only extend manifests
> you trust.
