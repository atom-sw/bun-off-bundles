---
name: literate-chapter
description: "Structure and write a tutorial chapter as a literate Lean file rendered by Verso, with prose in module-doc comments. Use when creating a new chapter file, adding sections or prose to one, or reviewing a chapter before weaving it to HTML."
---

# Write a literate Lean chapter

A chapter is one `.lean` file that reads as a document: prose in `/-! ... -/` blocks,
code between them. Verso renders both, plus the proof state after each tactic.

## Procedure

1. **Create the file** as `<Lib>/ChNN_Name.lean` (two-digit number) and import it from the
   library root module, in reading order. Add it to `literate.toml` `order` if the file
   sets one.
2. **Open with a header block**:

   ```lean
   /-!
   # Chapter title

   What this chapter formalizes, the source it follows (for example "TAPL, chapter 3"),
   and the Lean concepts it introduces.
   -/
   ```

3. **Alternate prose and code** in small units: a `/-! -/` block explains the next
   declaration, then the declaration follows. Use `##` headings for sections. Put
   one-sentence summaries in `/-- -/` docstrings on the declaration itself.
4. **Follow the source's names and notation** (for example TAPL's `t ⟶ t'`), and say in the
   prose when Lean forces a different choice and why.
5. **Show, then prove.** Use `#eval` or `#check` to illustrate a definition before stating
   theorems about it; Verso displays their output.
6. **Write readable proofs**: one tactic per line, structured cases (`case`, `·`), and a
   short comment before any non-obvious step.
7. **End with an `## Exercises` section**: statements left for the reader, each with
   `sorry` and a `/-! -/` note saying it is an exercise. These are the only allowed
   `sorry`s.
8. **Verify**: the file checks with no errors and no `sorry` outside the exercises. Weave
   the site (`lean-weave` skill) and read the rendered page once.

## Guardrails

- Keep chapters self-contained: import earlier chapters, never later ones.
- Do not write prose that restates the code; explain intent, design choices, and pitfalls.
- Do not mix languages of notation: once a symbol is introduced, keep it.
