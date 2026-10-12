# Backwards Compatibility Policies

This package provides backwards compatibility guarantees required by OpenTelemetry projects.

Stability: Development
Owners: @open-telemetry/specs-semconv-maintainers

## Details

This package checks the current registry against a baseline registry and reports
breaking changes to attributes, metrics, entities, events, spans, and public
attribute groups.

## Usage

```bash
$ weaver registry check \
    -p https://github.com/open-telemetry/opentelemetry-weaver-packages.git[policies/check/backwards-compatibility] \
    -r {your repository} \
    --baseline-registry {your_baseline_version}
```

## Exceptions

When a signal becomes a refinement, put the removal exception on its replacement:

```yaml
span_refinements:
  - id: span.aws.lambda.server
    ref: faas.server
    annotations:
      compatibility:
        policy_exceptions:
          - span_missing
```

Use the finding ID without the `compatibility_` prefix:

| Signal | Exception |
| --- | --- |
| Span | `span_missing` |
| Metric | `metric_missing` |
| Event | `event_missing` |
| Entity | `entity_missing` |

The refinement must have the same signal kind and match the former name or type.
Its ID may include the kind prefix, such as `span.` or `metric.`.
The example suppresses removal of `aws.lambda.server` only.

Other compatibility checks still run. Baseline annotations do not suppress findings.

### Entity converted to a public attribute group

A replacement public attribute group can suppress entity removal with the same
annotation:

```yaml
attribute_groups:
  - id: device
    visibility: public
    stability: development
    brief: Device attributes.
    annotations:
      compatibility:
        policy_exceptions: [entity_missing]
    attributes:
      - ref: device.id
        requirement_level: opt_in
```

The group ID must exactly match the removed entity type. Internal groups,
unannotated groups, and baseline annotations do not suppress removal findings.
Other compatibility checks still run.
