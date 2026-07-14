# Script testing

Test scripts with the standard library's `unittest`, so the tests need no extra dependencies and
run anywhere Python does. Follow the general `writing-tests` rule; the points below are the
lightweight specifics for scripts.

- Use `unittest` from the standard library. Do not add pytest or any other test dependency: the
  point of a script is that it runs without installing anything.
- Put tests in a `test_<script>.py` file beside the script, and import the script's functions to
  exercise them. Run the suite with `python -m unittest` (or `python -m unittest test_script`).
- Keep the tests light and proportionate. Cover the core logic and the handful of edge cases
  that matter (empty input, a boundary value, an error path): you do not need exhaustive
  coverage of every branch.
- Write one behavior per test method and name it for the scenario (`test_parses_empty_file`).
  Group related cases with `unittest.TestCase`, and use `subTest` for table-driven variations.
- For filesystem work, use `tempfile.TemporaryDirectory` so tests stay isolated and leave no
  trace.
