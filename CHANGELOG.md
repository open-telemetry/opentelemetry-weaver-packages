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
- `docs/markdown`: Add `entity-refinements.md` and `metric-refinements.md` pages
  for namespaces that define refinements of upstream entities or metrics.
  Refinements are automatically listed in the namespace `README.md` table of
  contents under **Entity refinements** and **Metric refinements** headings.
  Pages are emitted only when the corresponding `generate_entity_registry` /
  `generate_metric_registry` flag is enabled.
- `docs/markdown`: Fix table-of-contents anchor links for multi-word section
  headings (`Entity refinements`, `Metric refinements`) — spaces are now
  replaced with hyphens so `#entity-refinements` resolves correctly in GitHub
  Markdown.
- `diagnostic_templates/gh_workflow_command`: New diagnostic template that emits
  Weaver policy violations as `::error` GitHub Actions workflow commands and
  other diagnostics as an expandable `::group` block. Filters
  `UnstableFileFormat` advisories so CI output stays actionable.

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
