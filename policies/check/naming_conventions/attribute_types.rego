package after_resolution

import rego.v1

# Rule: Complex attributes are only allowed on events and spans
# We check metrics, entities, and attribute_groups.

# Check metrics
deny contains finding if {
    some metric in input.registry.metrics
    some attr in metric.attributes
    attr.type in ["any", "template[any]"]

    finding := {
        "id": "naming_convention_attribute_complex_type_violation",
        "context": {
            "attribute_key": attr.key,
            "attribute_type": attr.type,
        },
        "message": sprintf("Attribute '%s' has type '%s' and is referenced on metric '%s'. Complex attributes are only allowed on events and spans.", [attr.key, attr.type, metric.name]),
        "level": "violation",
        "signal_type": "metric",
        "signal_name": metric.name,
    }
}

# Check entities (identity)
deny contains finding if {
    some entity in input.registry.entities
    some attr in entity.identity
    attr.type in ["any", "template[any]"]

    finding := {
        "id": "naming_convention_attribute_complex_type_violation",
        "context": {
            "attribute_key": attr.key,
            "attribute_type": attr.type,
        },
        "message": sprintf("Attribute '%s' has type '%s' and is used as identity on entity '%s'. Complex attributes are only allowed on events and spans.", [attr.key, attr.type, entity.type]),
        "level": "violation",
        "signal_type": "entity",
        "signal_name": entity.type,
    }
}

# Check entities (description)
deny contains finding if {
    some entity in input.registry.entities
    some attr in entity.description
    attr.type in ["any", "template[any]"]

    finding := {
        "id": "naming_convention_attribute_complex_type_violation",
        "context": {
            "attribute_key": attr.key,
            "attribute_type": attr.type,
        },
        "message": sprintf("Attribute '%s' has type '%s' and is used in description on entity '%s'. Complex attributes are only allowed on events and spans.", [attr.key, attr.type, entity.type]),
        "level": "violation",
        "signal_type": "entity",
        "signal_name": entity.type,
    }
}

# Check attribute_groups
deny contains finding if {
    some group in input.registry.attribute_groups
    some attr in group.attributes
    attr.type in ["any", "template[any]"]

    finding := {
        "id": "naming_convention_attribute_complex_type_violation",
        "context": {
            "attribute_key": attr.key,
            "group_id": group.id,
            "attribute_type": attr.type,
        },
        "message": sprintf("Attribute '%s' has type '%s' and is referenced on group '%s'. Complex attributes are only allowed on events and spans.", [attr.key, attr.type, group.id]),
        "level": "violation",
    }
}
