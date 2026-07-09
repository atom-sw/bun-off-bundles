# Python testing

Tests run with pytest, invoked through uv. Follow the general `writing-tests` rule; the points
below are the pytest specifics.

- Run tests with `uv run pytest`. During iteration prefer a targeted run
  (`uv run pytest path/to/test_x.py::test_case`) over the full suite for speed.
- Express table-driven cases with `@pytest.mark.parametrize`, giving each case a clear `id` so a
  failure names the scenario.
- Share setup through fixtures, and use the `tmp_path` fixture for filesystem work.
