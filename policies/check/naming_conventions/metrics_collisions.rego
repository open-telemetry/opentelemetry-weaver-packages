package after_resolution

import rego.v1

# Rule: Detect metric name collisions with namespaces
deny contains finding if {
    some metric in input.registry.metrics
    name := metric.name
    not metric.deprecated

    prefix := concat("", [name, "."])

    some other_metric in input.registry.metrics
    other_name := other_metric.name
    not other_metric.deprecated

    # Allow exceptions on annotations from either metric.
    exceptions := { policy | some policy in metric.annotations.naming_conventions.policy_exceptions } | { policy | some policy in other_metric.annotations.naming_conventions.policy_exceptions }
    not exceptions["metric_namespace_collision"]

    name != other_name
    startswith(other_name, prefix)

    finding := {
        "id": "naming_convention_metric_namespace_collision",
        "context": {
            "colliding_metric_name": other_name,
        },
        "message": sprintf("Metric with name '%s' is used as a namespace in the following metric '%s'.", [name, other_name]),
        "level": "violation",
        "signal_type": "metric",
        "signal_name": name,
    }
}
