# Markdown Documentation Generation

Generates Markdown documentation for a semantic convention registry. Two entry
points share the same macros:

- **`weaver registry generate`** — renders the attribute registry (one page per
  namespace plus an index: `attributes/README.md`, `attributes/<namespace>.md`,
  `README.md`) and the entity registry (`entities/README.md`,
  `entities/<namespace>.md`).
- **`weaver registry update-markdown`** — refreshes `<!-- weaver {jq} -->`
  blocks embedded in hand-written docs using `snippet.md.j2` (span, metric,
  event, entity and attribute tables).

Stability: Development
Owners: TBD

## Usage

Generate the attribute registry:

```bash
weaver registry generate -r <registry> --v2 --templates <templates-root> docs/markdown <output>
```

Refresh embedded snippet tables (note: `update-markdown` looks for the snippet
template under `<templates-root>/registry/<target>/snippet.md.j2`):

```bash
weaver registry update-markdown -r <registry> --v2 --templates <templates-root> --target markdown <markdown-dir>
```

## Configuration

All links the templates emit are explicit params in [`weaver.yaml`](weaver.yaml)
— nothing is hardcoded in the `.j2` files. Override per registry with `--param`
(scalars) or your own copy of `weaver.yaml`. There are two independent groups:

- **OpenTelemetry general guidance** (`otel_requirement_level_url`,
  `otel_naming_recommendations_url`, `otel_recording_errors_url`) — planet-wide
  singletons, not tied to any dependency.
- **Upstream / dependency docs** (`upstream_docs_base`,
  `imported_attribute_path_template`) — where the attributes this registry
  *imports* are documented; a per-registry choice.

`registry_base_url` points at this registry's own published attribute pages.

### Cross-registry links

Each attribute the templates render is linked to its documentation. The target is
chosen from the attribute's `provenance`:

- **Local** attributes (defined in this registry) link to this registry's own
  pages under `registry_base_url`.
- **Imported** attributes (pulled from a dependency) link to their upstream
  docs at `upstream_docs_base` + `imported_attribute_path_template`. Routing
  imports to multiple upstreams is a TODO (today every import shares a single
  `upstream_docs_base`).

The [`tests/cross-registry`](tests/cross-registry) example shows this end to end:
a local registry that depends on an arbitrary upstream registry, where the
generated table links the local attribute to a relative page and the imported
attribute to the upstream docs.

## Tests

`tests/<name>/registry/` holds the input registry and `tests/<name>/expected/`
the golden output. A test that also has a `tests/<name>/markdown/` directory is
run as a snippet test through `update-markdown` (the files in `markdown/` carry
`<!-- weaver … -->` markers); otherwise it is run through `generate`. Run them
with `buildscripts/test_weaver_templates.sh` or `make test-templates`.
