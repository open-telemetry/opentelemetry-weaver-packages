# Markdown Documentation Generation

Generates Markdown documentation for a semantic convention registry.

Stability: Development
Owners: @open-telemetry/weaver-package-maintainers

> **Requires weaver 0.25.0 or later.**

## Usage

Point weaver at this package - no need to copy it into your repo. Pin a tag or
commit instead of `main` if you want reproducible output.

Generate a full registry of Markdown pages:

```bash
weaver registry generate -r ./model --v2 \
  -t 'https://github.com/open-telemetry/opentelemetry-weaver-packages.git@main[templates/docs]' \
  markdown ./docs/registry
```

You get a top-level `README.md` listing all namespaces, and per namespace:

- `<namespace>/README.md` - what the namespace defines, plus its attributes.
- `<namespace>/spans.md`, `metrics.md`, `events.md`, `entities.md` - one page per
  signal type the namespace defines. Nothing is written for signal types it
  doesn't define.

You can generate only some signal types, or skip the registry entirely - see
[Output toggles](#output-toggles).

To embed a single table in a hand-written doc instead, put a
`<!-- weaver {jq} -->` marker where you want it and run:

```bash
weaver registry update-markdown -r ./model --v2 \
  -t 'https://github.com/open-telemetry/opentelemetry-weaver-packages.git@main[templates/docs]' \
  --target markdown ./docs
```

This rewrites the content under each marker in place.

A definition looks the same either way, so a span on a generated page matches
the same span embedded in your doc.

### Snippet input

The filter runs over the
[materialized resolved schema](https://github.com/open-telemetry/weaver/blob/main/schemas/semconv-schemas.md#materialized-resolved-schema) -
your registry with imports and attribute references expanded into full
definitions.

The filter must resolve to a *single* object, and that object becomes the
template context directly. Each entry under `.registry.spans`, `.metrics`,
`.events`, `.entities` and `.attribute_groups` is already a whole definition from
that schema, so selecting one is enough. `snippet.md.j2` then picks what to render by looking at
which fields the object has, taking the first row that matches:

| If the object has | You get | Example filter |
| --- | --- | --- |
| `kind` | Span | `.registry.spans[] \| select(.type == "myapp.request")` |
| `instrument` | Metric | `.registry.metrics[] \| select(.name == "myapp.request.duration")` |
| `identity` or `description` | Entity | `.registry.entities[] \| select(.type == "myapp.service")` |
| `name` and `attributes` | Event | `.registry.events[] \| select(.name == "myapp.session.started")` |
| `id` and `attributes` | Public attribute group | `.registry.attribute_groups[] \| select(.id == "myapp.error")` |

An object matching no row renders as empty. Attribute groups are snippet-only - the generated registry does not
give them pages of their own.

## Configuration

Set params on the command line with `--param key=value`. Values are parsed as
YAML, so `--param stable_only=true` and `--param 'exclude_root_namespace=["foo"]'`
both work. The tables below list the defaults.

[Namespace titles](#namespace-titles) are the exception - they are configured in
your project's `.weaver.toml`.

### Output toggles

Pick which signal types the generated registry covers. Turn them all off and
nothing is generated.

| Param | Default | Effect |
| --- | --- | --- |
| `generate_attribute_registry` | `true` | List attributes on the namespace README. |
| `generate_entity_registry` | `true` | Generate `<namespace>/entities.md`. |
| `generate_span_registry` | `true` | Generate `<namespace>/spans.md`. |
| `generate_metric_registry` | `true` | Generate `<namespace>/metrics.md`. |
| `generate_event_registry` | `true` | Generate `<namespace>/events.md`. |

These only affect the generated registry, not `update-markdown`. A snippet is
always rendered where you put its marker.

### Signal & attribute selection

Pick which definitions are documented. Applies to both generated pages and
snippets.

| Param | Default | Effect |
| --- | --- | --- |
| `exclude_deprecated` | `true` | Drop deprecated attributes, signals and enum members. Set to `false` to document them - they move to a `Deprecated` section at the end of the page instead of appearing inline. |
| `stable_only` | `false` | Keep only stable attributes, signals and enum members. |
| `exclude_root_namespace` | `[]` | Namespaces to drop, e.g. `["foo", "bar"]`. |

### Links

Each attribute links to its own documentation: attributes defined in this
registry link to its own pages, imported ones link upstream.
[`tests/cross-registry`](tests/cross-registry) shows both.

Links between generated pages come from params:

| Param | Purpose |
| --- | --- |
| `registry_base_url` | Where this registry is published (no trailing slash). Links between generated pages are absolute, `<registry_base_url>/<namespace>/<page>.md`, so they also work from a snippet embedded anywhere. |
| `otel_requirement_level_url`, `otel_naming_recommendations_url`, `otel_recording_errors_url` | OpenTelemetry general guidance. The same for everyone; params only so they are easy to update. |

#### Upstream docs

Where a *dependency's* attributes are documented is the `upstream_docs` text
map, keyed by the `schema_url` you declared for that dependency. Values are url
templates with `{namespace}` substituted:

```toml
[template.text_maps.upstream_docs]
"https://opentelemetry.io/schemas/1.39.0" = "https://github.com/open-telemetry/semantic-conventions/blob/main/docs/registry/attributes/{namespace}.md"
"https://example.com/schemas/platform/2.0.0" = "https://docs.example.com/reference/{namespace}/attributes/"
```

Like the title settings below this goes in your `.weaver.toml`, not `--param`.

Attributes from a dependency you don't list render
unlinked - the docs say the attribute is there without claiming to know where it
is documented. 

### Namespace titles

A namespace page is titled after its namespace id, made readable in one of two
ways:

1. If the id is in the `namespace_mapping` text map, the title comes from there.
   Use this when the title is more than the id in different casing, e.g.
   `cicd` → `CI/CD`.
2. Otherwise the id is capitalized (`myapp` → `Myapp`), or upper-cased if it is
   listed as an acronym (`http` → `HTTP`).

Both lists go in the `[template]` section of your `.weaver.toml` (weaver finds it
by walking up from your registry), not in `--param`, and apply to every template
package your project uses:

```toml
[template]
acronyms = ["API", "HTTP", "SDK", "MyProduct"]
text_maps = { namespace_mapping = { cicd = "CI/CD" } }
```

## Tests

Each test lives in `tests/<name>/`:

| File | Purpose |
| --- | --- |
| `registry/` | The input registry. |
| `expected/` | The `generate` output to match. |
| `params.yaml` | Params for this test (optional). |
| `.weaver.toml` | Project config for this test - `[template]` `acronyms`, `text_maps` (optional). |
| `markdown/` | Files carrying `<!-- weaver … -->` markers (optional). Present, the registry is *also* run through `update-markdown`. See [`tests/snippets`](tests/snippets), which has one marker per signal type. |
| `expected-markdown/` | The `update-markdown` output to match. Required when `markdown/` exists. |

Every test runs `generate`; a test with `markdown/` runs both. When it runs both,
`buildscripts/check_snippet_consistency.py` then asserts each definition came out
byte for byte identical in the snippet and in its `## \`<id>\`` section on the
generated page - the two expected trees alone cannot catch the paths drifting
apart. It reads the marker's jq filter to find the matching page, so
`select(.type == "…")` style filters are what it understands; attribute groups
have no generated page and are reported as skipped.

Run them with `make test-templates`, or `make update-test-output` to rewrite
`expected/` from the current output.
