package after_resolution

import rego.v1

# --- Deprecation Policies ---

# Helper sets for non-deprecated signals
registry_attribute_keys := {attr.key |
    some attr in input.registry.attributes
    not attr.deprecated
}

registry_metric_names := {metric.name |
    some metric in input.registry.metrics
    not metric.deprecated
}

registry_event_names := {event.name |
    some event in input.registry.events
    not event.deprecated
}

registry_span_types := {span.type |
    some span in input.registry.spans
    not span.deprecated
}

registry_entity_types := {entity.type |
    some entity in input.registry.entities
    not entity.deprecated
}

registry_attribute_map := {attr.key: attr |
    some attr in input.registry.attributes
}

# Rule: Attribute renamed_to must be another existing, non-deprecated attribute
deny contains finding if {
    some attr in input.registry.attributes
    attr.deprecated.reason == "renamed"
    new_name := attr.deprecated.renamed_to
    not registry_attribute_keys[new_name]

    finding := {
        "id": "deprecation_attribute_renamed_to_invalid",
        "message": sprintf("Attribute '%s' was renamed to '%s', but the new attribute does not exist or is deprecated.", [attr.key, new_name]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "renamed_to": new_name
        }
    }
}

# Helper to get type string for primitives or "enum"
get_type_string(attr) := "enum" if {
    attr.type.members
} else := type_str if {
    type_str := attr.type
}

# Rule: attribute.deprecated.renamed_to attribute must be of the same type
deny contains finding if {
    some attr in input.registry.attributes
    attr.deprecated.reason == "renamed"
    new_name := attr.deprecated.renamed_to
    new_attr := registry_attribute_map[new_name]
    
    # skip enums, checked separately
    not attr.type.members
    not new_attr.type.members
    
    attr.type != new_attr.type
    
    finding := {
        "id": "deprecation_attribute_renamed_to_type_mismatch",
        "message": sprintf("Attribute '%s' was renamed to '%s', but the new attribute type '%s' is not the same as the old attribute type '%s'.", [attr.key, new_name, new_attr.type, attr.type]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "renamed_to": new_name,
            "old_type": attr.type,
            "new_type": new_attr.type
        }
    }
}

# Rule: attribute.deprecated.renamed_to: string to enum of strings is ok
deny contains finding if {
    some attr in input.registry.attributes
    attr.deprecated.reason == "renamed"
    new_name := attr.deprecated.renamed_to
    new_attr := registry_attribute_map[new_name]

    attr.type == "string"
    new_attr.type.members
    not is_string(new_attr.type.members[0].value)

    finding := {
        "id": "deprecation_attribute_renamed_to_type_mismatch",
        "message": sprintf("String attribute '%s' was renamed to enum attribute '%s', but the new attribute member type is not a string type", [attr.key, new_name]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "renamed_to": new_name
        }
    }
}

# Rule: attribute.deprecated.renamed_to: int to enum of ints is ok
deny contains finding if {
    some attr in input.registry.attributes
    attr.deprecated.reason == "renamed"
    new_name := attr.deprecated.renamed_to
    new_attr := registry_attribute_map[new_name]

    attr.type == "int"
    new_attr.type.members
    not is_number(new_attr.type.members[0].value)

    finding := {
        "id": "deprecation_attribute_renamed_to_type_mismatch",
        "message": sprintf("Int attribute '%s' was renamed to enum attribute '%s', but the new attribute member type is not a number", [attr.key, new_name]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "renamed_to": new_name
        }
    }
}

# Rule: enum attribute.deprecated.renamed_to: enum of the same value types is ok
deny contains finding if {
    some attr in input.registry.attributes
    attr.deprecated.reason == "renamed"
    new_name := attr.deprecated.renamed_to
    new_attr := registry_attribute_map[new_name]
    
    attr.type.members
    new_attr.type.members

    not same_type(attr.type.members[0].value, new_attr.type.members[0].value)
    
    finding := {
        "id": "deprecation_attribute_renamed_to_type_mismatch",
        "message": sprintf("Enum attribute '%s' was renamed to '%s', but the value types are not the same.", [attr.key, new_name]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "renamed_to": new_name
        }
    }
}

# Rule: enum attribute.deprecated.renamed_to: enum of strings to string is ok
deny contains finding if {
    some attr in input.registry.attributes
    attr.deprecated.reason == "renamed"
    new_name := attr.deprecated.renamed_to
    new_attr := registry_attribute_map[new_name]

    attr.type.members
    is_string(attr.type.members[0].value)

    not new_attr.type.members
    new_attr.type != "string"
    
    finding := {
        "id": "deprecation_attribute_renamed_to_type_mismatch",
        "message": sprintf("Enum attribute '%s' with string values was renamed to '%s', but the new attribute type is '%s'.", [attr.key, new_name, new_attr.type]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "renamed_to": new_name
        }
    }
}

# Rule: enum attribute.deprecated.renamed_to: enum of ints to int is ok
deny contains finding if {
    some attr in input.registry.attributes
    attr.deprecated.reason == "renamed"
    new_name := attr.deprecated.renamed_to
    new_attr := registry_attribute_map[new_name]

    attr.type.members
    is_number(attr.type.members[0].value)

    not new_attr.type.members
    new_attr.type != "int"
    
    finding := {
        "id": "deprecation_attribute_renamed_to_type_mismatch",
        "message": sprintf("Enum attribute '%s' with int values was renamed to '%s', but the new attribute type is '%s'.", [attr.key, new_name, new_attr.type]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "renamed_to": new_name
        }
    }
}

# Rule: Metric renamed_to must be another existing, non-deprecated metric
deny contains finding if {
    some metric in input.registry.metrics
    metric.deprecated.reason == "renamed"
    new_name := metric.deprecated.renamed_to
    not registry_metric_names[new_name]

    finding := {
        "id": "deprecation_metric_renamed_to_invalid",
        "message": sprintf("Metric '%s' was renamed to '%s', but the new metric does not exist or is deprecated.", [metric.name, new_name]),
        "level": "violation",
        "context": {
            "renamed_to": new_name
        },
        "signal_type": "metric",
        "signal_name": metric.name,
    }
}

# Rule: Event renamed_to must be another existing, non-deprecated event
deny contains finding if {
    some event in input.registry.events
    event.deprecated.reason == "renamed"
    new_name := event.deprecated.renamed_to
    not registry_event_names[new_name]

    finding := {
        "id": "deprecation_event_renamed_to_invalid",
        "message": sprintf("Event '%s' was renamed to '%s', but the new event does not exist or is deprecated.", [event.name, new_name]),
        "level": "violation",
        "context": {
            "renamed_to": new_name
        },
        "signal_type": "event",
        "signal_name": event.name,
    }
}

# Rule: Span renamed_to must be another existing, non-deprecated span
deny contains finding if {
    some span in input.registry.spans
    span.deprecated.reason == "renamed"
    new_name := span.deprecated.renamed_to
    not registry_span_types[new_name]

    finding := {
        "id": "deprecation_span_renamed_to_invalid",
        "message": sprintf("Span '%s' was renamed to '%s', but the new span does not exist or is deprecated.", [span.type, new_name]),
        "level": "violation",
        "context": {
            "renamed_to": new_name
        },
        "signal_type": "span",
        "signal_name": span.type,
    }
}

# Rule: Entity renamed_to must be another existing, non-deprecated entity
deny contains finding if {
    some entity in input.registry.entities
    entity.deprecated.reason == "renamed"
    new_name := entity.deprecated.renamed_to
    not registry_entity_types[new_name]

    finding := {
        "id": "deprecation_entity_renamed_to_invalid",
        "message": sprintf("Entity '%s' was renamed to '%s', but the new entity does not exist or is deprecated.", [entity.type, new_name]),
        "level": "violation",
        "context": {
            "renamed_to": new_name
        },
        "signal_type": "entity",
        "signal_name": entity.type,
    }
}

# Rule: Enum member renamed_to must exist in the same enum and not be deprecated
deny contains finding if {
    some attr in input.registry.attributes
    some member in attr.type.members
    member.deprecated.reason == "renamed"
    new_id := member.deprecated.renamed_to
    
    # Find matches in the same enum
    matches := [m.id |
        some m in attr.type.members
        m.id == new_id
        not m.deprecated
    ]
    count(matches) == 0

    finding := {
        "id": "deprecation_enum_member_renamed_to_invalid",
        "message": sprintf("Member '%s' of the attribute '%s' was renamed to '%s', but the new member does not exist or is deprecated.", [member.id, attr.key, new_id]),
        "level": "violation",
        "context": {
            "attribute_key": attr.key,
            "member_id": member.id,
            "renamed_to": new_id
        }
    }
}

same_type(a, b) if {
  is_string(a)
  is_string(b)
}

same_type(a, b) if {
  is_number(a)
  is_number(b)
}

same_type(a, b) if {
  is_boolean(a)
  is_boolean(b)
}

same_type(a, b) if {
  is_array(a)
  is_array(b)
}

same_type(a, b) if {
  is_set(a)
  is_set(b)
}

same_type(a, b) if {
  is_object(a)
  is_object(b)
}
