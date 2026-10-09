# writing bundle

House style for the prose an assistant writes: documentation, README files, code comments,
commit messages, and the text of error strings. It carries nothing about code itself, and
nothing that belongs to a single project, so it is meant to be installed **once per machine**.

```bash
boff deploy path/to/bun-off-bundles/writing --platform claude --global
```

Drop `--global` to install it into one workspace instead.

## What it deploys

Rules, always in context:

- `american-english`: one spelling variant everywhere, with quoted text and existing
  identifiers explicitly exempt.
- `documentation-style`: active voice, colons over dashes, arrows only for a sequence or a
  hierarchy, emoji only to decorate a README.
- `writing-docs`: document the intent and the non-obvious, lead with the point, keep the
  documentation in step with the code, and prefer an example over a paragraph.
- `tool-names`: the product name in prose (Bun Off), the command in code formatting
  (`boff`), and the package name where a registry or installer needs it (`bun-off`).

A skill, loaded only when it is wanted:

- `simple-english`: rewrite a passage in plain, controlled technical English, with short
  sentences, simple tenses, one meaning per word, and the filler removed. Ask for it by name,
  or in the words its own description recognizes ("de-slop this", "make this readable",
  "write for non-native readers").

An output style, installed but **not** switched on:

- `simple-english`: the same discipline as a session-wide voice, for Claude Code.

## Choosing how far the style applies

The Simple English guidance comes in three strengths, and you pick one by choosing what to
deploy rather than by editing anything.

| You want | Deploy | Effect |
|---|---|---|
| It available when you ask | `writing` | The skill loads on request and costs nothing otherwise. |
| It applied to all prose in a project | `writing-simple-english` | Adds a condensed always-on rule; the full skill stays available. |
| It applied to a whole session | `writing`, then pick the output style | Claude Code only. |

The output style is deployed but never selected, because installing a style does not activate
it. Choose it in `/config` under Output style, or set it yourself:

```yaml
settings:
  claude:
    outputStyle: simple-english
```

Only one output style can be active at a time, and it stays active while you are doing
anything else, so it suits a session given over to writing rather than everyday work. For
ordinary use prefer the skill.

## Credit

The `simple-english` skill and output style are **not** written here. They are vendored
verbatim from [**SimpleEnglish** by AminBlg](https://github.com/AminBlg/SimpleEnglish), used
under the MIT License, and the bundle only packages them for `boff`. All the thinking in them
is upstream's.

The copy is pinned to a specific commit. `writing/skills/simple-english/UPSTREAM.md` records
which one, and carries the licence notice. To refresh it:

```bash
./utils/sync-simple-english.sh --check   # has upstream moved?
./utils/sync-simple-english.sh           # copy, then review with git diff
```

Please report issues with the guidance itself upstream, not here.

## Usage with the development bundles

`writing` is a separate root: it does not extend `commons-dev` and `commons-dev` does not
extend it, because prose style and coding discipline are installed on different rhythms. The
pairing they are designed for is one global install and one per project:

```bash
boff deploy path/to/bun-off-bundles/writing --platform claude --global
cd path/to/your/project
boff deploy path/to/bun-off-bundles/general-dev --platform claude
```

`documentation-style` and `writing-docs` used to live in `commons-dev`. They moved here in
`commons-dev` 0.3.0.
