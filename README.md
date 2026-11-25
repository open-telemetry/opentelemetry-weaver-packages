# OpenTelemetry Weaver Packages

This repository is shared ecosystem for developing packages for [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver).

Weaver packages come in two primary forms:

- `templates`: Code generation, Documentation generation, etc.
- `policies`: Verification and validation rules that can be applied to a repository.

## Templates

- [docs/markdown](templates/docs/markdown/README.md): Generates Markdown docs for a registry - a namespace-first set of attribute, span, metric, event, and entity pages, plus embeddable snippet tables, with configurable cross-registry links.

## Policies

- [check/backwards-compatibility](policies/check/backwards-compatibility/README.md): Ensures compatibility between versions of schema.
- [check/naming_conventions](policies/check/naming_conventions/README.md): Enforces naming rules for OpenTelemetry Semantic Conventions.
- [check/stability](policies/check/stability/README.md): Ensures stability rules around attribute definition and usage are maintained.

## Missing something?

We'd love your contributions! Please read our [contributing guide](CONTRIBUTING.md) to see how to get started.

## Approvers and Maintainers

This repository is co-maintained by the Weaver and Semantic Conventions SIGs.
For github groups see the [codeowners](.github/CODEOWNERS) file.

### Maintainers

- [Alexander Wert](https://github.com/AlexanderWert), Dash0
- [Armin Ruech](https://github.com/arminru), Dynatrace
- [Christophe Kamphaus](https://github.com/kamphaus), Independent
- [Jeremy Blythe](https://github.com/jerbly), Evertz
- [Joao Grassi](https://github.com/joaopgrassi), Dynatrace
- [Josh Suereth](https://github.com/jsuereth), Google
- [Laurent Quérel](https://github.com/lquerel), F5 Networks
- [Liudmila Molkova](https://github.com/lmolkova), Google
- [Trask Stalnaker](https://github.com/trask), Microsoft

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).

### Approvers

For more information about the approver role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#approver).
