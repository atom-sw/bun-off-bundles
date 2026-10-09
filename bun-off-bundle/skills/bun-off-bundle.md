---
name: bun-off-bundle
description: "Author a bun-off (boff) bundle: a boff.yaml manifest folder that deploys rules, skills, slash commands, agents, MCP servers, permissions, settings, and hooks to Claude Code, OpenCode, and Antigravity CLI. Use when asked to create, extend, review, or fix a bun-off bundle or a boff.yaml manifest."
---

# Authoring a bun-off bundle

Bun Off (`boff`) deploys an AI coding-assistant stack from one `boff.yaml` manifest into each
platform's native config locations. A **bundle** is a folder holding that manifest plus the
content files it lists. Your job here: turn a description of what the stack is for into a
correct, minimal bundle.

This skill is self-contained: everything below is what you need. It documents `bun-off` 0.3.1.
The authoritative reference, should you need a detail this file omits, is
<https://github.com/atom-sw/bun-off> (its `README.md`).

---

## 1. Interview before you write

Ask only what you cannot infer, then proceed. The answers that change the design:

| Question | Why it matters |
|---|---|
| What work does the stack support? | Decides the rules and skills, and their vocabulary. |
| Which platforms? | `claude`, `opencode`, `antigravity`, or all. Antigravity supports a subset. |
| What must the assistant *always* honor vs. do *on request*? | Splits rules from skills. |
| Which external tools, servers, or runtimes does it assume? | Decides `mcp_servers:` and `mise:`. |
| Does it build on an existing bundle? | Decides `extends:`. |

Defaults when the user does not say: target `claude` and `opencode`, add `antigravity` only if
asked; no `extends:`; no `mise:` unless the stack names a tool that must be on `PATH`.

Keep the bundle small. A bundle of four sharp rules and one skill beats a bundle of twenty
rules the assistant will never fully honor.

---

## 2. Choose the artifact type

This is the decision that determines whether the bundle works. Match the intent, not the
format:

| The intent | The artifact | Why |
|---|---|---|
| A standing constraint the assistant must always honor | `rules:` | Loaded into every session unconditionally. |
| A repeatable multi-step procedure, run on request | `skills:` | Loaded only when triggered, so it costs nothing until used. |
| An explicit, user-typed entry point | `slash_commands:` | A `/name` the user invokes deliberately. |
| A sub-task deserving its own context window | `agents:` | A subagent with its own prompt and tool scope. |
| A capability the assistant lacks (a service, a database, an index) | `mcp_servers:` | Adds tools at runtime. |
| A policy on which tools may be used, and how | `permissions:` | Translated to each platform's native syntax. |
| A platform knob Bun Off does not model | `settings:` | Verbatim passthrough into native settings. |
| A deterministic side effect on a runtime event | `event_hooks:` | Runs a shell body after an edit, a command, or at session boundaries. |
| Setup work at deploy time | `hooks.pre_install` / `hooks.post_install` | Python scripts run once, around the deploy. |
| A runtime or CLI the stack needs on `PATH` | `mise:` | A non-destructive `mise` drop-in. |
| A file tree to drop into the workspace verbatim | `plugins:` | Copies a local subtree. |

**Anti-patterns to avoid.**

- **A workflow written as a rule.** Rules load unconditionally and consume context in every
  session. A ten-step release procedure belongs in a skill.
- **A rule covering several concerns.** One concern per rule, so a stack can override or drop
  one without touching the others. Name the rule for the concern.
- **A hook that duplicates a native feature.** If a platform formats, lints, or indexes
  natively, configure that through `settings:` and scope the hook to the platforms that lack
  it. See the format-on-edit split in section 5.
- **An agent where a skill would do.** Reach for an agent only when the work genuinely needs a
  separate context window or a narrower tool scope.
- **Unconditional tooling.** A hook or formatter that fires in every project will annoy users
  in projects that did not opt in. Guard it: check for a config file, or `command -v <tool>`,
  and exit 0 when absent.

---

## 3. Lay out the folder

```
my-bundle/
  boff.yaml           # the manifest (required)
  README.md           # conventional, not read by boff
  rules/              # <name>.md per entry in rules:
  skills/             # per entry in skills:, either <name>.md or a <name>/ folder
                      # holding SKILL.md plus the files that skill ships
  slash_commands/     # <name>.md per entry in slash_commands:
  agents/             # <name>.md per entry in agents: (the system-prompt body)
  mcp_servers/
    raw/
      claude/         # <name>.json, verbatim server config
      opencode/
      antigravity/
  plugins/            # subtrees referenced by plugin install specs
  mise/               # mise.toml files listed under mise:
  hooks/              # <name>.py per lifecycle hook
  event_hooks/        # <name> shell script per event hook that uses script:
```

**Every name listed in `boff.yaml` must have its backing file.** A missing
`rules/<name>.md` is a load error, not a warning. Create only the directories you use.

---

## 4. `boff.yaml` reference

Required: `meta.name` and `meta.description`. Everything else is optional.

```yaml
meta:                              # REQUIRED block
  name: my-stack                   # required
  description: One line, what this stack is for.   # required
  long_description: |              # optional, free-form markdown
    A paragraph for humans browsing the bundle.
  version: "0.1.0"                 # optional
  author: Your Name                # optional
  homepage: https://example.com    # optional

extends: ../base-stack             # optional: one ref, or a list of refs

rules:
  - style                          # short form: just the name
  - name: lint                     # long form
    category: backend              # optional: a subdirectory on disk
    globs: ["**/*.ts"]             # optional: scope to matching files (Claude only)
    available_on: [claude]         # optional: restrict to these platforms

skills:
  - review-checklist               # short or long form, same as rules; the entry looks the
                                   # same whichever of the two on-disk forms you wrote

slash_commands:
  - name: review
    available_on: [claude, opencode]

agents:
  - name: reviewer                 # body at agents/reviewer.md
    description: Read-only code reviewer.       # required
    model: haiku                   # optional: string, or a per-platform map
    mode: subagent                 # optional, OpenCode only
    permissions:                   # optional, same rule shape as below
      allow: [{ tool: read }, { tool: grep }]
      deny:  [{ tool: edit }, { tool: bash }]

mcp_servers:
  - context7                       # needs mcp_servers/raw/<platform>/context7.json
  - name: internal
    available_on: [claude]

permissions:
  allow:
    - { tool: read, pattern: "./src/**" }
  ask:
    - { tool: bash, pattern: "git push *" }
  deny:
    - { tool: bash, pattern: "curl *" }

plugins:
  my-plugin:
    install:
      claude:
        source: local
        path: plugins/my-plugin    # relative to the manifest root

mise:
  - mise/mise.toml

settings:                          # verbatim, deep-merged into native settings
  claude:
    outputStyle: Explanatory
  opencode:
    theme: tokyonight

event_hooks:
  - name: audit
    event: after_bash              # after_edit | after_bash | on_finish
                                   # | session_start | session_end
    command: "logger boff: $BOFF_COMMAND"    # inline shell
  - name: lint
    event: after_edit
    script: lint                   # shell script at event_hooks/lint
    available_on: [claude]
    timeout: 30                    # optional, seconds

hooks:
  pre_install:
    - script: check-deps           # hooks/check-deps.py
  post_install:
    - script: warm-index
```

---

## 5. Artifact detail, per platform

### Rules

Markdown files providing persistent instructions. The body deploys **verbatim**: write no
frontmatter unless you want it on disk.

| Platform | Target |
|---|---|
| `claude` | `.claude/rules/[<category>/]<name>.md` |
| `opencode` | `.opencode/rules/[<category>/]<name>.md`, plus an `instructions` glob merged into `opencode.json` |
| `antigravity` | Inlined into a generated `GEMINI.md`, one `## <name>` section per rule, in manifest order. `category:` is ignored. |

`globs:` scopes a rule to matching files. **Only Claude enforces it**: Bun Off prepends a
`paths:` frontmatter block (a YAML list of the patterns) to the rule file, the key Claude Code
reads for path-scoped rules. OpenCode and Antigravity deploy the rule unscoped and log a
warning, because neither supports conditional, path-scoped loading.

Antigravity never loads `.agents/rules/*.md` and does not expand `@`-includes, which is why
rules are inlined. Bun Off writes `GEMINI.md`, never `AGENTS.md`: `AGENTS.md` is OpenCode's
primary instructions file and is commonly hand-authored.

### Skills

Markdown files teaching a repeatable workflow. Deployed to
`<config_root>/skills/<name>/SKILL.md` on all three platforms (`.claude/`, `.opencode/`,
`.agents/`).

A skill takes either of two forms on disk, and Bun Off picks the one it finds:

```
skills/
  quick-fix.md              a skill that is just its own text
  review-checklist/         a skill that ships supporting files
    SKILL.md                the entry point; the name is fixed
    references/rubric.md    read only when the skill needs it
    templates/report.md     a file the assistant copies
```

- **A skill folder ships its own subtree.** Everything under it deploys beside `SKILL.md`
  keeping its layout, so `.claude/skills/review-checklist/references/rubric.md` is where a
  relative link in `SKILL.md` expects it. Write those links relative to `SKILL.md`, not to the
  bundle root.
- Supporting files are read by the assistant with its own file tools rather than parsed by the
  platform, so the folder form behaves identically on all three.
- **Declaring a skill in both forms at once is a load error**, as is a folder with no
  `SKILL.md`. Neither is a warning: the deploy stops.
- Build and editor droppings never ship, so tooling run inside a skill folder does not reach
  the deployed skill: the `__pycache__`, `.git`, `.pytest_cache`, `.ruff_cache`, `.mypy_cache`,
  and `.ipynb_checkpoints` directories at any depth, and the files `*.pyc`, `*.pyo`,
  `.DS_Store`, `Thumbs.db`, `*.swp`, `*.swo`, `*~`, `*.orig`, and `*.rej`. Everything else
  ships, so the author still decides what a skill carries.
- `boff check` verifies every supporting file, so an edited template is reported as drift, and
  `boff deploy` removes the ones a bundle stops shipping, pruning a directory that empties.
- The content, including frontmatter, deploys verbatim. **Always write `name` and
  `description` frontmatter**: Antigravity requires both, and every platform reads the
  description to decide whether to activate the skill.
- Write the description as a trigger: state what the skill does *and when to use it*.
- Add `disable-model-invocation: true` to the frontmatter for a scaffolding skill that should
  fire only on an explicit request. Pair it with a slash command so users have an entry point.
- **Reuse a published skill instead of copying it.** A skill or rule entry with
  `from: <git URL>` resolves its name inside that repository directory instead of the local
  `skills/` or `rules/`. Pin a tag or commit, and reuse the URL with a YAML anchor:

  ```yaml
  skills:
    - name: lean-proof
      from: &lean-fro https://github.com/leanprover/skills/tree/7d3da0282e7b724b07620e45cf212f2e05e19334/skills
    - { name: lean-mwe, from: *lean-fro }
  ```

  Prefer this to a platform's plugin marketplace when the repository uses the `SKILL.md`
  layout: the fetched skill deploys to all three platforms.

### Slash commands

Markdown files defining a `/command`. `$ARGUMENTS` interpolates what the user typed.

| Platform | Target |
|---|---|
| `claude` | `.claude/commands/<name>.md` |
| `opencode` | `.opencode/commands/<name>.md` |
| `antigravity` | **Not supported**: warns and skips. |

Antigravity's slash commands are built in and it discovers no author-supplied command
directory. Scope commands with `available_on: [claude, opencode]` to silence the warning.

Keep a command thin: a `description:` frontmatter line, then a body that tells the assistant to
load and follow the matching skill, passing `$ARGUMENTS`. Do not duplicate the skill's content.

### Agents

A subagent: `name` and `description` in `boff.yaml`, system-prompt body in `agents/<name>.md`.
Bun Off generates each platform's native frontmatter, so the body file holds the prompt only.

| Platform | Target |
|---|---|
| `claude` | `.claude/agents/<name>.md` |
| `opencode` | `.opencode/agents/<name>.md` |
| `antigravity` | `.agents/agents/<name>.md` |

- `model:` takes a string (verbatim on every platform) or a per-platform map. Bun Off performs
  **no model-name translation**: Claude expects an alias (`haiku`, `sonnet`, `opus`) or a full
  id, OpenCode expects `provider/model-id`. Use the map form when targeting both. Antigravity
  subagents inherit the parent's model: a `model` there is ignored with a warning.
- `mode:` is OpenCode-only; Claude ignores it.
- Per-agent `permissions:` use the same rule shape as the top-level block, but are more
  restricted. **Claude rejects a per-agent `pattern` and a per-agent `ask` verdict** (it maps
  `allow`/`deny` onto `tools`/`disallowedTools`). **Antigravity rejects per-agent permissions
  entirely.** Both are hard errors: scope such rules with `available_on: [opencode]`.

### MCP servers

Each entry injects verbatim JSON into the platform's MCP config. You supply one raw file per
platform at `mcp_servers/raw/<platform>/<name>.json`, holding the server object exactly as
that platform expects it.

| Platform | Target file | Merged under |
|---|---|---|
| `claude` | `.mcp.json` | `mcpServers` |
| `opencode` | `opencode.json` | `mcp` |
| `antigravity` | `.agents/mcp_config.json` | `mcpServers` |

- **Provide a raw file for every platform the server is available on.** An entry with no raw
  file at all fails to load; an entry missing the file for a platform you are deploying to
  fails during that deploy. Use `available_on:` when you have config for only some platforms.
- The per-platform shapes genuinely differ. Claude and Antigravity use a Claude-style object
  (`command`, `args`, `env`, or a remote endpoint); OpenCode uses its own (`type: "local"` with
  a `command` array, or `type: "remote"` with a `url`, plus `enabled`).
- **Antigravity names a remote endpoint `serverUrl`.** The `url` and `httpUrl` keys are not
  read.
- Prefer a launcher that needs no prior install (`uvx`, `npx`) and declare its runtime under
  `mise:`.

### Permissions

Platform-neutral tool-use policy, grouped under `allow`, `ask`, and `deny`. Each rule needs a
`tool`; `pattern` narrows it, `available_on` restricts it.

The fifteen canonical tool names:

`bash`, `read`, `edit`, `write`, `glob`, `grep`, `webfetch`, `websearch`, `agent`, `mcp`,
`lsp`, `skill`, `question`, `external_directory`, `doom_loop`

| Platform | Target file | Merged under |
|---|---|---|
| `claude` | `.claude/settings.json` | `permissions`, split into `allow`/`ask`/`deny` |
| `opencode` | `opencode.json` | `permission`, keyed by tool |
| `antigravity` | **Not supported**: warns and skips (its allowlist is machine-global). |

**A tool the target platform cannot express is a hard error, not a warning.** Claude rejects
`lsp`, `skill`, `question`, `external_directory`, and `doom_loop`; OpenCode rejects `mcp`.
Scope those rules with `available_on:`.

Translation notes: `agent` becomes `Task` (Claude) or `task` (OpenCode); `webfetch` with a
pattern becomes `WebFetch(domain:<pattern>)`, so write the pattern as a bare domain; `mcp`
becomes `mcp__<pattern>`, or plain `mcp` with no pattern; `write` collapses into `edit` on
OpenCode.

### Settings

A verbatim per-platform block, deep-merged into the platform's native settings file. Use it for
anything Bun Off does not model with a dedicated artifact.

| Platform | Target file |
|---|---|
| `claude` | `.claude/settings.json` |
| `opencode` | `opencode.json` |
| `antigravity` | **Not supported**: warns and skips (it has no workspace settings file). |

Bun Off does not validate the values, but it **rejects keys a dedicated artifact owns**:
`permissions` and `mcpServers` on Claude; `permission`, `mcp`, and `instructions` on OpenCode.
Configure those through `permissions:`, `mcp_servers:`, and `rules:`.

This block is also the escape hatch for anything the normalized artifacts cannot express: a
Claude-native hook event that must block a tool call, an OpenCode `formatter`, an LSP entry.

### Plugins

Copies a local file tree into the workspace root, preserving structure, for the listed
platforms only.

```yaml
plugins:
  my-plugin:
    install:
      opencode:
        source: local
        path: plugins/my-plugin
```

Only `source: local` exists today. Use it to vendor a file a platform loads from a fixed path
that no other artifact targets. A file a *skill* needs is not that case: put it in the skill's
own folder, where it lands beside `SKILL.md` instead of at the workspace root.

### mise (tool installer)

`mise:` lists `mise.toml` files relative to the manifest root. Bun Off writes each as a drop-in
it owns at `<workspace>/.config/mise/conf.d/boff-<n>.toml`. This is **non-destructive**: mise
auto-loads every file under `conf.d/`, so a hand-authored `mise.toml` is never touched.

Declare the runtimes and CLIs your MCP servers, hooks, and plugins assume. Deploying does not
install them: pair the drop-in with a `post_install` hook that runs `mise install`, or a
`session_start` event hook, or both.

### Lifecycle hooks

Python scripts run around the deploy itself, not inside the assistant. Each `script:` name
resolves to `hooks/<name>.py`.

```python
from boff.hooks import HookContext

ctx = HookContext.from_stdin()
# ctx.phase          HookPhase: pre_install | post_install
# ctx.platforms      tuple[str, ...]
# ctx.scope          Scope: kind + workspace_root
# ctx.manifest_root  Path to the manifest folder
# ctx.ops_count      int, operations planned
```

Bun Off runs them with its own Python interpreter, from the root of the bundle that declared
them, so a hook inherited through `extends:` still resolves paths against its own bundle. A
non-zero exit aborts the deploy. Hooks do not run under `--dry-run`.

Keep them idempotent and quiet: a deploy may be repeated at any time. Fail open on anything
optional.

### Event hooks

Shell bodies that run *inside* the assistant on a runtime event. You write one body; Bun Off
generates the platform glue.

| `event:` | Fires | Claude | OpenCode | Antigravity | Context |
|---|---|---|---|---|---|
| `after_edit` | after a file edit or write | `PostToolUse` (`Edit\|Write`) | `tool.execute.after` | `PostToolUse` (file-writing tools) | `BOFF_FILE` |
| `after_bash` | after a shell command | `PostToolUse` (`Bash`) | `tool.execute.after` | `PostToolUse` (`run_command`) | `BOFF_COMMAND` |
| `on_finish` | when the assistant finishes | `Stop` | `session.idle` | `Stop` | none |
| `session_start` | when a session starts | `SessionStart` | `session.start` | **not supported** | none |
| `session_end` | when a session ends | `SessionEnd` | `session.deleted` | **not supported** | none |

Each entry needs a `name` (also the deployed filename), an `event` from that set, and exactly
one of `command:` (inline shell) or `script:` (a file under `event_hooks/`). Optional:
`available_on:` and `timeout:` (honored by Claude and Antigravity, ignored by OpenCode).

The script contract, identical on every platform:

| Variable | Value |
|---|---|
| `BOFF_EVENT` | the normalized event name |
| `BOFF_TOOL` | the underlying tool, lowercased (`edit`, `write`, `bash`); empty when not applicable |
| `BOFF_FILE` | the edited file for `after_edit`; empty otherwise |
| `BOFF_COMMAND` | the command for `after_bash`; empty otherwise |

Three properties to design around:

- **Side-effect only.** Output and exit code are ignored; a hook cannot block or modify a tool
  call. For blocking or context injection, write a raw Claude `hooks` block through
  `settings:` and scope it to Claude.
- **`session_end` is approximate off Claude.** OpenCode maps it to `session.deleted`, which
  fires on session removal, not on a graceful exit. Prefer `session_start` for once-per-session
  work.
- **Antigravity has no session lifecycle events.** Scope `session_start` / `session_end` hooks
  with `available_on: [claude, opencode]`.

**Prefer a native feature over a hook when one exists.** Formatting is the canonical case:
OpenCode formats natively and more efficiently, so scope the hook to Claude and configure
OpenCode through `settings:`.

```yaml
event_hooks:
  - name: format
    event: after_edit
    command: 'command -v myfmt >/dev/null 2>&1 && myfmt "$BOFF_FILE" || exit 0'
    available_on: [claude]

settings:
  opencode:
    formatter:
      myfmt:
        command: ["myfmt", "$FILE"]     # $FILE is OpenCode's own placeholder
        extensions: [".ext"]
```

---

## 6. Platform capability matrix

| Artifact | `claude` | `opencode` | `antigravity` |
|---|---|---|---|
| `rules` | yes, `globs:` enforced | yes, `globs:` warns | yes, inlined into `GEMINI.md`; `globs:`/`category:` ignored |
| `skills` | yes, supporting files included | yes, supporting files included | yes, supporting files included |
| `slash_commands` | yes | yes | dropped with a warning |
| `agents` | yes; no per-agent `pattern`/`ask` (error) | yes, full | yes; per-agent permissions are an error, `model` ignored |
| `mcp_servers` | yes | yes | yes; remote key is `serverUrl` |
| `permissions` | yes; rejects 5 tools (error) | yes; rejects `mcp` (error) | dropped with a warning |
| `settings` | yes | yes | dropped with a warning |
| `event_hooks` | all five events | all five events | no `session_start` / `session_end` (dropped with a warning) |
| `plugins`, `mise`, `hooks` | yes | yes | yes |

"Dropped with a warning" is not a failure: `boff check` reports it as `dropped` and still exits
0. A hard error stops the deploy, so scope those artifacts with `available_on:`.

---

## 7. Targeting platforms with `available_on:`

Every artifact accepts `available_on:` (rules, skills, slash commands, MCP servers, agents,
event hooks, and each individual permission rule). Omit it and the artifact deploys to every
platform in the current `--platform` invocation.

Use it for three things: silencing a warn-and-skip, avoiding a hard error, and splitting one
intent across platforms. The split pattern deploys two entries with the same purpose and
different bodies:

```yaml
rules:
  - name: tool-usage-manual         # platforms with no interception point
    available_on: [antigravity]
event_hooks:
  - name: tool-usage-auto           # platforms that can automate it
    event: after_bash
    available_on: [claude, opencode]
    command: "..."
```

---

## 8. `extends:` and references

`extends:` takes one reference or an ordered list. Each names another manifest folder, which
Bun Off loads and merges *underneath* this one.

| Form | Example |
|---|---|
| Local path | `../base-stack`, `/abs/path/stack` (relative to the extending manifest) |
| Git URL | `https://host/org/repo.git/sub/dir@v1.2.0` |
| Forge URL | `https://github.com/org/repo/sub/dir@v1.2.0` |
| Browser URL | `https://github.com/org/repo/tree/main/sub/dir` |
| Repository root | `https://github.com/org/repo` |

The `/<subdir>` and the trailing `@<ref>` are optional; `@<ref>` defaults to the remote's
default branch, and is the only way to name a branch containing a slash.

**Merge is last-wins.** Parents merge in declaration order, and the child overrides them all.
Named artifacts (rules, skills, slash commands, MCP servers, agents, plugins, event hooks)
replace by name, printing a warning. Permission rules concatenate and de-duplicate. `settings:`
deep-merges per platform. `mise` file lists concatenate. `meta:` is never inherited: write your
own. Inheritance cycles are an error.

Override an inherited rule by declaring a rule with the same name and shipping your own
`rules/<name>.md`. Drop one you do not want by not extending that bundle, or by overriding it
with a body that says something else: there is no "remove" directive.

---

## 9. Writing the content files

The manifest is the easy half. The bundle is only as good as its prose.

**Rules.** Short, imperative, one concern. Aim for under twenty lines: a one-line statement of
the principle, then bullets that are checkable. Say what to do, not what a tool is. Never dump
code, and never restate something the assistant already does by default.

```markdown
# Verify your work

Close the loop yourself: never report a change as done on the strength of "it looks right."

- Run the project's own gate after a change: its tests, build, linter, or type checker.
- Reproduce a bug with a failing test before you fix it, then watch that test go green.
- Show the evidence: the command you ran and its output.
```

**Skills.** A numbered procedure someone could follow. Open with frontmatter whose
`description` states what it does *and when to use it*. Structure the body as ordered steps,
and close with a guardrails section naming what the skill must not do. Reach for the folder
form once `SKILL.md` grows a long reference table or a template worth copying verbatim: keep
`SKILL.md` the procedure and move that material to `references/` or `templates/`, so it costs
context only when the step that needs it is reached. A skill that fits in one readable file
stays one file.

**Slash commands.** Frontmatter `description:`, then two or three sentences delegating to the
skill and passing `$ARGUMENTS`.

**Agents.** The body is a system prompt: state the role, the scope, and the stopping condition.

**House style throughout.** Active voice. Lead with the point. Prefer a concrete command over a
paragraph. Use colons rather than dashes to introduce an explanation. Keep emojis out of
everything except a `README.md`.

**A bundle `README.md`** is conventional and not read by `boff`: what the bundle deploys, what
it deliberately omits, a usage line per platform, and any prerequisite.

---

## 10. Validate

Always validate before reporting the bundle done.

If `boff` is on `PATH`, run a dry run from a scratch directory, once per target platform.
`--dry-run` writes nothing and runs no lifecycle hooks; the workspace is always the current
directory, so never dry-run from the user's project unless that is where it will be deployed.

```bash
mkdir -p /tmp/boff-check && cd /tmp/boff-check
boff -v deploy /path/to/my-bundle --dry-run --platform claude
boff -v deploy /path/to/my-bundle --dry-run --platform opencode
boff -v deploy /path/to/my-bundle --dry-run --platform antigravity
```

Read the output: the `meta` header, then one operation per artifact per platform. Confirm every
artifact you authored appears, and that the only warnings are drops you intended. `-v` is a
global flag and goes *before* the subcommand; without it you get a count rather than a list.

Then deploy for real into that scratch directory and verify:

```bash
boff deploy /path/to/my-bundle --platform claude
boff -v check --no-probe              # expect no missing / drifted / stale
```

`--no-probe` is a `check` flag (not a `deploy` one). It skips the requirement that each
platform's CLI binary be on `PATH`, which matters wherever the assistants are not installed.

If `boff` is unavailable, verify by hand:

- Every name under `rules:`, `slash_commands:`, `agents:` has its `.md` file.
- Every name under `skills:` resolves to either `skills/<name>.md` or `skills/<name>/SKILL.md`,
  never both, and every relative link in a `SKILL.md` points inside its own folder.
- Every `mcp_servers:` entry has a raw JSON file for each platform it is available on, and each
  file parses.
- Every `event_hooks:` entry has exactly one of `command:` or `script:`, and every `script:`
  file exists under `event_hooks/`.
- Every `hooks:` script exists at `hooks/<name>.py`.
- `meta.name` and `meta.description` are present and non-empty.
- The YAML parses.

---

## 11. Common mistakes

- A name listed in `boff.yaml` with no backing file. The most frequent failure.
- A missing `meta:` block, or `meta.name` / `meta.description` left out.
- An unquoted YAML scalar containing a colon. `description: Author bundles: turn a ...` is a
  parse error: quote any value with a colon in it.
- A `SKILL.md` with no `name` / `description` frontmatter: Antigravity will not load it.
- A skill declared in both forms at once (`skills/<name>.md` *and* `skills/<name>/`), usually a
  leftover file after a split. That is an error, as is a skill folder with no `SKILL.md`.
- A link in a `SKILL.md` written relative to the bundle root. Only the skill's own folder
  deploys with it: a link must stay inside it.
- Reserved keys inside `settings:` (`permissions`, `mcpServers`, `permission`, `mcp`,
  `instructions`). Use the dedicated section instead.
- Expecting `globs:` to scope a rule on OpenCode or Antigravity. Only Claude enforces it.
- A permission naming a tool the target rejects. That is an error and stops the deploy: scope
  it with `available_on:`.
- Per-agent `pattern` or `ask` rules on Claude, or any per-agent permission on Antigravity.
- An MCP server missing its raw JSON for a platform it is available on.
- Slash commands, `settings:`, `permissions:`, or session events deployed to Antigravity
  without `available_on:`, producing warnings on every deploy.
- Copying a Claude MCP config into `raw/opencode/`: the shapes differ.
- A formatting or linting hook configured for every platform, when the platform formats
  natively.
- A rule that is really a workflow. Move it to a skill.
