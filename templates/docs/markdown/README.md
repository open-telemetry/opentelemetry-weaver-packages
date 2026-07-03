# Markdown Documentation Generation

Generates Markdown documentation for a semantic convention registry. Two entry
points share the same macros:

- **`weaver registry generate`** - renders a **namespace-first** registry: a
  top-level index (`README.md`) listing every namespace, and per namespace a
  `<namespace>/README.md` plus one page per signal type it defines -
  `<namespace>/attributes.md`, `<namespace>/spans.md`,
  `<namespace>/metrics.md`, `<namespace>/events.md`,
  `<namespace>/entities.md`. A signal page is emitted only when the namespace
  actually defines that signal, so there are no empty files.
- **`weaver registry update-markdown`** - refreshes `<!-- weaver {jq} -->`
  blocks embedded in hand-written docs using `snippet.md.j2` (span, metric,
  event, entity and attribute tables).

Each definition on a generated signal page is rendered with the same macros as
the embedded snippets, so a span, metric, or event looks identical whether it is
generated as a registry page or embedded via `update-markdown`.

Stability: Development
Owners: TBD

## Usage

Generate the registry (attribute, entity, and signal pages):

```bash
weaver registry generate -r <registry> --v2 --templates <templates-root> docs/markdown <output>
```

Refresh embedded snippet tables (note: `update-markdown` looks for the snippet
template under `<templates-root>/registry/<target>/snippet.md.j2`):

```bash
weaver registry update-markdown -r <registry> --v2 --templates <templates-root> --target markdown <markdown-dir>
```

## Configuration

All behavior that varies per registry is an explicit param in
[`weaver.yaml`](weaver.yaml) - nothing is hardcoded in the `.j2` files. The
values here are the package defaults; when you reuse this package you don't edit
its `weaver.yaml`. Override params per registry on the command line with
`--param key=value` (values are parsed as YAML, so `--param stable_only=true` and
`--param 'exclude_root_namespace=["foo"]'` both work). Acronyms and text maps are
set differently - in your project's `.weaver.toml`; see below.

### Output toggles

Gate which signal types are generated (via each template's `when:` clause). All
default to `true`. The registry index (`README.md`) and per-namespace
`README.md` are emitted when **any** toggle is on, and each namespace README
only links to the sections whose toggle is on and that have definitions, so
setting all toggles to `false` generates nothing.

| Param | Default | Effect |
| --- | --- | --- |
| `generate_attribute_registry` | `true` | Emit the attribute pages (`<namespace>/attributes.md`). |
| `generate_entity_registry` | `true` | Emit the entity pages (`<namespace>/entities.md`). |
| `generate_span_registry` | `true` | Emit the span pages (`<namespace>/spans.md`). |
| `generate_metric_registry` | `true` | Emit the metric pages (`<namespace>/metrics.md`). |
| `generate_event_registry` | `true` | Emit the event pages (`<namespace>/events.md`). |

### Signal & attribute selection

Forwarded to the `semconv_grouped_attributes` (attributes) and `semconv_signal`
(spans, metrics, events, entities) JQ functions that decide what lands in the
docs. The v2 schema is always on; by default nothing is excluded.

| Param | Default | Effect |
| --- | --- | --- |
| `exclude_deprecated` | `false` | Drop deprecated attributes/entities and enum members. |
| `stable_only` | `false` | Keep only stable attributes/entities and stable enum members. |
| `exclude_root_namespace` | `[]` | Root namespaces to drop, e.g. `["foo", "bar"]`. |

### Links

Every link the templates emit is an explicit param, read by
[`links.j2`](links.j2). Three independent groups:

| Param | Purpose |
| --- | --- |
| `registry_base_url` | Root of this registry's own published pages (no trailing slash). Internal links are built root-anchored as `<registry_base_url>/<namespace>/<page>.md`, so they resolve both on a generated page and inside a snippet embedded in an arbitrary doc. |
| `otel_requirement_level_url`, `otel_naming_recommendations_url`, `otel_recording_errors_url` | OpenTelemetry general guidance - planet-wide singletons, not tied to any dependency. |
| `upstream_docs_base_url`, `upstream_docs_attribute_path` | Where *imported* attributes are documented. The imported-attribute link is `upstream_docs_base_url` + `upstream_docs_attribute_path` with `{namespace}` substituted. |

### Acronyms and text maps

The package ships a default `acronyms` list in its
[`weaver.yaml`](weaver.yaml), used by the `acronym` filter to keep known
initialisms fully upper-cased when a heading is title-cased (so the `http`
namespace renders as `HTTP`, not `Http`).

To add your own acronyms (or text maps) when reusing this package, **don't edit
`weaver.yaml`** - put them in a `[template]` section of your project's
`.weaver.toml` (weaver discovers it by walking up from your registry). Those
settings apply on top of every template package the project uses:

```toml
[template]
acronyms = ["API", "HTTP", "SDK", "MyProduct"]
# text_maps = { namespace_mapping = { cicd = "CI/CD" } }
```

Your acronyms are unioned with the package's, and on a case-insensitive
collision your value wins. `text_maps` (named `term → replacement` maps used by
weaver's text-mapping filter) are wired the same way. Today the `[template]`
section supports only `acronyms` and `text_maps`.

### Cross-registry links

Each attribute the templates render is linked to its documentation. The target is
chosen from the attribute's `provenance`:

- **Local** attributes (defined in this registry) link to this registry's own
  pages under `registry_base_url` (`<registry_base_url>/<namespace>/attributes.md`).
- **Imported** attributes (pulled from a dependency) link to their upstream
  docs at `upstream_docs_base_url` + `upstream_docs_attribute_path`. Routing
  imports to multiple upstreams is a TODO (today every import shares a single
  `upstream_docs_base_url`).

The [`tests/cross-registry`](tests/cross-registry) example shows this end to end:
a local registry that depends on an arbitrary upstream registry, where the
generated table links the local attribute to a root-anchored page in this
registry and the imported attribute to the upstream docs.

## Limitations

- **Single upstream only.** Imported attributes all link to one
  `upstream_docs_base_url`, so any multi-dependency hierarchy - whether flat
  (several direct dependencies) or deep (dependencies of dependencies) -
  produces incorrect links for every import that does not live at that one
  base. Routing imports to the right upstream (e.g. by `provenance.schema_url`
  once weaver exposes it) is a TODO.
- **No deprecated-signal pages.** The registry does not generate a deprecated
  index or otherwise surface deprecated attributes/entities/signals as
  standalone documentation.

## Tests

`tests/<name>/registry/` holds the input registry and `tests/<name>/expected/`
the golden output. A test that also has a `tests/<name>/markdown/` directory is
run as a snippet test through `update-markdown` (the files in `markdown/` carry
`<!-- weaver … -->` markers); otherwise it is run through `generate`. Run them
with `buildscripts/test_weaver_templates.sh` or `make test-templates`.
