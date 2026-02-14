package after_resolution

import rego.v1

# Rule: Detect metric name collisions with namespaces
deny contains finding if {
    some metric in input.registry.metrics
    name := metric.name
    not metric.deprecated

    exceptions := {
        # legacy hardware metrics that are known to cause collisions
        "hw.battery.charge", "hw.cpu.speed", "hw.fan.speed", "hw.temperature", "hw.voltage"
    }
    not exceptions[name]

    prefix := concat("", [name, "."])

    some other_metric in input.registry.metrics
    other_name := other_metric.name
    not other_metric.deprecated

    name != other_name
    startswith(other_name, prefix)

    finding := {
        "id": "naming_convention_metric_namespace_collision",
        "context": {
            "metric_name": name,
            "colliding_metric_name": other_name,
        },
        "message": sprintf("Metric with name '%s' is used as a namespace in the following metric '%s'.", [name, other_name]),
        "level": "violation",
        "signal_type": "metric",
        "signal_name": name,
    }
}
