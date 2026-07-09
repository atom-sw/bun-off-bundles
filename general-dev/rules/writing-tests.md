# Writing tests

Write tests that pin behavior clearly and survive refactoring.

- Test one behavior per case, and name the test for the scenario and its expected outcome.
  Arrange, act, then assert.
- Prefer a single table-driven (parametrized) test over several near-duplicate tests when the
  cases share the same structure. Give each case a clear label so a failure names the scenario.
- Do not repeat a literal. Bind a value once and reuse it for both the input and the expected
  result, so the two cannot drift. For example, bind `greeting = "hello"`, construct the object
  with `greeting`, then assert against `greeting` rather than a second literal `"hello"`. Derive
  expected values from the same source where practical.
- Build shared state with factories or fixtures instead of duplicating setup across tests.
- Assert observable behavior through the public interface, not internal details. Keep mocking to
  a minimum: prefer real objects.
- Keep each test independent and deterministic: no reliance on order or shared mutable state,
  and control time and randomness.
- Cover the edge cases and error paths, not only the happy path.
