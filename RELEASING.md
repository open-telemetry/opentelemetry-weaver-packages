# Releasing

All packages in this repository are released together under a single version,
starting at `v0.1.0`. Releases are cut from `main` and published as GitHub
releases; consumers pin a package by referencing its path at a release tag.

Versioning is [semantic](https://semver.org/): breaking changes to a package's
inputs or outputs bump the minor version while the major version is `0`.

## Preparing a release

There are two ways to prepare a release.

### Option 1: run the prepare release workflow

1. Run the [prepare release workflow](https://github.com/open-telemetry/opentelemetry-weaver-packages/actions/workflows/prepare-release.yml)
   with the version to release, e.g. `0.1.0`. It turns the `## Unreleased`
   section of [CHANGELOG.md](CHANGELOG.md) into a `## v{version}` section, opens
   a fresh `## Unreleased` section, and creates a pull request with the result.
2. Review and merge the pull request.
   - Note: if changes with change log entries are merged to `main` while the
     pull request is open, close it and re-run the workflow so those entries are
     part of the release.
   - The workflow only reshuffles the existing `## Unreleased` section, so if any
     merged changes are missing an entry, add them to the pull request during
     review.

The same change can be made by hand if the workflow is unavailable:

```bash
make chlog-update VERSION=0.1.0
```

### Option 2: use the prepare-release skill

Use the [prepare-release skill](skills/prepare-release.md) to have an agent
prepare the release. On top of cutting the change log section, it reconciles the
`## Unreleased` section against the changes merged since the last release and
fills in any missing entries before opening the pull request. Review and merge
the pull request it opens.

## Making the release

Merging the release pull request triggers the
[release workflow](https://github.com/open-telemetry/opentelemetry-weaver-packages/actions/workflows/release.yml),
which reads the topmost version in `CHANGELOG.md`, creates the `v{version}` tag
and publishes a GitHub release with that section of the change log as release
notes.

On merge, the workflow only runs for pull requests that carry the `release`
label, so ordinary changes to `CHANGELOG.md` never release. It fails if the
change log has no untagged version section, which means the release pull request
did not update the change log.

The workflow can also be run manually with `workflow_dispatch` against `main`,
which skips those checks - use it if the release pull request was merged without
triggering the workflow.

Verify that the [release](https://github.com/open-telemetry/opentelemetry-weaver-packages/releases)
looks as expected once the workflow finishes.

If the workflow is unavailable, create the
[release](https://github.com/open-telemetry/opentelemetry-weaver-packages/releases/new)
by hand: set the tag and title to `v{version}` on the merged release commit and
paste that version's `CHANGELOG.md` section as the release notes.
