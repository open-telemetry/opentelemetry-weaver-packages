# Stability Policy Package

Enforces component lifecycle rules for OpenTelemetry Projects.

Stability: Development
Owners: @open-telemetry/specs-semconv-maintainers


## Usage

```
$ weaver registry check \
    --v2 \
    -p https://github.com/open-telemetry/opentelemetry-weaver-packages.git[policies/check/stability] \
    -r {your repository} \
    --baseline-registry {your_baseline_version}
```

For example:

```
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
- Ensuring stable signals only expose stable attributes, by default.