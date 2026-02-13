package after_resolution

import rego.v1

# Helper to check if requirement level is opt_in
is_opt_in(level) if {
    level == "opt_in"
}
is_opt_in(level) if {
    level.opt_in
}

# Rule: Stable entities must have identifying attributes.
deny contains finding if {
    some entity in input.registry.entities
    entity.stability == "stable"
    
    # identity is omitted if empty due to skip_serializing_if
    not entity.identity
    
    finding := {
        "id": "stability_entity_no_identity",
        "message": sprintf("Stable entity '%s' has no identifying attributes", [entity.type]),
        "level": "violation",
        "context": { "entity_type": entity.type },
    }
}

deny contains finding if {
    some entity in input.registry.entities
    entity.stability == "stable"
    
    count(entity.identity) < 1
    
    finding := {
        "id": "stability_entity_no_identity",
        "message": sprintf("Stable entity '%s' has no identifying attributes", [entity.type]),
        "level": "violation",
        "context": { "entity_type": entity.type },
    }
}

# Rule: Stable metrics should not have experimental attributes unless opt_in
deny contains finding if {
    some metric in input.registry.metrics
    metric.stability == "stable"
    some attr in metric.attributes
    
    attr.stability != "stable"
    not is_opt_in(attr.requirement_level)

    finding := {
        "id": "stability_metric_experimental_attribute",
        "message": sprintf("Stable metric '%s' references experimental attribute '%s' with requirement level '%s', only 'opt_in' level is allowed", [metric.name, attr.key, attr.requirement_level]),
        "level": "violation",
        "context": {
            "metric_name": metric.name,
            "attribute_key": attr.key,
            "requirement_level": attr.requirement_level
        }
    }
}

# Rule: Stable events should not have experimental attributes unless opt_in
deny contains finding if {
    some event in input.registry.events
    event.stability == "stable"
    some attr in event.attributes
    
    attr.stability != "stable"
    not is_opt_in(attr.requirement_level)

    finding := {
        "id": "stability_event_experimental_attribute",
        "message": sprintf("Stable event '%s' references experimental attribute '%s' with requirement level '%s', only 'opt_in' level is allowed", [event.name, attr.key, attr.requirement_level]),
        "level": "violation",
        "context": {
            "event_name": event.name,
            "attribute_key": attr.key,
            "requirement_level": attr.requirement_level
        }
    }
}

# Rule: Stable spans should not have experimental attributes unless opt_in
deny contains finding if {
    some span in input.registry.spans
    span.stability == "stable"
    some attr in span.attributes
    
    attr.stability != "stable"
    not is_opt_in(attr.requirement_level)

    finding := {
        "id": "stability_span_experimental_attribute",
        "message": sprintf("Stable span '%s' references experimental attribute '%s' with requirement level '%s', only 'opt_in' level is allowed", [span.type, attr.key, attr.requirement_level]),
        "level": "violation",
        "context": {
            "span_type": span.type,
            "attribute_key": attr.key,
            "requirement_level": attr.requirement_level
        }
    }
}

# Rule: Stable entities should not have experimental attributes unless opt_in
deny contains finding if {
    some entity in input.registry.entities
    entity.stability == "stable"
    some list_name in ["identity", "description"]
    some attr in entity[list_name]
    
    attr.stability != "stable"
    not is_opt_in(attr.requirement_level)

    finding := {
        "id": "stability_entity_experimental_attribute",
        "message": sprintf("Stable entity '%s' references experimental attribute '%s' in %s with requirement level '%s', only 'opt_in' level is allowed", [entity.type, attr.key, list_name, attr.requirement_level]),
        "level": "violation",
        "context": {
            "entity_type": entity.type,
            "attribute_key": attr.key,
            "requirement_level": attr.requirement_level
        }
    }
}
