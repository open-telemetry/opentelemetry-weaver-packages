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

## Handling Naming Exceptions

It is possible that exceptions to naming rules are needed. In this event, we support using `annotations` to supress
naming enforcement.

Example:

```yaml
metrics:
- name: hw.battery.charge
  brief: A colliding metric.
  stability: stable
  instrument: counter
  unit: '1'
  annotations:
    # Defines controls for naming_conventions policies
    naming_conventions:
      policy_exceptions:
        # I should document why this exception is allowed.
        - metric_namespace_collision
```

All exceptions should be defined in the `naming_conventions.policy_exceptions` annotation for the signal causing the violation.

Supported policy_exception strings:

- `metric_namespace_collision`: For metrics which have namespace conflicts.


The `attribute_constant_collision` policy violation can be resolved by letting code generation drop the conflciting attribute via the `code_generation` annotation, for example:

```yaml
attributes:
- key: my.attribute
  ...
  annotations:
    code_generation:
        exclude: true # This is a hint to all code generation not to use this attribute.
```
