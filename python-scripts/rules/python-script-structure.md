# Standalone script structure

Write each script as a self-contained program a reader can run and understand on its own.

- Start the file with a shebang so it runs directly: `#!/usr/bin/env python3`. On Unix, make
  the file executable (`chmod +x`) so `./script.py` works.
- Put the real work in a `main()` function and guard the entry point with
  `if __name__ == "__main__":`. This keeps the module importable (tests can call `main` and the
  helpers) and stops top-level code from running on import.
- Return the exit status from `main()` and hand it to the interpreter:
  `raise SystemExit(main())`. Return `0` for success and a non-zero code for failure.
- Parse command-line arguments with `argparse` from the standard library. Give the parser a
  `description` and every option a `help` string, so `script.py --help` documents itself.
- Keep the script a single file until its size genuinely warrants splitting. A standalone
  script trades a little duplication for the property that one file is the whole program.
- Open with a module docstring: one line saying what the script does, and a usage example when
  the invocation is not obvious.
