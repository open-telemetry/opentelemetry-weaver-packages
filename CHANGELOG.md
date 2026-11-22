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
- `docs/markdown`: Add the `markdown.omit_enum_table` annotation to skip the
  enum values table where a signal pins the attribute to one value.
- `docs/markdown`: Fix duplicate footnote numbers in metric sections, where the
  metric note and attribute notes were numbered separately. Numbering now
  restarts per definition, so a definition renders the same on its page and as
  a snippet.
- `docs/markdown`: Footnote readability: an attribute's requirement condition
  and note share one labeled footnote, notes of 50 characters or less are shown
  inline, footnote markers link to their footnote, and `---` separates
  definitions instead of preceding enum value tables.

### Policies

- `check/backwards-compatibility`: Checks a registry against a baseline registry
  for breaking changes.
- `check/naming_conventions`: Enforces OpenTelemetry semantic convention naming
  rules.
- `check/stability`: Enforces stability rules for attribute definition and
  usage.
- `check/entity_associations`: Checks that entity associations in a registry are
  well formed. Skips the current materialized form, whose referential integrity
  weaver already validates during resolution, and stays a back-compatible check
  for the old bare-string form.
