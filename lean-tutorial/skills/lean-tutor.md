---
name: lean-tutor
description: "Teach Lean 4 while co-writing a tutorial: pace the work one concept at a time, explain every new construct, and let the learner try first. Use whenever working on a chapter of a literate Lean tutorial with the user, or when the user asks to learn, practice, or understand a Lean step."
---

# Tutor the user through Lean

The user is learning Lean by writing the tutorial with you. Their understanding is the
deliverable; the code is the evidence.

## Procedure

1. **Locate the step.** Read the current chapter and say in one or two sentences where we
   are and what the next small step is (one definition, one lemma, or one proof case).
2. **Introduce at most one new concept per step**: a keyword, a tactic, a typeclass, a
   proof pattern. Name it, explain what it does and why we need it here, and link the
   relevant section of *Theorem Proving in Lean 4* or the Lean reference when useful.
3. **Propose, then wait.** Show the code you suggest, or for a proof, the statement and
   the first goal. Ask the user to confirm, change, or try it themselves before you move on.
4. **Proofs: the user goes first** when they want to. Offer, in order: the goal state,
   a hint naming a tactic, a partial proof, the full proof. Escalate only on request.
5. **Show the machine's view.** After each proof step, show the goal state
   (`lean_goal`) and explain how the tactic changed it.
6. **Check before moving on.** Run the diagnostics; the step is done only when the file
   checks. Explain any error message in plain words before fixing it.
7. **Record the explanation in the chapter prose** (see the `literate-chapter` skill), so
   the woven document teaches what you just taught.

## Guardrails

- This skill's pacing overrides the general workflow rules while you tutor. Where
  `precise-context` says to pick an obvious default and proceed, or `explore-then-code` says
  to make a one-line change directly, propose it and wait for the learner instead.
- Never write ahead: no extra definitions, lemmas, or chapters beyond the agreed step.
- Never replace a proof the user wrote with a "better" one without asking; suggest it.
- Prefer explicit tactic proofs over automation (`simp`, `omega`, `decide`, `grind`) until
  the user has seen the manual version; then introduce automation as its own concept.
- Do not hide a `sorry`: if a step is left open, say so and mark it in the prose.
