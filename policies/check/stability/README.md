# Stability Policy Package

Enforces component lifecycle rules for OpenTelemetry Projects.

Stability: Development
Owners: @open-telemetry/specs-semconv-maintainers

## Usage

```bash
$ weaver registry check \
    --v2 \
    -p https://github.com/open-telemetry/opentelemetry-weaver-packages.git[policies/check/stability] \
    -r {your repository} \
    --baseline-registry {your_baseline_version}
```

For example:

```bash
$ weaver registry check \
  --v2 \
  -p https://github.com/open-telemetry/opentelemetry-weaver-packages.git[policies/check/stability] \
  -r https://github.com/open-telemetry/semantic-conventions.git[model] \
  --baseline-registry https://github.com/open-telemetry/semantic-conventions/archive/refs/tags/v$(LATEST_RELEASED_SEMCONV_VERSION).zip[model]
```

## Details

This package enforces stability restrictions for OpenTelemetry semantic-conventions projects. This includes:

- Ensuring `deprecated` blocks are accurate, and up-to-date.
  For example, all `renamed_to` deprecations should point at non-depreated values.
- Ensuring stable entities declare at least one identifying attribute.
- Ensuring a signal never claims a higher stability than any attribute it
  references, unless that attribute is `opt_in`. Stability levels are ordered
  `development`/`experimental` < `alpha` < `beta` < `release_candidate` < `stable`,
  so this catches both a stable metric referencing a development attribute and,
  e.g., a `release_candidate` span referencing a `development` attribute. The
  finding id is `stability_<signal>_lower_stability_attribute`.

### Exceptions

A signal can opt out of the stability-ordering check via annotations, using the
same `policy_exceptions` mechanism as the `naming_conventions` package. The
exception key is the finding id with the leading `stability_` prefix dropped:

```yaml
metrics:
  - name: my.metric
    stability: stable
    annotations:
      stability:
        policy_exceptions:
          - metric_lower_stability_attribute
    attributes:
      - ref: some.experimental.attr
        requirement_level: required
```
