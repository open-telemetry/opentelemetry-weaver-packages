# Naming Conventions Policy Package

Enforces naming rules for OpenTelemetry Semantic Conventions.

Stability: Development
Owners: @open-telemetry/specs-semconv-maintainers

## Usage

```
$ weaver registry check 
    -p https://github.com/open-telemetry/opentelemetry-weaver-packages.git[policies/check/naming_conventions] 
    -r {your repository}
```

## Details

This package enforces naming and structural rules for OpenTelemetry semantic conventions. This includes:

- **Attribute Constant Collisions**: Ensures that attribute keys, when converted to constant names (e.g., `.` to `_`), do not collide.
- **Attribute Namespace Collisions**: Ensures that an attribute name is not used as a namespace for other attributes.
- **Complex Attribute Restrictions**: Ensures that complex types (like `any` or `template[any]`) are only used on events and spans.
- **Metric Brief Formatting**: Ensures that metric briefs end with a period.
- **Metric Namespace Collisions**: Ensures that a metric name is not used as a namespace for other metrics.
- **Name Formatting**: Enforces regex-based naming conventions for attributes, metrics, events, entities, and enum members.
- **Attribute Namespaces**: Ensures that all non-deprecated attributes are correctly namespaced.
- **Event Best Practices**: Prevents forbidden attributes like `event.name` from being manually added to events.
