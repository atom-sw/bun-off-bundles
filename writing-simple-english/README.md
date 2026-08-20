# writing-simple-english bundle

Applies Simple English to every piece of prose in a project, instead of only when you ask
for it. It is the enforcing half of the [`writing`](../writing/README.md) bundle.

## What it adds

One rule, `simple-english`: the condensed form of the skill, about 420 words, always in
context. Short sentences, simple tenses, active voice, one meaning per word, conditions before
commands, and no filler. That is all it contains.

## Deploying it

It does **not** extend `writing`, on purpose. The two are installed at different scopes, so
inheriting would put every base rule and the whole skill folder in both places and the
assistant would load each of them twice.

The usual pairing is a global `writing` and this one per project:

```bash
boff deploy path/to/bun-off-bundles/writing --platform claude --global   # once per machine
cd path/to/your/project
boff deploy path/to/bun-off-bundles/writing-simple-english --platform claude
```

To keep everything inside one workspace instead, stack the two in a single deploy:

```bash
boff deploy path/to/bun-off-bundles/writing path/to/bun-off-bundles/writing-simple-english \
    --platform claude
```

## Why a rule *and* a skill

They are two depths of the same guidance, not a duplicate. The rule is short enough to keep
loaded permanently and sets the default. The full skill is roughly ten times longer, with the
complete rule set, a checklist, and worked examples, and loads only when a passage needs a
careful pass. Keeping both means the everyday cost stays small without losing the detail.

## Credit

The guidance is vendored from
[**SimpleEnglish** by AminBlg](https://github.com/AminBlg/SimpleEnglish) and used under the
MIT License. `rules/simple-english.md` is upstream's own condensed rendering, with the
harness-specific preamble removed. The pinned commit and the licence notice are recorded in
[`writing/skills/simple-english/UPSTREAM.md`](../writing/skills/simple-english/UPSTREAM.md),
and `utils/sync-simple-english.sh` refreshes the copy.
