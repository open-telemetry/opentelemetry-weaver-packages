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

All behavior that varies per registry is an explicit param in
[`weaver.yaml`](weaver.yaml) — nothing is hardcoded in the `.j2` files. The
values here are the package defaults; when you reuse this package you don't edit
its `weaver.yaml`. Override params per registry on the command line with
`--param key=value` (values are parsed as YAML, so `--param stable_only=true` and
`--param 'exclude_root_namespace=["foo"]'` both work). Acronyms and text maps are
set differently — in your project's `.weaver.toml`; see below.

### Output toggles

Gate which registries are generated (via each template's `when:` clause). Both
default to `true`; the registry index (`README.md`) is emitted when **either**
is on, so setting both to `false` generates nothing.

| Param | Default | Effect |
| --- | --- | --- |
| `generate_attribute_registry` | `true` | Emit the attribute pages (`attributes/README.md`, `attributes/<namespace>.md`). |
| `generate_entity_registry` | `true` | Emit the entity pages (`entities/README.md`, `entities/<namespace>.md`). |

### Attribute & entity selection

Forwarded to the `semconv_grouped_attributes` (attributes) and `semconv_signal`
(entities) JQ functions that decide what lands in the docs. The v2 schema is
always on; by default nothing is excluded.

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
| `registry_base_url` | This registry's own published attribute pages (relative links for local attributes). |
| `otel_requirement_level_url`, `otel_naming_recommendations_url`, `otel_recording_errors_url` | OpenTelemetry general guidance — planet-wide singletons, not tied to any dependency. |
| `upstream_docs_base_url`, `upstream_docs_attribute_path` | Where *imported* attributes are documented. The imported-attribute link is `upstream_docs_base_url` + `upstream_docs_attribute_path` with `{namespace}` substituted. |

### Acronyms and text maps

The package ships a default `acronyms` list in its
[`weaver.yaml`](weaver.yaml), used by the `acronym` filter to keep known
initialisms fully upper-cased when a heading is title-cased (so the `http`
namespace renders as `HTTP`, not `Http`).

To add your own acronyms (or text maps) when reusing this package, **don't edit
`weaver.yaml`** — put them in a `[template]` section of your project's
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
  pages under `registry_base_url`.
- **Imported** attributes (pulled from a dependency) link to their upstream
  docs at `upstream_docs_base_url` + `upstream_docs_attribute_path`. Routing
  imports to multiple upstreams is a TODO (today every import shares a single
  `upstream_docs_base_url`).

The [`tests/cross-registry`](tests/cross-registry) example shows this end to end:
a local registry that depends on an arbitrary upstream registry, where the
generated table links the local attribute to a relative page and the imported
attribute to the upstream docs.

## Limitations

- **Single upstream only.** Imported attributes all link to one
  `upstream_docs_base_url`, so any multi-dependency hierarchy — whether flat
  (several direct dependencies) or deep (dependencies of dependencies) —
  produces incorrect links for every import that does not live at that one
  base. Routing imports to the right upstream (e.g. by `provenance.schema_url`
  once weaver exposes it) is a TODO.
- **`generate` covers attributes and entities only.** There is no metric, span,
  or event *registry* output — those signals are documented only via embedded
  snippets (`update-markdown` / `snippet.md.j2`), not as generated registry
  pages.
- **No deprecated-signal pages.** The registry does not generate a deprecated
  index or otherwise surface deprecated attributes/entities/signals as
  standalone documentation.

## Tests

`tests/<name>/registry/` holds the input registry and `tests/<name>/expected/`
the golden output. A test that also has a `tests/<name>/markdown/` directory is
run as a snippet test through `update-markdown` (the files in `markdown/` carry
`<!-- weaver … -->` markers); otherwise it is run through `generate`. Run them
with `buildscripts/test_weaver_templates.sh` or `make test-templates`.
