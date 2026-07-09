---
description: Cut a Python release by following the python-packaging skill.
---

Cut a Python release. Load and follow the `python-packaging` skill, running its steps in order:
preflight checks, version bump, build, publish, then tag. Stop if any check fails, and never
publish from a dirty tree.

Release notes or target for this run: $ARGUMENTS
