# External Harness Workflow Design

## Problem

In-project `git clone Personal-Agent-Harness` nests a second `.git` inside the target project and leaves the full harness source tree in the project.

## Decision

- Primary workflow: external `PAH_HOME` clone + `bootstrap.sh <target>`.
- Installed-state tracking: existing `.harness/manifest.json` (`harness_version`, checksums).
- Update tracking: `pah status --harness-root <pah-checkout>` compares installed vs local harness `VERSION`.
- Legacy in-project clone: supported for migration via `bootstrap.sh --clean-nested`; discouraged in docs.
- Out of scope v1: curl installer, remote git fetch in status, submodule mode.

## Migration

1. External-clone harness to PAH_HOME.
2. Run `bootstrap.sh <target> --clean-nested`.
3. Optionally `pah install <target> --components gitignore` to ignore future accidental clones.
