package after_resolution

import rego.v1

# Checks referential integrity of `entity_associations`: every entity referenced
# by a signal must resolve to an entity that exists in the registry.

# Set of all entity types defined in the registry.
known_entities := {entity.type | some entity in input.registry.entities}

# Metrics
deny contains finding if {
    some metric in input.registry.metrics
    some association in metric.entity_associations
    not known_entities[association]

    finding := entity_association_finding(association, "metric", metric.name)
}

# Spans
deny contains finding if {
    some span in input.registry.spans
    some association in span.entity_associations
    not known_entities[association]

    finding := entity_association_finding(association, "span", span.type)
}

# Events
deny contains finding if {
    some event in input.registry.events
    some association in event.entity_associations
    not known_entities[association]

    finding := entity_association_finding(association, "event", event.name)
}

entity_association_finding(association, signal_type, signal_name) := {
    "id": "entity_association_unknown_entity",
    "message": sprintf("Unknown entity '%s' associated with %s '%s'", [association, signal_type, signal_name]),
    "level": "violation",
    "context": {
        "entity": association,
    },
    "signal_type": signal_type,
    "signal_name": signal_name,
}
