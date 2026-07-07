package after_resolution

import rego.v1

# The attribute_name_collisions.rego policy checks generated-constant collisions
# between attributes. This policy covers the other signal kinds: metrics, events,
# and entities. Each kind lives in its own namespace in generated code, so
# collisions are only checked within a single kind.

signal_constant contains obj if {
    some metric in input.registry.metrics
    obj := signal_constant_entry("metric", metric.name, metric)
}

signal_constant contains obj if {
    some event in input.registry.events
    obj := signal_constant_entry("event", event.name, event)
}

signal_constant contains obj if {
    some entity in input.registry.entities
    obj := signal_constant_entry("entity", entity.type, entity)
}

signal_constant_entry(signal_type, name, source) := {
    "signal_type": signal_type,
    "name": name,
    "const": replace(name, ".", "_"),
    "excluded": object.get(source, ["annotations", "code_generation", "exclude"], false) == true,
}

deny contains finding if {
    some entry in signal_constant
    not entry.excluded

    some other in signal_constant
    other.signal_type == entry.signal_type
    other.name != entry.name
    other.const == entry.const
    not other.excluded

    finding := {
        "id": sprintf("naming_convention_%s_constant_collision", [entry.signal_type]),
        "context": {
            "colliding_name": other.name,
            "constant_name": entry.const,
        },
        "message": sprintf("%s '%s' has the same constant name '%s' as '%s'.", [entry.signal_type, entry.name, entry.const, other.name]),
        "level": "violation",
        "signal_type": entry.signal_type,
        "signal_name": entry.name,
    }
}
