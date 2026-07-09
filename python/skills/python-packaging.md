---
name: python-packaging
description: Build, version, and publish a Python package with uv. Use when cutting a release, bumping the version, building a wheel or sdist, publishing to PyPI or a private index, or tagging a release.
disable-model-invocation: true
---

# Python packaging and release

Follow this workflow to release a Python package managed by uv. Run the steps in order and
stop if any check fails.

## 1. Preflight

- Confirm the working tree is clean and on the intended branch.
- Confirm the checks pass: `uv run pytest`, the linter, and the type checker.
- Confirm `pyproject.toml` metadata is correct: `name`, `description`, `authors`, `license`,
  `requires-python`, and `classifiers`.

## 2. Bump the version

- Choose the level from the changes: `patch` for fixes, `minor` for features, `major` for
  breaking changes.
- Bump it: `uv version --bump <patch|minor|major>`. Pre-release and post-release components
  (`stable`, `alpha`, `beta`, `rc`, `post`, `dev`) are also supported.
- Update the changelog if the project keeps one.

## 3. Build

- Build the distributions: `uv build`. This writes an sdist and a wheel to `dist/`.
- Verify `dist/` contains the wheel and sdist for the new version and nothing stale.

## 4. Publish

- Publish: `uv publish`. Supply credentials through the environment, never on the command
  line: set `UV_PUBLISH_TOKEN` (or `UV_PUBLISH_USERNAME` and `UV_PUBLISH_PASSWORD`).
- Publish to a private or test index with `--publish-url`. When unsure, do a trial run
  against TestPyPI first (`--publish-url https://test.pypi.org/legacy/`).
- In CI, prefer a PyPI Trusted Publisher (OIDC): configure the trusted publisher on the
  project so no token is stored as a secret.

## 5. Tag and finalize

- Commit the version bump and changelog.
- Tag the release: `git tag vX.Y.Z`, then push the tag.
- On GitHub, publish release notes: `gh release create vX.Y.Z`.

## Guardrails

- Never publish from a dirty tree or with failing checks.
- Keep credentials in the environment or a keyring, never in the repository.
