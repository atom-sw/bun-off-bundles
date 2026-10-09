# lean-tutorial bundle

A tutoring style for writing a literate Lean tutorial **with** a learner, deployable to Claude
Code, OpenCode, and Antigravity CLI with `bun-off`. The learner's understanding is the
deliverable; the code is the evidence. It extends [`lean-base`](../lean-base/README.md), so
deploying it also installs the Lean language server, the `lean` rule, the `lean-lint` and
`lean-weave` skills, and the `general-dev` baseline under them.

## What it deploys

Skills (loaded on demand):

- `lean-tutor`: paces the work. One new Lean concept per step, explained when it appears; the
  learner tries each proof first and gets hints only on request, from the goal state up to
  the full proof; nothing is written ahead of the agreed step. While tutoring it overrides the
  inherited workflow rules that say to pick a default and proceed: it proposes and waits.
- `literate-chapter`: fixes the shape of a chapter, a `.lean` file that Verso renders as a
  document: a header block, prose and code alternating in small units, readable proofs, and
  an `## Exercises` section holding the only allowed `sorry`s.

## Usage

```bash
boff deploy path/to/bun-off-bundles/lean-tutorial --platform claude
```

## Notes

- The skills assume a Verso-based project laid out as one chapter per file
  (`<Lib>/ChNN_Name.lean`), with site options in `literate.toml`. `lean-weave` from
  `lean-base` builds the site.
- Deliberately left out: [`cameronfreer/lean4-skills`](https://github.com/cameronfreer/lean4-skills).
  Its session hooks and autoproving commands work against learning one step at a time.
