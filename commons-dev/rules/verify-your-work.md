# Verify your work

Close the loop yourself: never report a change as done on the strength of "it looks
right." Give every change a check you can run and read the result of.

- Run the project's own gate after a change: its tests, build, linter, or type checker.
  Prefer the command the repo already defines over an ad-hoc one.
- Reproduce a bug with a failing test before you fix it, then watch that test go green.
- Fix the root cause. Do not silence an error, weaken an assertion, or delete a test to
  make a check pass.
- Show the evidence: the command you ran and its output. State plainly when a check fails
  or a step was skipped.
