# Changelog

All notable changes to the packages in this repository are documented here.

Add your entry under `## Unreleased` in the same pull request that makes the
change. See [CONTRIBUTING.md](CONTRIBUTING.md#changelog) for details.

## Unreleased

### Templates

- `docs/markdown`: Generates Markdown documentation for a semantic convention
  registry - namespace-first pages for attributes, spans, metrics, events, and
  entities, plus embeddable snippet tables and configurable cross-registry
  links.

### Policies

- `check/backwards-compatibility`: Checks a registry against a baseline registry
  for breaking changes.
- `check/naming_conventions`: Enforces OpenTelemetry semantic convention naming
  rules.
- `check/stability`: Enforces stability rules for attribute definition and
  usage.
- `check/entity_associations`: Checks that entity associations in a registry are
  well formed.
