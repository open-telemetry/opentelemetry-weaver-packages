# Contributing

Welcome to OpenTelemetry weaver packages repository!

Before you start - see OpenTelemetry general
[contributing](https://github.com/open-telemetry/community/blob/main/guides/contributor/README.md)
requirements and recommendations.

## Sign the CLA

Before you can contribute, you will need to sign the [Contributor License
Agreement](https://identity.linuxfoundation.org/projects/cncf).

## How to contribute

Weaver packages come in two primary forms:

- `templates`: Code generation, Documentation generation, etc.
- `policies`: Verification and validation rules that can be applied to a repository.

## Running Tests

To run all tests from the root of the repository:

```bash
make test
```

Individual targets:

```bash
make test-policies    # policy packages only
make test-templates   # template packages only
```

Requires `weaver` on your PATH. Set the `WEAVER` environment variable to use a custom path.

## Changelog

Every user-facing change needs an entry in [CHANGELOG.md](CHANGELOG.md), added
in the same pull request as the change itself. Put it under the `## Unreleased`
heading, in the `### Templates` or `### Policies` subsection (create the
subsection if it is missing), and prefix it with the package it applies to:

```markdown
## Unreleased

### Policies

- `check/stability`: Allow deprecated attributes to be referenced from
  deprecated groups. ([#123](https://github.com/open-telemetry/opentelemetry-weaver-packages/pull/123))
```

Changes that don't affect users of the packages - CI, tests, refactoring - don't
need an entry; start the pull request title with `[chore]` instead.

Entries under `## Unreleased` become the release notes of the next release. See
[RELEASING.md](RELEASING.md) for how a release is cut.

## Templates

Weaver template packages consist of a `weaver.yaml`, a set of jinja templates, a `README.md` and `tests` directory filled with tests for the templates.

Templates are divided into two categories:

- `templates/docs`: This directory contains packages which generate documentation from semantic convention registries.
- `templates/codegen`: This directory contains packages which generate code (e.g. Java, Go, TypeScript) from semantic convention registries.

### Testing Policy Packages

To run the tests for a given template package, you can run `make test-templates` from the root, or run `buildscripts/test_weaver_templates.sh` directly either within the template package directory or at the root of this repository.

### Anatomy of a template package

- `weaver.yaml`: Configuration for how to interact with template schema and which files to generate.
- `*.j2`: Jinja templates or macro files which generate files.
- `README.md`: A file describing the package.
- `tests` directory contains any number of test directories.
  - "name" directory - The name of the directory is the name of the test.
    - `registry` - This is the directory where you put a weaver registry. This will be used with the `--registry` flag in `weaver registry generate`.
    - `expected` - This directory contains the expected files you want to be generated for this test.

## Policies

Weaver policy packages consist of a set of rego policy files, a `README.md` and a `tests` directory filled with tests for the policy.

Policies are divided into two categories:

- `policies/check`: This directory contains policy packages designed to be used with `weaver registry check`.
- `policies/live-check`: This directory contains policy packages designed to be used with `weaver registry live-check`.

### Testing Policy Packages

To run the tests for a given policy package, you can run `make test-policies` from the root, or run `buildscripts/test_weaver_policies.sh` directly either within the policy package directory or at the root of this repository.

### Anatomy of a `check` policy package

- `*.rego` - These are the policy files that constitute your package.
- `README.md` - A file describing your package.
- `tests` directory contains any number of test directories.
  - "name" directory - The name of the directory is the name of the test.
    - `base` - This is the directory where you put a "baseline" weaver registry. This will be used with the `--baseline-registry` flag in `weaver registry check`.
    - `current` - This is the directory where you put a weaver registry. This will be used with the `--registry` flag in `weaver registry check`.
    - `expected-diagnostic-output.json` - This file represents the `PolicyFinding`s you expect your package will output for the given registries of this test.

### Anatomy of a `live-check` policy package

TODO - figure this out
