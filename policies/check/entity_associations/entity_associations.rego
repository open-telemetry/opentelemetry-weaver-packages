package after_resolution

import rego.v1

# Checks referential integrity of `entity_associations`: a signal must not name
# an entity that no entity definition provides.
#
# Weaver validates this during resolution for the new materialized form, where
# an association leaf is an object carrying `type` and `provenance`. Such a
# registry has already been checked, so this policy skips object leaves and is a
# no-op for it. It remains a back-compatible check for the old form, where a
# leaf is a bare entity-type string that weaver did not yet validate.

# Set of all entity types defined in this registry.
known_entities := {entity.type | some entity in input.registry.entities}

# Metrics
deny contains finding if {
    some metric in input.registry.metrics
    some association in metric.entity_associations
    is_string(association)
    not known_entities[association]
    finding := entity_association_finding(association, "metric", metric.name)
}

# Spans
deny contains finding if {
    some span in input.registry.spans
    some association in span.entity_associations
    is_string(association)
    not known_entities[association]
    finding := entity_association_finding(association, "span", span.type)
}

# Events
deny contains finding if {
    some event in input.registry.events
    some association in event.entity_associations
    is_string(association)
    not known_entities[association]
    finding := entity_association_finding(association, "event", event.name)
}

entity_association_finding(entity_type, signal_type, signal_name) := {
    "id": "entity_association_unknown_entity",
    "message": sprintf("Unknown entity '%s' associated with %s '%s'", [entity_type, signal_type, signal_name]),
    "level": "violation",
    "context": {
        "entity": entity_type,
    },
    "signal_type": signal_type,
    "signal_name": signal_name,
}
