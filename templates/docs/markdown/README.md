# Markdown Documentation Generation

Generates Markdown documentation for a semantic convention registry.

Stability: Development
Owners: TBD

> **Requires the next weaver release (presumably 0.25.0).**

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

Every link in the generated docs comes from a param.

| Param | Purpose |
| --- | --- |
| `registry_base_url` | Where this registry is published (no trailing slash). Links between generated pages are absolute, `<registry_base_url>/<namespace>/<page>.md`, so they also work from a snippet embedded anywhere. |
| `otel_requirement_level_url`, `otel_naming_recommendations_url`, `otel_recording_errors_url` | OpenTelemetry general guidance. The same for everyone; params only so they are easy to update. |
| `upstream_docs_base_url`, `upstream_docs_attribute_path` | Where attributes you *import* from another registry are documented. The link is the two joined, with `{namespace}` substituted. |

Each attribute links to its own documentation: attributes defined in this
registry link to its own pages, imported ones link upstream.
[`tests/cross-registry`](tests/cross-registry) shows both.

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

## Limitations

- **Single upstream only.** Every imported attribute links under
  `upstream_docs_base_url`, so if you depend on more than one registry, links to
  the others are wrong. Routing each import to its own upstream is a TODO.

## Tests

Each test lives in `tests/<name>/`:

| File | Purpose |
| --- | --- |
| `registry/` | The input registry. |
| `expected/` | The output to match. |
| `params.yaml` | Params for this test (optional). |
| `weaver-config.yaml` | What a registry would put in `.weaver.toml` - `acronyms`, `text_maps` (optional). |
| `markdown/` | Makes this a snippet test (optional): these files carry `<!-- weaver … -->` markers and are run through `update-markdown` instead of `generate`. |

Run them with `make test-templates`, or `make update-test-output` to rewrite
`expected/` from the current output.
