---
description: Scaffold a standalone Python script and its unittest test by following the new-script skill.
---

Scaffold a new standalone Python script. Load and follow the `new-script` skill, running its
steps in order: settle the filename and CLI, write the script from the template, write the
matching `test_<name>.py`, then verify with `python <name>.py --help` and `python -m unittest`.
Keep the script dependency-free unless a dependency is genuinely needed.

Script name and purpose for this run: $ARGUMENTS
