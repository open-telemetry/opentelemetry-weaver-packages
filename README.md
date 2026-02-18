# OpenTelemetry Weaver Packages

This repository is shared ecosystem for developing packages for [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver).

Weaver packages come in two primary forms:

- `templates`: Code generation, Documentation generation, etc.
- `policies`: Verification and validation rules that can be applied to a repository.

## Templates

- [docs/markdown](templates/docs/markdown/README.md): Coming soon.

## Policies

- [check/backwards-compatibility](policies/check/backwards-compatibility/README.md): Ensures compatibility between versions of schema.
- [check/stability](policies/check/stability/README.md): Ensures stability rules around attribute definition and usage are maintained.

## Missing something?

We'd love your contributions! Please read our [contributing guide](CONTRIBUTING.md) to see how to get started.

## Approvers and Maintainers

For github groups see the [codeowners](CODEOWNERS) file.

### Maintainers

- [Jeremy Blythe](https://github.com/jerbly) Evertz
- [Josh Suereth](https://github.com/jsuereth) Google LLC
- [Laurent Quérel](https://github.com/lquerel) F5 Networks
- [Liudmila Molkova](https://github.com/lmolkova), Grafana Labs

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).

### Approvers

For more information about the approver role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#approver).
