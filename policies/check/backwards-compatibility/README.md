# Backwards Compatibility Policies

This package provides backwards compatibility guarantees required by OpenTelemetry projects.

Stability: Development
Owners: @open-telemetry/specs-semconv-maintainers

## Usage

```
$ weaver registry check \
    -p https://github.com/open-telemetry/opentelemetry-weaver-packages.git[policies/check/backwards-compatibility] \
    -r {your repository} \
    --baseline-registry {your_baseline_version}
```
