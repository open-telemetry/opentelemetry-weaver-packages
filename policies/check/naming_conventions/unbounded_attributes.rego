package after_resolution

import rego.v1

# An attribute with unbounded value size must not be required.
deny contains finding if {
    some entry in unbounded_signal_attributes
    entry.attr.requirement_level == "required"

    finding := {
        "id": "unbounded_attribute_required",
        "message": sprintf("Attribute '%s' on %s '%s' is marked as unbounded and cannot be required.", [entry.attr.key, entry.signal_type, entry.signal_name]),
        "level": "violation",
        "context": {
            "attribute_key": entry.attr.key,
        },
        "signal_type": entry.signal_type,
        "signal_name": entry.signal_name,
    }
}

deny contains finding if {
    some group in input.registry.attribute_groups
    some attr in group.attributes
    attr.annotations.value.unbounded_size == true
    attr.requirement_level == "required"

    finding := {
        "id": "unbounded_attribute_required",
        "message": sprintf("Attribute '%s' on group '%s' is marked as unbounded and cannot be required.", [attr.key, group.id]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "group_id": group.id,
        },
    }
}

unbounded_signal_attributes contains {"signal_type": "span", "signal_name": span.type, "attr": attr} if {
    some span in input.registry.spans
    some attr in span.attributes
    attr.annotations.value.unbounded_size == true
}

unbounded_signal_attributes contains {"signal_type": "event", "signal_name": event.name, "attr": attr} if {
    some event in input.registry.events
    some attr in event.attributes
    attr.annotations.value.unbounded_size == true
}

# An attribute with unbounded value size must not be used on metrics.
deny contains finding if {
    some metric in input.registry.metrics
    some attr in metric.attributes
    attr.annotations.value.unbounded_size == true

    finding := {
        "id": "unbounded_attribute_metric",
        "message": sprintf("Attribute '%s' is marked as unbounded and cannot be used on metric '%s'.", [attr.key, metric.name]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
        },
        "signal_type": "metric",
        "signal_name": metric.name,
    }
}

unbounded_signal_attributes contains {"signal_type": "entity", "signal_name": entity.type, "attr": attr} if {
    some entity in input.registry.entities
    some attr in object.get(entity, "description", [])
    attr.annotations.value.unbounded_size == true
}

# An attribute with unbounded value size must not be part of entity identity.
deny contains finding if {
    some entity in input.registry.entities
    some attr in object.get(entity, "identity", [])
    attr.annotations.value.unbounded_size == true

    finding := {
        "id": "unbounded_attribute_entity_identity",
        "message": sprintf("Attribute '%s' is marked as unbounded and cannot be used as identity on entity '%s'.", [attr.key, entity.type]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
        },
        "signal_type": "entity",
        "signal_name": entity.type,
    }
}
