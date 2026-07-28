---
name: prepare-release
description: 'Use when preparing a release of the OpenTelemetry Weaver packages in this repository - cutting a new version, updating CHANGELOG.md, and opening the release pull request. Reconciles the `## Unreleased` section against the user-facing changes merged since the last release (from PR descriptions), rewrites entries to be concise and high-level, then cuts the release section and opens the release PR.'
---

# Prepare a release

Use this skill to curate the change log and cut the release pull request by
hand, in place of the automated
[prepare release workflow](https://github.com/open-telemetry/opentelemetry-weaver-packages/actions/workflows/prepare-release.yml),
when the change log should be cleaned up first.

See [RELEASING.md](../RELEASING.md) for the overall release process and
[CONTRIBUTING.md](../CONTRIBUTING.md#changelog) for change log conventions. If
anything here contradicts those docs, fail and tell you can't continue; call out that skill is out of date.

## Goal

Produce a `## v{version}` section in [CHANGELOG.md](../CHANGELOG.md) whose
entries capture **every user-facing change** since the last release, written
concisely and at a high level, and open the release pull request.

This skill does **not** cut the git tag or publish the GitHub release — merging
the release pull request triggers the
[release workflow](https://github.com/open-telemetry/opentelemetry-weaver-packages/actions/workflows/release.yml)
that does that.

## Versioning

- All packages release together under a single version; the major version is
  `0`.
- A regular release bumps the **minor** version (e.g. `v0.2.0` → `v0.3.0`). This
  is the default.
- A **patch** release (e.g. `v0.3.0` → `v0.3.1`) is only for fixes against the
  **latest** released version. Ask the user before cutting one.
- **Fail** if the user asks to patch a version older than the latest release —
  this repository does not support patch releases of past versions.
- If the user does not give a version, default to a minor bump of the last
  release and confirm before proceeding.

## Procedure

1. **Find the last release.** Read the topmost `## v{version}` heading in
   [CHANGELOG.md](../CHANGELOG.md) and its tag:

   ```bash
   git describe --tags --abbrev=0 --match 'v*'
   ```

2. **List what merged since then.** Enumerate the user-facing changes merged to
   `main` since that tag so nothing is missed:

   ```bash
   git log --no-merges v{last}..origin/main --pretty='%s (%h)'
   ```

   For each pull request, read its description (title and body) — that is the
   source of truth for what changed and whether it is user-facing.

3. **Reconcile against `## Unreleased`.** Every user-facing change must have
   exactly one entry under `## Unreleased`. Add missing entries; drop entries for
   changes that are not user-facing (CI, tests, refactors).

4. **Fill the gaps.** Add entries for user-facing changes that are missing one,
   following the rules below. Leave existing entries alone unless they clearly
   break the rules (e.g. a raw PR title) — do not reword entries the contributor
   already wrote well.

5. **Cut the release section.** Turn `## Unreleased` into `## v{version}` and open
   a fresh empty `## Unreleased`:

   ```bash
   make chlog-update VERSION={version}
   ```

   This runs [buildscripts/update_changelog.sh](../buildscripts/update_changelog.sh).
   Do not hand-edit the section headings — let the script move them so the
   release workflow can find the section.

6. **Sanity-check the release notes.** Confirm the extracted notes read well:

   ```bash
   ./buildscripts/extract_changelog.sh {version}
   ```

7. **Open the release pull request** from a descriptively named branch (e.g.
   `prepare-release-v{version}`), titled `[chore] Prepare release v{version}`,
   carrying the `release` label. The `release` label is what triggers the release
   workflow on merge, so it is required. Leave it for a maintainer to review and
   merge — do not push or force-merge.

   > If changelog-bearing changes merge to `main` while the pull request is open,
   > close it and redo from step 2 so those entries ship in the release.

## Change log rules

Structure (see the existing [CHANGELOG.md](../CHANGELOG.md) for the exact shape):

- Entries live under `## Unreleased`, grouped into `### Templates` and
  `### Policies` subsections. Create a subsection only if it has entries.
- Each entry is a single bullet, prefixed with the package path it applies to,
  and ends with a link to its pull request:

  ```markdown
  - `check/stability`: Allow deprecated attributes to be referenced from
    deprecated groups. ([#123](https://github.com/open-telemetry/opentelemetry-weaver-packages/pull/123))
  ```

Writing style — apply these when **adding a missing entry** or fixing one that
clearly breaks the rules. Do not rewrite existing, well-formed entries; the
contributor who added them chose that wording deliberately.

- **User-facing only.** Describe the change from the perspective of someone who
  consumes the package, not the implementation. Omit CI, test, and refactor
  changes entirely.
- **Concise and high-level.** One line per change. Summarize what changed and
  why it matters; do not restate the diff or the full PR body.
- **Consistent voice.** Present tense, capitalized after the package prefix,
  ending with a period.
- **One entry per change.** Merge duplicate or overlapping bullets that describe
  the same change; split a single bullet that hides two unrelated changes.
- **Flag breaking changes** clearly in the wording (e.g. lead with "Breaking:")
  so the version bump and release notes make the impact obvious.
- **Order by package**, then by significance (breaking changes first).

## Output

When done, report:

- the chosen version and why (minor bump by default, or a patch of the latest
  release at the user's request),
- the curated `## v{version}` section,
- any merged changes you judged non-user-facing and excluded, and
- the release pull request (branch, label) ready for maintainer review.
