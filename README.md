# OpenTelemetry Weaver Packages

This repository is shared ecosystem for developing packages for [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver).

Weaver packages come in two primary forms:

- `templates`: Code generation, Documentation generation, etc.
- `policies`: Verification and validation rules that can be applied to a repository.

## Templates

TODO - implement these.

## Policies

Weaver policy packages consist of a set of rego policy files, a `README.md` and a `tests` directory filled with tests for the policy.

Policies are divided into two categories:

- `polices/check`: This directory contains policy packages designed to be used with `weaver registry check`.
- `policies/live-check`: This directory contains policy packages designed to be used with `weaver registry live-check`.

### Testing Policy Packages

To run the tests for a given policy package, you can run the `buildscripts/test_weaver_policies.sh` file either within the policy package directory, or at the root of this repository.

### Anatomy of a `check` policy package

- `*.rego` - These are the policy files that constitute your package.
- `README.md` - A file describing your package.
- `tests` directory contains any number of test directories.
  - "name" directory - The name of the directory is the name of the test.
    - `base` - This is the directory where you put a "baseline" weaver registry.  This will be used with the `--baseline-registry` flag in `weaver registry check`.
    - `current` - This is the directory where you put a weaver registry. This will be used with the `--registry` flag in `weaver registry check`.
    - `expected-diagnostic-output.json` - This file represents the `PolicyFinding`s you expect your package will output for the given registries of this test.

### Anatomy of a `live-check` policy package

TODO - figure this out


## Approvers and Maintainers

For github groups see the [codeowners](CODEOWNERS) file.

### Maintainers

- [Jeremy Blythe](https://github.com/jerbly) Evertz
- [Josh Suereth](https://github.com/jsuereth) Google LLC
- [Laurent Quérel](https://github.com/lquerel) F5 Networks

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).

### Approvers

- [Liudmila Molkova](https://github.com/lmolkova), Grafana Labs

For more information about the approver role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#approver).
